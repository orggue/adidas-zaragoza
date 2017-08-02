# Alpine Linux

In previous exercises we have used Debian linux, the distribution which Ubuntu
is derived from. Traditional distributions like Debian and Ubuntu work fine in
docker, but the containerization movement has generated demand for smaller,
more lightweight distributions. One such popular distribution which has emerged
is Alpine Linux.

Alpine linux is based on lightweight GNU alternatives: musl and busybox.
Running the alpine image works just the same as running the debian image:

```
$ docker run alpine echo Hello Alpine
Hello Alpine
```

Because of the lightweight nature of alpine linux, some things you might expect
to work on normal distributions will fail out of the box, such as running bash:
```
$ docker run -it alpine bash
docker: Error response from daemon: oci runtime error: container_linux.go:262: starting container process caused "exec: \"bash\": executable file not found in $PATH".
```

Alpine instead features a more lightweight shell, called sh:
```
$ docker run -it alpine sh
/ # MYVAR=123
/ # echo $MYVAR
123
/ # exit
```

There are some small feature differences between bash and sh, but for the
most part shell scripts intended to run in bash should work fine in sh. Beware
of shell scripts which begin with `#!/bin/bash`, as they will not work by
default in alpine linux, and will produce a cryptic error:
```
$ cat <<EOF > test.sh
#!/bin/bash
echo Hello from shell script
EOF
$ chmod +x test.sh
$ docker run -v $(pwd)/test.sh:/test.sh alpine /test.sh
standard_init_linux.go:187: exec user process caused "no such file or directory"
```

Why does this shell script, which interacts with no files, produce a `no such
file or directory` error? Because `/bin/bash` is not a valid file:
```
$ docker run alpine ls /bin/bash
ls: /bin/bash: No such file or directory
```

With a small modification we can see that the shell script works just fine in
sh:
```
$ cat <<EOF > test.sh
#!/bin/sh
echo Hello from shell script
EOF
$ chmod +x test.sh
$ docker run -v $(pwd)/test.sh:/test.sh alpine /test.sh
Hello from shell script
```

Some bash scripts may not work in sh, even with modification. Let's look at how
to install bash using `apk`, the alpine linux package manager.
```
$ cat <<EOF > test.sh
#!/bin/bash
echo Hello from shell script
EOF
$ chmod +x test.sh
$ docker run -it -v $(pwd)/test.sh:/test.sh alpine sh
/ # apk --no-cache add bash
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
(1/5) Installing ncurses-terminfo-base (6.0-r7)
(2/5) Installing ncurses-terminfo (6.0-r7)
(3/5) Installing ncurses-libs (6.0-r7)
(4/5) Installing readline (6.3.008-r5)
(5/5) Installing bash (4.3.48-r1)
Executing bash-4.3.48-r1.post-install
Executing busybox-1.26.2-r5.trigger
OK: 12 MiB in 16 packages
/ # /test.sh
Hello from shell script
/ # exit
```

Notice the flag `--no-cache` to apk? Let's see why it's there:
```
$ docker run alpine apk add bash
WARNING: Ignoring APKINDEX.84815163.tar.gz: No such file or directory
WARNING: Ignoring APKINDEX.24d64ab1.tar.gz: No such file or directory
ERROR: unsatisfiable constraints:
  bash (missing):
    required by: world[bash]
```

Without the `--no-cache` flag `apk` produces errors like this. `apk` expects
some tar.gz files to exist, but they are not present in the stock alpine image.
One alternative to the `--no-cache` flag is to first generate the cache for
`apk` by running `apk update`, but this cache will only live for the life of the
container:
```
$ docker run -it alpine sh
/ # apk update
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
v3.6.2-34-g7ecc057684 [http://dl-cdn.alpinelinux.org/alpine/v3.6/main]
v3.6.2-32-g6f53cfcccd [http://dl-cdn.alpinelinux.org/alpine/v3.6/community]
OK: 8436 distinct packages available
/ # apk add bash
(1/5) Installing ncurses-terminfo-base (6.0-r7)
(2/5) Installing ncurses-terminfo (6.0-r7)
(3/5) Installing ncurses-libs (6.0-r7)
(4/5) Installing readline (6.3.008-r5)
(5/5) Installing bash (4.3.48-r1)
Executing bash-4.3.48-r1.post-install
Executing busybox-1.26.2-r5.trigger
OK: 12 MiB in 16 packages
/ # exit
```

The `--no-cache` flag is handy because it avoids the need to run `apk update`
in every recipe, and it prevents the problematic situation of baking stale
cache data into a docker image.

Another way to deal with the apk cache problem is to keep a volume around for
the apk cache. This isn't practical for production purposes, but can be useful
for local development. By persisting the apk cache you can avoid the repeated
download of files, and speed up local builds.

Let's setup a local apk cache and see how it works. First, we'll run
`apk update` against the `apk_cache` volume to initialize it. Since this is the
first time we have specified the `apk_cache` volume id, it will be automatically
created.
```
$ docker run -v apk_cache:/etc/apk/cache alpine apk update
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
v3.6.2-34-g7ecc057684 [http://dl-cdn.alpinelinux.org/alpine/v3.6/main]
v3.6.2-32-g6f53cfcccd [http://dl-cdn.alpinelinux.org/alpine/v3.6/community]
OK: 8436 distinct packages available
```

If you now repeatedly launch containers which install a package, you will
notice on a slow network such as public wi-fi, and even on fast networks for
larger packages, that the subsequent installations are much faster.
```
$ time docker run -v apk_cache:/etc/apk/cache alpine apk add bash
(1/5) Installing ncurses-terminfo-base (6.0-r7)
(2/5) Installing ncurses-terminfo (6.0-r7)
(3/5) Installing ncurses-libs (6.0-r7)
(4/5) Installing readline (6.3.008-r5)
(5/5) Installing bash (4.3.48-r1)
Executing bash-4.3.48-r1.post-install
Executing busybox-1.26.2-r5.trigger
OK: 12 MiB in 16 packages

real	0m28.042s
user	0m0.021s
sys	0m0.014s
$ time docker run -v apk_cache:/etc/apk/cache alpine apk add bash
(1/5) Installing ncurses-terminfo-base (6.0-r7)
(2/5) Installing ncurses-terminfo (6.0-r7)
(3/5) Installing ncurses-libs (6.0-r7)
(4/5) Installing readline (6.3.008-r5)
(5/5) Installing bash (4.3.48-r1)
Executing bash-4.3.48-r1.post-install
Executing busybox-1.26.2-r5.trigger
OK: 12 MiB in 16 packages

real	0m1.209s
user	0m0.018s
sys	0m0.014s
```

In fact, after the cache has been primed with packages needed for your image, no
network access is required by apk at all. We can prove this by launching a
container with `--net none` and successfully installing packages that are in
the cache, but not other packages:
```
$ docker run -v apk_cache:/etc/apk/cache --net none alpine apk add bash
(1/5) Installing ncurses-terminfo-base (6.0-r7)
(2/5) Installing ncurses-terminfo (6.0-r7)
(3/5) Installing ncurses-libs (6.0-r7)
(4/5) Installing readline (6.3.008-r5)
(5/5) Installing bash (4.3.48-r1)
Executing bash-4.3.48-r1.post-install
Executing busybox-1.26.2-r5.trigger
OK: 12 MiB in 16 packages
$ docker run -v apk_cache:/etc/apk/cache --net none alpine apk add nginx
(1/2) Installing pcre (8.40-r2)
ERROR: pcre-8.40-r2: temporary error (try again later)
(2/2) Installing nginx (1.12.1-r0)
ERROR: nginx-1.12.1-r0: temporary error (try again later)
2 errors; 4 MiB in 11 packages
```
*In this case the cache was primed with bash, but not pcre or nginx, so these
errors were expected.*

These errors can be better managed by adding the `--no-network` flag to apk:
```
$ docker run -v apk_cache:/etc/apk/cache --net none alpine apk add --no-network nginx
ERROR: unsatisfiable constraints:
  pcre-8.40-r2:
    masked in: --no-network
    satisfies: nginx-1.12.1-r0[so:libpcre.so.1]
  nginx-1.12.1-r0:
    masked in: --no-network
    satisfies: world[nginx]
```

Apk includes other features you might expect in package managers, such as
searching the package repository:
```
$ docker run alpine apk --no-cache search nginx
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
nginx-1.12.1-r0
collectd-nginx-5.6.2-r0
nginx-mod-mail-1.12.1-r0
nginx-mod-http-lua-upstream-1.12.1-r0
nginx-mod-http-upload-progress-1.12.1-r0
nginx-mod-http-lua-1.12.1-r0
nginx-mod-rtmp-1.12.1-r0
nginx-mod-http-echo-1.12.1-r0
nginx-mod-http-set-misc-1.12.1-r0
patchwork-uwsgi-nginx-1.1.3-r0
nginx-mod-http-image-filter-1.12.1-r0
nginx-mod-http-nchan-1.12.1-r0
nginx-mod-http-fancyindex-1.12.1-r0
nginx-mod-http-redis2-1.12.1-r0
nginx-mod-http-geoip-1.12.1-r0
nginx-mod-http-headers-more-1.12.1-r0
nginx-mod-stream-1.12.1-r0
nginx-mod-http-xslt-filter-1.12.1-r0
nginx-vim-1.12.1-r0
nginx-mod-devel-kit-1.12.1-r0
nginx-mod-http-perl-1.12.1-r0
nginx-doc-1.12.1-r0
nginx-mod-stream-geoip-1.12.1-r0
```

Why is such a basic linux distro becoming so popular? Let's look at the nginx
images on docker hub and see why:
```
$ docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
e6e142a99202: Pull complete
b6268bec1a4d: Pull complete
677a76dde9c6: Pull complete
Digest: sha256:423210a5903e9683d2bc8436ed06343ad5955c1aec71a04e1d45bd70b0d68460
Status: Downloaded newer image for nginx:latest
$ docker pull nginx:alpine
alpine: Pulling from library/nginx
019300c8a437: Pull complete
a3fe4a77433d: Pull complete
a5443900e7f5: Pull complete
0ae275323c0f: Pull complete
Digest: sha256:24a27241f0450b465f9e9deb30628c524aa81a1aa6936daa41ef7c4345515272
Status: Downloaded newer image for nginx:alpine
$ docker image ls nginx
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               alpine              ba60b24dbad5        7 days ago          15.5MB
nginx               latest              e4e6d42c70b3        7 days ago          108MB
```

Here we see two versions of the same image, but the alpine version is much
smaller.
```
$ docker run nginx cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 9 (stretch)"
NAME="Debian GNU/Linux"
VERSION_ID="9"
VERSION="9 (stretch)"
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
$ docker run nginx:alpine cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.5.2
PRETTY_NAME="Alpine Linux v3.5"
HOME_URL="http://alpinelinux.org"
BUG_REPORT_URL="http://bugs.alpinelinux.org"
```

If nothing else, it's remarkable to consider the usefulness that's provided by a
linux distribution that could fit on just three floppies:
```
$ docker image ls alpine
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
alpine              latest              7328f6f8b418        3 weeks ago         3.97MB
```

Distros like Alpine Linux are a departure from established traditions, and the
simple example of a bash script not working may be only the beginning of trouble
when containerizing legacy applications. Can you think of any further pitfalls
that might occur in containerizing applications with lightweight distros such as
Alpine linux? Does using a debian or ubuntu image solve all of these problems?
What lessons can we learn about application design from all this?

## Bonus Task

What's the largest practical image you can create with Alpine Linux?

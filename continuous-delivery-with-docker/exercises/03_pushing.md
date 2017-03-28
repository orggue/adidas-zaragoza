\pagebreak
 
# Pushing to a Registry

If an image succesfully passes the test, the next step is to push it to a
registry. In our case we'll use the Docker Hub, but this could be any local or
remote registry.

Add the following to `.drone.yml`:

```
  push:
    image: docker
    environment:
      - PASS=${HUB_PASS}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker login -u <username> -p $PASS
      - docker push <username>/example-webserver
```

Replace `<username>` with your username on the Hub.

Rather than hardcode the password into the file and check it into source
control, we'll inject it using the Drone CLI and the above `${HUB_PASS}` syntax.
You can install the CLI either on your local laptop or in the VM. To do it on
the VM:

```
$ mkdir drone-cli
$ cd drone-cli
$ curl http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx
$ sudo install -t /usr/local/bin drone
$ cd
```

If you want to install on your laptop, use the instructions at
_http://readme.drone.io/usage/getting-started-cli/_.

To use the CLI, you'll need to set up environment variables with the IP of your
VM and the Drone token. The Drone token can be found by going to the "account" page of the Drone webapp and clicking on the "SHOW TOKEN" button on the left. 

```
$ export DRONE_SERVER=http://<VM_IP>
$ export DRONE_TOKEN=<TOKEN>
```

Where `<VM_IP>` is the IP address of your VM and `<TOKEN>` is the token from
Drone.

Now you should be able to add our password using the `drone secret` command. The
arguments are the name of the repository, the name of the secret and the value
of the secret:

```
$  drone secret add --skip-verify=true <username>/go-example-webserver \
   HUB_PASS mypassword
```

Note that if you add an extra space before the command, it won't be added to the
bash history.

If you now commit and push the updated `.drone.yml`, your image should be built
and pushed to the Hub. If you browse to your account on the Hub, you should be
able to find it.


## Bonus Tasks

1) We used the `--skip-verify` argument to avoid some extra config. Try fixing this
by signing the repository following the on-line instructions _http://readme.drone.io/usage/secret-guide/_.

2) Try pushing to self-hosted registry instead of the Docker Hub. You should be
able to get one running by following the instructions at _https://hub.docker.com/_/registry/_.

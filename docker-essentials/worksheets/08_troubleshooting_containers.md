# Troubleshooting Containers

Running docker containers can be as mysterious as it is convenient. The linux
administration utilities you might be used to will not be so helpful anymore,
and figuring out why your containers aren't behaving as expected can be
difficult if you don't know the right tools.

In this exercise we'll dive into some of the administration tools available in
docker and understand how they can be used in troubleshooting.

Let's create a troublesome container image:
```
$ docker build -t trouble - <<EOF
FROM alpine
RUN apk --no-cache add python
CMD python -c 'import random; import sys; import time; time.sleep(random.randrange(30,60));  sys.exit(random.randrange(64,112));'
EOF
```

Now run that image as a daemon container:
```
$ docker run -d trouble
```

Looking at `docker ps` we can now see the container running as expected:
```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
47745a61bce2        trouble             "/bin/sh -c 'pytho..."   11 seconds ago      Up 10 seconds                           mystifying_engelbart
```

However, after some short time, `docker ps` doesn't show our troublesome
container running anymore:
```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

Since this was the last container we launched, we can force `docker ps` to show
the container using the flag `-l`:
```
$ docker ps -l
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                           PORTS               NAMES
47745a61bce2        trouble             "/bin/sh -c 'pytho..."   2 minutes ago       Exited (70) About a minute ago                       mystifying_engelbart
```

The status field here shows the exit code for the process. Let's try getting
docker to automatically restart the container upon failure:
```
$ docker run -d --restart=unless-stopped trouble
```

Now upon inspecting `docker ps`, we will on occasion see the process be
restarted:
```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
6c4987671868        trouble             "/bin/sh -c 'pytho..."   2 minutes ago       Up 42 seconds                           serene_goldberg
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS               NAMES
6c4987671868        trouble             "/bin/sh -c 'pytho..."   2 minutes ago       Up Less than a second                       serene_goldberg
```

One clue of trouble here is that the container was created minutes ago, but its
status shows that it has been up for much less than that. Based on this, we
know that the container is being restarted, but how can we find out when the
restarts are happening? Surely there's a better way than running `docker ps`
over and over.

Docker provides a command to view the logs of the application, which we can try:
```
$ docker logs $(docker ps -q -l)
```

Unfortunately, this application doesn't produce any logs, so the output from
`docker logs` is empty. We'll have to dig deeper. The `docker events` command
lets us see realtime events from the docker server:
```
$ docker events
2017-07-19T16:24:29.833069681+02:00 container die 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (exitCode=101, image=trouble, name=serene_goldberg)
2017-07-19T16:24:30.086258489+02:00 network disconnect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:24:30.196571752+02:00 network connect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:24:31.283887250+02:00 container start 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (image=trouble, name=serene_goldberg)
```
*When you are ready, hit CTRL-C to stop the `docker events` command*

At first the output from `docker events` is blank, but after some time the
container fails again, and we see the container get restarted. This is helpful,
but what about seeing failures from the past? The `docker events` command
accepts `--since` and `--until` arguments which allow us to specify a time
window of log events. Let's use these to list all the logged events for the last
2 minutes:
```
$ docker events --since $(expr $(date +%s) - 120) --until $(date +%s)
2017-07-19T16:27:24.192572980+02:00 container die 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (exitCode=98, image=trouble, name=serene_goldberg)
2017-07-19T16:27:24.418310701+02:00 network disconnect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:27:24.514899518+02:00 network connect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:27:25.570386586+02:00 container start 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (image=trouble, name=serene_goldberg)
2017-07-19T16:28:16.718763767+02:00 container die 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (exitCode=64, image=trouble, name=serene_goldberg)
2017-07-19T16:28:16.936889481+02:00 network disconnect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:28:17.037144763+02:00 network connect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:28:18.211551352+02:00 container start 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (image=trouble, name=serene_goldberg)
2017-07-19T16:28:49.369349380+02:00 container die 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (exitCode=69, image=trouble, name=serene_goldberg)
2017-07-19T16:28:49.608132231+02:00 network disconnect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:28:49.728109229+02:00 network connect d6a402660a822b2f5158b95cac516744b4f67e636538aeb65b7cd394a5bdd775 (container=6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c, name=bridge, type=bridge)
2017-07-19T16:28:50.971677021+02:00 container start 6c4987671868383ee0f5ebc72c48987a8117b1f0f51e0812289600978ccf201c (image=trouble, name=serene_goldberg)
```

Let's look at another example:
```
$ docker build -t app_500m - <<EOF
FROM alpine
RUN apk --no-cache add python
CMD python -c 'import time; x ="x" * (500 * 1024 * 1024); time.sleep(9999999);'
EOF
```

This application will use about 500MB of memory, but no CPU. If we run it we can
verify that by looking at `docker stats`:
```
$ docker run -d app_500m
$ docker stats
CONTAINER           CPU %               MEM USAGE / LIMIT   MEM %               NET I/O             BLOCK I/O           PIDS
66585515ba7b        0.00%               504MiB / 1.952GiB   25.21%              578B / 0B           0B / 0B             2
```
*When you are finished, hit CTRL-C to stop the `docker stats` command*

Stop the container, and run it again, but this time with a memory limit of
200MB:
```
$ docker stop $(docker ps -ql)
e39bc6a074b7
$ docker run --memory 50m --restart on-failure -d app_500m
```

Now let's look at `docker stats` again:
```
$ docker stats
CONTAINER           CPU %               MEM USAGE / LIMIT   MEM %               NET I/O             BLOCK I/O           PIDS
^C
```
*Hit CTRL-c to escape `docker stats`*

You may see nothing at all in `docker stats`, or you may only see something
flickering in and out. If we look at `docker ps` though, we can see that the
container certainly is scheduled:
```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                           PORTS               NAMES
e2e7bbeaba3f        app_500m            "/bin/sh -c 'pytho..."   2 minutes ago       Restarting (137) 8 seconds ago                       clever_noyce
```

The log for the container indicates that the process is being killed repeatedly,
but gives no further explanation:
```
$ docker logs $(docker ps -ql)
Killed
Killed
Killed
Killed
Killed
Killed
Killed
Killed
Killed
```

If we look at `docker events` though, we will see something a bit different from
before:
```
$ docker events
2017-07-20T00:11:04.041679732+02:00 network connect 40ee25e5f7085fd4add435b0517f1af465f0edc734f1b9dee83ab7b4514b298c (container=e2e7bbeaba3feb7de766a97aeb75aa2c0a36cb64b614736702f024d879389364, name=bridge, type=bridge)
2017-07-20T00:11:04.335290042+02:00 container start e2e7bbeaba3feb7de766a97aeb75aa2c0a36cb64b614736702f024d879389364 (image=app_500m, name=clever_noyce)
2017-07-20T00:11:04.852403238+02:00 container oom e2e7bbeaba3feb7de766a97aeb75aa2c0a36cb64b614736702f024d879389364 (image=app_500m, name=clever_noyce)
2017-07-20T00:11:05.002941924+02:00 container die e2e7bbeaba3feb7de766a97aeb75aa2c0a36cb64b614736702f024d879389364 (exitCode=137, image=app_500m, name=clever_noyce)
2017-07-20T00:11:05.390848374+02:00 network disconnect 40ee25e5f7085fd4add435b0517f1af465f0edc734f1b9dee83ab7b4514b298c (container=e2e7bbeaba3feb7de766a97aeb75aa2c0a36cb64b614736702f024d879389364, name=bridge, type=bridge)
^C
```
*Hit CTRL-c to escape `docker events`*

See the message `container oom`? That indicates an out-of-memory event. The
container is using more memory than it is allowed, and is therefore being
killed by the OS. Because this happens so quickly after the process starts, we
may not even see it show up in `docker stats`. The output from `docker ps`,
however, isn't about what is *running*, but rather what is *scheduled*. It's
important to understand that just because a container is in `docker ps` does
not mean that it is successfully running at all.

Make sure to clean up the containers created during this exercise:
```
$ docker stop $(docker ps -qa)
$ docker rm $(docker ps -qa)
```

## Bonus Task

`docker events` has a `--filter` option. How can this flag be used to help with
troubleshooting? Try running 50 or more containers at once and then perform some
of the same troubleshooting steps using the `--filter` option.

\pagebreak

# Basic Docker Networking

In this worksheet we will see the basics of how containers on the same host can communicate.

Start by creating a new Docker bridge network:

```
$ docker network create -d bridge mynet
e5788917f54b6c0ed6d9b9811511051c96b64fe8c66d400c3baf89a2d237831e
```

We can see what networks are availabe with the `network ls` command:

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
636450ff0145        bridge              bridge              local
ff885138f910        host                host                local
e5788917f54b        mynet               bridge              local
21bfb77d0e38        none                null                local
```

Start a Redis container and attach it to the network with the `--net` flag:

```
$ docker run -d --name redis --net mynet redis
28da10ac27d1f13144365369adc0ef6bb6bb283b9e50781fee16f8259ac9499e
```

Note that we don't need to use the `-p` command to expose ports as we won't be
connecting from the host.

Now let's start another container and try to connect to our redis server:

```
$ docker run --net mynet debian ping -c 4 redis
PING redis (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: icmp_seq=0 ttl=64 time=0.593 ms
64 bytes from 172.19.0.2: icmp_seq=1 ttl=64 time=0.075 ms
64 bytes from 172.19.0.2: icmp_seq=2 ttl=64 time=0.089 ms
64 bytes from 172.19.0.2: icmp_seq=3 ttl=64 time=0.071 ms
--- redis ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.071/0.207/0.593/0.223 ms
```

Great. We can see that our new container was able to reach the redis container
by name, which was resolved to an internal IP address.

Now let's connect to the actual database using the `redis-cli` in another
container:

```
$ docker run --net mynet -it redis redis-cli -h redis
redis:6379> 
```

Here we've started an interactive connection to the remote redis container. The
argument `-h redis` told the client to connect to the remote server called
`redis`.

Now we can run some Redis commands:

```
redis:6379> ping
PONG
redis:6379> set foo bar
OK
redis:6379> get foo
"bar"
redis:6379> exit
```

This is the basic way to connect containers in Docker. Things can get a lot more
complex when we consider multi-host networking and load-balancing, but the
principle of connecting via known names on shared networks remains the same.


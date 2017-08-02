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

Sometimes, especially in the case of builds, network access can be an
undesirable thing. Docker makes this easy to accomplish with the special "none"
network. By specifying `--net none` on a container launch we can ensure that
processes running inside that container will not be able to access the network:
```
$ docker run --net none debian ping 8.8.8.8
ping: sending packet: Network is unreachable
PING 8.8.8.8 (8.8.8.8): 56 data bytes
```

Let's take a closer look at what effect various network configurations have on a
container by inspecting the network interfaces:

First, we'll look at a traditional container launch:
```
$ docker run busybox ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02
          inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:90 (90.0 B)  TX bytes:0 (0.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
$ docker run busybox route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth0
```

There's nothing surprising here: we have eth0 with an address and a default
route. Something interesting happens when we specify `--net none`:
```
$ docker run --net none busybox ifconfig
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
$ docker run --net none busybox route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
$ docker run --net none busybox ifconfig eth0
ifconfig: eth0: error fetching interface information: Device not found
```

The eth0 device has disappeared entirely by passing `--net none`. The container
literally has no network connectivity. This provides a high level of assurance
that no network traffic can occur.

Let's try mapping a port to a container with `--net none` and see what happens.
We'll start a web server which simply reports the uptime of the container:
```
$ docker run --name nc --net none -d -p 8000:8000 gophernet/netcat -v -lk -p 8000 -n -e uptime
ca485248e68caf0b5920996c6dc7335665174c538344a605c432e36f46b1d130
$ curl localhost:8000
curl: (7) Failed to connect to localhost port 8000: Connection refused
```

We are unable to connect to the web server from our host. Is it possible from
within the server itself?
```
$ docker exec nc nc localhost 8000
 21:18:32 up 1 day, 10:33,  load average: 0.02, 0.04, 0.03
 ^C
```
*Hit ctrl-c to stop the command after you see the uptime output*

The webserver is listening and responding to requests on 127.0.0.1, but docker
is still unable to forward the port to our host. This indicates that docker is
forwarding traffic not through some trickery on the loopback address, but rather
some other method. We can discover this method by inspecting the nc output.

First let's stop the nc server we started before:
```
$ docker stop nc
nc
$ docker rm nc
nc
```

Let's start the server again, but this time allow it network access and forward
the port, then connect to it from our host:
```
$ docker run --name nc -d -p 8000:8000 gophernet/netcat -v -lk -p 8000 -n -e uptime
$ curl localhost:8000
 21:22:52 up 1 day, 10:38,  load average: 0.00, 0.01, 0.00
```

The request worked as expected, but how did it reach the container? The
container logs can provide a bit more information:
```
$ docker logs nc
listening on [::]:8000 ...
connect to [::ffff:172.17.0.2]:8000 from [::ffff:172.17.0.1]:39122 ([::ffff:172.17.0.1]:39122)
$ docker exec nc route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth0
```

As can be seen in the log output, the request is routed through 172.17.0.1, the
default gateway. A port-mapped request from our host must reach the container in
the same way that traffic from the internet would reach the container. This
provides a consistent experience despite the traffic source, and provides for
strong network isolation when that is required.

Remember to stop the nc server:
```
$ docker stop nc
nc
$ docker rm nc
nc
```

## Bonus Task

Networks can be connected and disconnected from running containers, give it a
shot!

Try using this feature combined with iptables to build a router and LAN
inside of docker. For the true brave of heart, try running a real world
network device inside docker: https://github.com/plajjan/vrnetlab

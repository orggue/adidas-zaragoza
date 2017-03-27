# First Steps with Drone

You should run these exercises from a cloud VM. You'll also need a GitHub
account and a Docker Hub account.

_You can also use a local laptop, but be aware that you will need to use a
forwarder such as ngrok in order to make your Drone instance externally
addressable. If you don't know how to do this, use a cloud VM._

First, fork the repository TK. 

Go to https://github.com/settings/applications -> OAuth applications -> Register
a new application

Give it the application name Drone and a description and a home page. For the callback URL, you
need to use the address of your VM plus TK e.g. http://104.155.81.69/authorize

TK screenshot

Github will now give you a Client ID and Secret, which we need to put in the
Drone config.

On the VM, create a docker-compose.yml with the following contents:

```
version: '2'

services:
  drone-server:
    image: drone/drone:0.5
    ports:
      - 80:8000
    volumes:
      - ./drone:/var/lib/drone/
    restart: always
    environment:
      - DRONE_OPEN=true
      - DRONE_GITHUB=true
      - DRONE_GITHUB_CLIENT=${DRONE_GITHUB_CLIENT}
      - DRONE_GITHUB_SECRET=${DRONE_GITHUB_SECRET}
      - DRONE_SECRET=${DRONE_SECRET}
      - DRONE_ADMIN=your_github_username

  drone-agent:
    image: drone/drone:0.5
    command: agent
    restart: always
    depends_on: [ drone-server ]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_SERVER=ws://drone-server:8000/ws/broker
      - DRONE_SECRET=${DRONE_SECRET}

```

Set the variables and start Drone:

```
$ export DRONE_SECRET=mysecret123
$ export DRONE_GITHUB_CLIENT=93f1a31a6104a70bc3e4 
$ export DRONE_GITHUB_SECRET=987ed8882f6cfd6933868b39178fc8a315f97316
$ docker-compose up -d
Pulling drone-server (drone/drone:0.5)...
0.5: Pulling from drone/drone
a3ed95caeb02: Pull complete
802d894958a2: Pull complete
eb9bbc802fed: Pull complete
Digest: sha256:c361a2da847834ba91fa53ac32681ace311bf578c0f558445c530ece7a247376
Status: Downloaded newer image for drone/drone:0.5
Creating csuser_drone-server_1
Creating csuser_drone-agent_1
```

Now you should be able to log into Drone by opening a browser and visiting the
VMs IP address e.g: http://104.155.81.69. You'll be asked to authorize the
application (Drone) to access your Github account.

Once this is done, you should get a "Loading..." message. Ignore this and click
the button in the top right and select "Account". From here you should see a
list of the GitHub repositories you have access to. Browse to the TK repository
and click the slider so it is in the on position. Also click the trusted slider,
which will allow us to do "trusted" actions such as mount volumes.

Drone is now monitoring the repository, but we still need to tell it what to
build.










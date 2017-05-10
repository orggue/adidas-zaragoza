# First Steps with Drone

We'll use a mixture of a cloud VM and your laptop for these exercises. You'll
also need a GitHub account (_https://github.com_) and a Docker Hub account
(_https://hub.docker.com_).

Start by forking the repository `ContainerSolutions/go-example-webserver`. You can
do this by browsing to
_https://github.com/ContainerSolutions/go-example-webserver_ and clicking the fork
button in the top right corner. Once you've done this, checkout the code on your
local laptop with `git clone` (if you click the "Clone or download" button, you
should get specific instructions). 

We'll come back to the code later, but the next step is to get Drone up and
running on the VM. As we'll be using Github to login to Drone, we first need to
register Drone as a new application in Github, which will provide us with some
secrets to pass to Drone.

Navigate to _https://github.com/settings/applications_ -> "OAuth applications"
-> "Register a new application". In the box that appears, use "Drone" as the
application name, and the address of your VM for the home page. For the callback
URL, use `http://<VM_IP>/authorize`, where `VM_IP` is the IP address of your VM.

Github will now give you a Client ID and Secret, which we need to put in the
Drone config.

Login to the VM.  On the VM, create a file named `docker-compose.yml` with the
following contents:

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
      - DRONE_ADMIN=<your_github_username>

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

You can also grab this file from _https://raw.githubusercontent.com/ContainerSolutions/go-example-webserver/drone-compose/drone-compose.yml_ e.g.:

```
$ curl -o docker-compose.yml \
  https://raw.githubusercontent.com/ContainerSolutions/go-example-webserver/\
drone-compose/drone-compose.yml
```

Replace `<your_github_username>` with you Github username. We'll set environment
variables which will be used in place of the variables in curly brackets. The
`DRONE_SECRET` variable can be anything you like, but the `DRONE_GITHUB_CLIENT`
and `DRONE_GITHUB_SECRET` are the values that the Github page gave you earlier
e.g:


```
$ export DRONE_SECRET=mysecret123
$ export DRONE_GITHUB_CLIENT=93f1a31a6104a70bc3e4 
$ export DRONE_GITHUB_SECRET=987ed8882f6cfd6933868b39178fc8a315f97316
```

We can now start Drone:

```
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
list of the GitHub repositories you have access to. Browse to the
`go-example-code` repository and click the slider so it is in the on position.
Also click the "trusted" slider, which will allow us to do "trusted" actions such
as mount volumes.

Drone is now monitoring the repository, but we still need to tell it what to
build. To do this, we need to create a `.drone.yml` file at the root of the
repository, with our instructions. On your laptop, go to the directory where you
checked out the code and create a `.drone.yml` file with the following contents:

```
pipeline:
  build:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker build -t <username>/go-example-webserver .
```

Replace `<username>` with your username on the Docker Hub. Now commit and push
your code:

```
$ git add .drone.yml
$ git commit -m "Add Drone config"
$ git push
```

If you now open the Drone webapp you should see it is building the image. Once
it's done, you can test the built image by running it on the VM, and you should
get something similar to the following:

```
$ docker run -d -p 5000:8080 <username>/example-webserver
769126c0f4669d39435985920e05f850c756fc0b2b76de66e78a3c83e72c2a05
$ curl localhost:5000
Hello From Golang
$ docker stop $(docker ps -lq)
769126c0f466
```

Note that - despite appearances to the contrary - the Drone webapp is not
updated automatically; you'll need to hit refresh to see updates.


## Bonus Task

This project uses a single image for both building and running the application.
Another approach is to split this into two steps, so that the binary is built in
one stage, then copied into a new image that is used to run the application. The
advantage of this approach is that the final image can be much smaller, as it
doesn't require all the build files and tools in the first image.

See if you can turn the build into a two stage process, using an alpine image as
the base for the final image (hint `docker create` and `docker cp` are your
friends). Once you've done this, see if you can take it even further and run the
webserver using the empty "scratch" image as a base.


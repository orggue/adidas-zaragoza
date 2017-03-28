# First Steps with Drone

We'll use a mixture of a cloud VM and your laptop for these exercises. You'll
also need a GitHub account (https://github.com) and a Docker Hub account
(https://hub.docker.com).

Start by forking the repository ContainerSoltuions/go-example-webserver. You can
do this by browsing to
https://github.com/ContainerSolutions/go-example-webserver and clicking the fork
button in the top right corner. Once you've done this, checkout the code on your
local laptop with `git clone` (if you click the "Clone or download" button, you
should get specific instructions). 

We'll come back to the code later, but the next step is to get Drone up and
running on the VM. As we'll be using Github to login to Drone, we first need to
register Drone as a new application in Github, which will provide us with some
secrets to pass to Drone.

Navigate to https://github.com/settings/applications -> "OAuth applications" -> "Register
a new application". In the box that appears, use "Drone" as the application
name, and the address of your VM for the home page. For the callback URL, use
"http://<VM_IP>/authorize", where VM_IP is the IP address of your VM.

TK screenshot

Github will now give you a Client ID and Secret, which we need to put in the
Drone config.

Login to the VM.
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

TK .drone.yml

Do build, then test

If an image succesfully passes the test, the next step is to push it to a
registry. In our case we'll use the Docker Hub, but this could be any local or
remote registry.

Add the following to .drone.yml:

```
  push:
    image: docker
    environment:
      - PASS=${HUB_PASS}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker login -u amouat -p $PASS
      - docker push amouat/example-webserver
```

Replace "amouat" with your username on the Hub.

Rather than hardcode the password into the file and check it into source
control, we'll inject it using the Drone CLI and the above ${HUB_PASS} syntax.
You can install the CLI either on your local laptop or in the VM. To do it on
the VM:

```
$ mkdir drone-cli
$ cd drone-cli
$ curl http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx
$ sudo install -t /usr/local/bin drone
$ cd
```

If you want to install on your laptop, use the instructions at http://readme.drone.io/usage/getting-started-cli/.

To use the CLI, you'll need to set up environment variables with the IP of your
VM and the Drone token. The Drone token can be found by going to the "account" page of the Drone webapp and clicking on the "SHOW TOKEN" button on the left. 

```
$ export DRONE_SERVER=http://104.155.81.69
$ export DRONE_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZXh0IjoiYW1vdWF0IiwidHlwZSI6InVzZXIifQ.Hh-HmxVE-CD5GyDjwAqc5MwOAdsPt-4LFVMjKyxqZL4

```

Now you should be able to add our password using the drone secret command. The
arguments are the name of the repository, the name of the secret and the value
of the secret:

```
$  drone secret add --skip-verify=true amouat/go-example-webserver HUB_PASS mypassword
```

Note that if you add an extra space before the command, it won't be added to the
bash history.

If you now push the updated .drone.yml, your image should be built and pushed to
the Hub.

The final step in our pipeline is deploy, where we get our code running. We'll
use swarm for this purpose, although only on a single server. To start Swarm
running, run `docker swarm init` on the VM.

Add the following to .drone.yml:

```
  deploy:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker pull amouat/example-webserver
      - docker stack deploy -c ./docker-compose.yml example-webserver
```

After commiting and pushing this change, you should be able to access the
running service in your browser using the IP address of your VM and port 8080.

Now try making a change to the code, commiting and pushing it.

Congratulations! You have a fully fledged Continuous Deployment pipeline up and
running.

provenance
branches
sign secrets
diy with Java/Node/Python
use other users Drone
use k8s/swarm
use plugins/docker
multistage-builds
health endpoint

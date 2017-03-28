# Pushing to a Registry

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
badges

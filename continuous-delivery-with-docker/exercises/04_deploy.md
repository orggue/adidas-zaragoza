\pagebreak

# Deploying the Image

The final step in our pipeline is deploy, where we get our code running. We'll
use swarm for this purpose, although only on a single server. To put the Docker
engine into Swarm mode, run `docker swarm init` on the VM.

Now add the following stage to `.drone.yml`:

```
  deploy:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker pull <username>/example-webserver
      - docker stack deploy -c ./docker-compose.yml example-webserver
```

The first command will pull the image we pushed earlier. Technically this step
isn't necessary as we're using the same engine to build and run our image, but
this isn't normally the case. The second command starts the service using the
`docker-compose.yml` file in the repository. You'll need to modify this file to
point to your image instead of mine (replace the text amouat).

After committing and pushing these changes, you should be able to access the
running service in your browser using the IP address of your VM and port 8080.

Now try making a change to the code, committing and pushing it. You should
quickly see the effects of your change - the `docker stack deploy` command will
notice any changes to images or the compose file and recreate containers as
appropriate.

Congratulations! You have a fully fledged Continuous Deployment pipeline up and
running.

## Bonus Task

Take a deeper look at how Docker swarm, stacks and services work. Try creating
multiple load-balanced instances of the image and seeing how they are updated
when the image is changed.


[//]: # branches
[//]: # diy with Java/Node/Python
[//]: # use other users Drone
[//]: # use k8s/swarm
[//]: # use plugins/docker
[//]: # health endpoint
[//]: # badges

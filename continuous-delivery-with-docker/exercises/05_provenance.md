\pagebreak

# Provenance and Labeling

A major improvement we can make to the current system is using labels and tags
add meaningful metadata about the image.

The first, and biggest, problem is that we've implicitly used the "latest" tag
when building our image. The most striking problem with this is that it makes
rolling back difficult or impossible, as the previous image had exactly the same
name. Drone defines a lot of useful environment variables that we could as our
tag, which you can see at _http://readme.drone.io/usage/environment-reference/_.

In this case, we'll use the `DRONE_COMMIT_SHA`, another possible candidate is
the `DRONE_BUILD_NUMBER`. Update the `.drone.yml` to:

```
pipeline:
  build:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker build -t <username>/example-webserver:$DRONE_COMMIT_SHA .

  test:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker run <username>/example-webserver:$DRONE_COMMIT_SHA /test.sh

  push:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - PASS=${HUB_PASS}
    commands:
      - docker login -u <username> -p $PASS
      - docker push <username>/example-webserver:$DRONE_COMMIT_SHA

  deploy:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker pull <username>/example-webserver:$DRONE_COMMIT_SHA
      - docker tag <username>/example-webserver:$DRONE_COMMIT_SHA 
               <username>/example-webserver:production
      - docker stack deploy -c ./docker-compose.yml example-webserver
```

The changes are to add the `$DRONE_COMMIT_SHA` when building, running and
pulling the image and to retag the image as "production" immediately before running
deploy. We also need to update the `docker-compose.yml` so that the image tag
"production" is used:

```
version: '3'                                                                    
                                                                                
services:                                                                       
  server:                                                                       
    image: <username>/example-webserver:production
    ports:                                                                      
      - "8080:8080"  
```

Commit and push these changes and ensure the changes work.

Finally, we can also add some labels by updating the build step:

```
  build:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker build
         --label org.label-schema.vcs-ref=$DRONE_COMMIT_SHA
         --label build-number=$DRONE_BUILD_NUMBER
         --label build-date="$(date)"
         -t <username>/example-webserver:$DRONE_COMMIT_SHA .

```

Commit and push this change. Now run `docker inspect` on the running container
in the VM. You should be able to see the new metadata on the image - this sort
of information can be invaluable in debugging.

## Bonus Task

We would also like to be certain that gets built is exactly the same one that
gets deployed. As things stand, it's possible for someone to push a new image
in-between stages or tampering to occur in transit without our knowledge.

To guard against this, we can use Docker `digests` to verify the content of
images and to ensure we use the same image throughout. Update the `.drone.yml`
so that after pushing the image, the digest is extracted and saved to file. This
can then be picked up by the deploy stage and used as the argument to `docker
pull`. The `docker tag` tool can then be used to set the tag to the one used in
the `docker-compose.yml`. Alternatively, you can look into updating the image by
using `docker service` commands rather than `docker stack deploy` and using the
digest explicitly.




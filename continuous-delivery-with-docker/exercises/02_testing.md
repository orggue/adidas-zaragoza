\pagebreak

# Testing the Image

The next stage in the pipeline is to test the image. This is perhaps the part of
the example code that takes the most shortcuts and is intended as a nod in the
right direction, rather than a complete solution.

In this case, our Docker image is capable of testing itself, we just need to run
the appropriate command.

Add the following stage to `.drone.yml`:

```
  test:
    image: docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    commands:
      - docker run <username>/example-webserver /test.sh
```

Make sure you replace `<username>` with your Github username.

Commit and push:

```
$ git add .drone.yml
$ git commit
$ git push -m "Add test stage"
```

Now check the UI and the code should rebuild and include the new stage. 

To ensure that the test is working properly, try changing the go code to output
a different string. Ensure that the test fails and the build goes red. Fix the
build again afterwards.

## Bonus Task

Remove the test script from the _image_ by editing the Dockerfile and copy it
into the test container with `docker cp` before running the test. This way the
final image should not contain the test file, but should still have been tested.


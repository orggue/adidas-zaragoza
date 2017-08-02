\pagebreak

# Docker Compose 

In this exercise we'll briefly explore the Docker Compose tool.

First we will insure docker-compose is installed

On your ubuntu machine

```
$ sudo apt-get install -y docker-compose
```

Create a file `docker-compose.yml` with the following contents:

```
version: '2'
services:
  identidock:
    image: amouat/identidock
    ports:
      - "5000:5000"
    environment:
      ENV: DEV

  dnmonster:
    image: amouat/dnmonster:1.0

  redis:
    image: redis:3.0
```

This file defines three containers, identidock, dnmonster and redis. They all
have associated images and the identidock container also exposes a port to the
host and sets an environment variable.

Try starting the service:

```
$ docker-compose up -d
...
```

You should now be able to access the application at http://localhost:5000

Try some of the other Compose commands that you can list with `docker-compose
--help` e.g. `logs` and `ps`.

## Bonus Task

Try to build a docker compose file for your favorite development stack.

### Set up local GitLab for CI/CD

Requirements: 

- Docker
- GitLab Account

----

### Optional - Run GitLab locally (in Docker containers)

If you wish to use gitlab.com, you can skip the next few slides.

Launch GitLab (Docker image) and Registry together with Docker Compose (./docker-compose.yaml)

```
version: '2'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.example.com:8080'
        # Add any other gitlab.rb configuration here, each on its own line
    volumes:
      - ./srv/gitlab/config:/etc/gitlab
      - ./srv/gitlab/logs:/var/log/gitlab
      - ./srv/gitlab/data:/var/opt/gitlab
    ports:
      - "8043:443"
      - "8080:80"
      - "8022:22"
  registry:
    image: registry
    volumes:
      - ./registry-stuff:/registry
    ports:
      - "5000:5000"
    environment:
      - STORAGE_PATH=/regitry
```

----


```
docker-compose up -d gitlab registry
```

Follow logs to ensure GitLab launches without error. (This may take a couple of minutes)

```
docker logs -f cicd_gitlab_1
```

Open localhost:8080 in browser

----

Enter new password (username is `root`)

[Change Password](resources/gitlabPwd.png)

----

We'll create a new project in GitLab to use for this lab

Create a new project called `nodejs-example`

----

Push application code to GitLab
(Copy the source code to another folder)
```
cp -R nodejs-example /tmp/
cd /tmp/nodejs-example
git init
git remote add origin https://gitlab.com/[username]/nodejs-example.git
git add .
git commit -m "Initial commit"
git push -u origin master
```

----

Add ci config file

...


----

Return to the Gitlab UI and verify your project is there

[Project](resources/gitlab-project.png)

----

### Setup GitLab runner

(Optional if using gitlab.com)

```
docker-compose up -d gitlab-runner
```

From Gitlab UI

-> Settings -> CI/CD Pipeline

Copy the register token

[Token](resources/gitlab-regsiter.png)

----

(Optional if using gitlab.com)

Register runner with our GitLab server.

```
docker exec -it cicd_gitlab-runner_1 bash
[container]:/# sudo gitlab-runner register
Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://gitlab/ci
Please enter the gitlab-ci token for this runner:
TeX7tDK1FxsUiJwNXRdh
Please enter the gitlab-ci description for this runner:
[8080437060ff]: test
Please enter the gitlab-ci tags for this runner (comma separated):

Whether to lock Runner to current project [true/false]:
[false]:
Registering runner... succeeded                     runner=3wz14i9P
Please enter the executor: docker, docker-ssh, parallels, virtualbox, shell, ssh, docker+machine, docker-ssh+machine, kubernetes:
docker
Please enter the default Docker image (e.g. ruby:2.1):
node
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

----









----

Clean up 

```
docker-compose down
rm -rf ./srv
```

----

[Fin...](../01_outline.md)

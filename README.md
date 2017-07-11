# Training-modules
Training modules for all kind of trainings


| ID  | Module Name Topics                 | Contents                                                                                  |
|-----|------------------------------------|-------------------------------------------------------------------------------------------|
| CE  | Container Essentials               | Docker theory, Docker cli, images, namespaces,...                                         |
| DE  | Docker Essentials                  | Docker, Use cases, How it works, Images, Registries, Volumes, Deployment                  |
| AC  | Advanced Containers                | Volumes,                                                                                  |
| CP  | Containers in Production*          | Ops                                                                                       |
| CSE | Container Security Essentials      |                                                                                           |
| ACS | Advanced Container Security        |                                                                                           |
| KE  | Kubernetes Essentials              | kubectl, pods, services, Deployments mainly focus on core API pricinpels (non alpha/beta) |
| AK  | Advanced Kubernetes                | Ingress, GKE, ConfigMaps, Volumes, init containers, jobs, scheduled jobs                  |
| KP  | Kubernetes in Production*          | Multi-Master, AuthZ/N...                                                                  |
| KI  | Installing Kubernetes              | Different Methods, Binaries, Container, Static Pods,...                                   |
| OE  | OpenShift Essentials               | S2I, cmdline utils, web ui, registry...                                                   |
| ME  | Microservices Essentials           | Theory, Patterns, APIs (Swagger etc.), Testing  etc.                                      |
| AM  | Advanced Microservices             | F02H hands-on parts, ContainerPilot                                                       |
| CNE | Cloud Native NoSQL Essentials**    | Tech landscape, concepts, CAP, interacting with the DB                                    |
| CNP | Cloud Native NoSQL in Production*  | Operation, Backup/Recovery, Bulk data, data modeling                                      |
| PE  | Prometheus Essentials              | Scraping, Query Language, Alerting, Building dashboards...                                |
| DTE | Distributed Tracing Essentials     | Dapper, OpenTracing, ZipKin, app integration (Go/Java/Node..)                             |
| CLE | Cloud Native Logging Essentials    | fluentd, app integration, comparison to ELK stack                                         |
| CDC | Continuous Delivery with Containers| Intro & Background to CI/CD, practicals with Drone, Docker, k8s                           |
| MCM | Modern Configuration Management    | Nix, Habitat                                                                              |
| TE  | Terraform Essentials               |                                                                                           |
| AE  | Ansible Essentials                 |                                                                                           |
| ME  | Mesos Essentials                   | Installation, Marathon,                                                                   |
| AM  | Advanced Mesos                     | Framework development, working with Minimesos                                             |
| MP  | Mesos in Production*               | Running production grade Zookeeper… Debugging                                             |
| AKE | Apache Kafka Essentials            | Concepts, Clients etc.                                                                    |
| SE  | Scheduling Essentials              | Concepts,                                                                                 |

*) Flavours: GCE, AWS, Azure, Metal (leveraging the respective tools like EC2/Azure Container Service)

**) Flavours: MongoDB, ElasticSearch

## Usage

Content is written in Markdown designed to be shown as a revealjs presentation.

From any of the course directories, you should be able to run:

```
$ docker run -d  -p 8000:1948 -v $PWD:/usr/src/app containersol/reveal-md
```

Then browse to localhost:8000 to see the presentation.


## Suggested Workflow (by AM)

For a specific training, create a new branch. In this branch, remove the modules
you don't need and make any unique changes (e.g. date, title). Any fixes or
general improvements should be made to the _master_ branch and cherrypicked into
the specific branch. If I find branches have fixes not in master, I will change
all example code to Fortran 77.

(I did steal this workflow the Google SRE book's chapter on releases)

## Creating PDFs

Instructions to follow...

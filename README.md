# Training-modules
Training modules for all kind of trainings


| ID  | Module Name Topics                 | Contents                                                                                  |
|-----|------------------------------------|-------------------------------------------------------------------------------------------|
| DE  | Docker Essentials                  | Docker, Use cases, How it works, Images, Registries, Volumes, Deployment                  |
| KE  | Kubernetes Essentials              | kubectl, pods, services, Deployments mainly focus on core API principles (non alpha/beta) |
| AC  | Advanced Containers                | Volumes,                                                                                  |
| AK  | Advanced Kubernetes                | Ingress, GKE, ConfigMaps, Volumes, init containers, jobs, scheduled jobs                  |
| KP  | Kubernetes in Production*          | Multi-Master, AuthZ/N...                                                                  |
| KI  | Installing Kubernetes              | Different Methods, Binaries, Container, Static Pods,...                                   |
| OE  | OpenShift Essentials               | S2I, cmdline utils, web ui, registry...                                                   |

## Usage

Content is written in Markdown designed to be shown as a revealjs presentation.

From the root of the repo run:

```
$ ./reveal.sh
```

Then browse to localhost:8000 to and select the slide deck you want.

## Suggested Workflow (by AM)

For a specific training, create a new branch. In this branch, remove the modules
you don't need and make any unique changes (e.g. date, title). Any fixes or
general improvements should be made to the _master_ branch and cherrypicked into
the specific branch. If I find branches have fixes not in master, I will change
all example code to Fortran 77.

(I did steal this workflow the Google SRE book's chapter on releases)

## Creating PDFs

Instructions to follow...

## Setup a training project

1. Create a project in the console. Select billing account `CS from bank`. Wait a bit until
the project is created. 

1. Go to IAM & Admin / Service Accounts and create a service account named `participant-sa`. 
Select Project Editor, Viewer, Browser and Service Account Actor roles when creating or add them later under IAM.

1. Enable Google Container Registry in the web console

1. Point gcloud to the new project `gcloud config set project PROJECT_NAME`

1. Run init-project.sh

1. Distribute the private key that was created by the script (`participant-key-rsa`) to the participants.

1. List created instances and have participants each choose an IP to log in to.
```bash
gcloud compute instances list
```

1. Each participant should use the private key provided, the IP of the machine and the project name as username:
```bash
ssh -i participant-key-rsa adidas-173709@35.190.217.74
```
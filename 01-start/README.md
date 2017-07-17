## Setup a training project

1. Create a project in the console. Select billing account `CS from bank`. Wait a bit until
the project is created. 

1. Go to IAM & Admin / Service Accounts and create a service account named `participant-sa`. 
Select Project Editor, Viewer, Browser and Service Account Actor roles when creating or add them later under IAM.

1. Enable Google Container Registry in the web console

1. Run `./init-project.sh` and tell it to create a single participant. Once that is done have the VM create a cluster.
 (`gcloud compute ssh traininguser@participant-1 --command "./create-cluster-gke-norbac.sh"`).
 
 This will both test the VM and cluster creation and activate the quotas for the next step. Activation means
 they will be used so they will show up in the list without you having to search for them.

1. Ask Google to raise the following quotas on the project:

    P = number of participants
- Total SSD disk reserved (GB) : P * 10Gb
- Total persistent disk reserved (GB) : P * 30Gb
- CPUs : P * 6
- IP Addresses : P * 4

In a few hours an email will arrive from Google asking to verify the request by either transferring money or
pointing to another project that already had quotas raised. Reply to them saying the `container-solutions` project
already has that. In another few hours max the quotas should be raised.

1. Point gcloud to the new project `gcloud config set project PROJECT_NAME`

1. Run init-project.sh to create the rest 

1. Distribute the private key that was created by the script (`participant-key-rsa`) to the participants.

1. List created instances and have participants each choose an IP to log in to.
```bash
gcloud compute instances list
```

1. Each participant should use the private key provided, the IP of the machine and the project name as username:
```bash
ssh -i participant-key-rsa traininguser@35.190.217.74
```

1. Each participant should create 

### Notes

 * Participant permissions are controlled by the service account `participant-sa`. If they don't have access to something
 they should, go to IAM and add some more permissions.
 
 * The user on all VMs is `traininguser`. The private key is the same for everyone. You can get it in a bucket under the
 project. E.g: https://console.cloud.google.com/storage/browser/participant-pk/?project=adidas-173709&organizationId=879351307558
 
 You can also make this bucket public to share the key with participants.
 
 * Participants are expected to create their own clusters using either `./create-cluster-gke-norbac.sh` or
 `./create-cluster-gke-rbac.sh` for RBAC enabled clusters. They will find these scripts in their home directories.
 
 * For any commands that need a project ID, the ID is stored in PROJECT variable (`echo $PROJECT`)
 
 
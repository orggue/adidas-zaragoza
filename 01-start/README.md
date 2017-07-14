## Setup a training project

1. Create a project in the console. Select billing account `CS from bank`. Wait a bit until
the project is created. 

2. Go to IAM & Admin / Service Accounts and create a service account named `participant-sa`. 
Select Project Editor, Viewer, Browser and Service Account Actor roles when creating or add them later under IAM.

4. Enable Google Container Registry in the web console

4. Point gcloud to the new project `gcloud config set project PROJECT_NAME`

5. Run init-project.sh
<h1>Installation</h1>
To create instances you need first to install 
* install gcloud tool https://cloud.google.com/sdk/
* run
```bash
gcloud auth login
```

* Create service account credentials at https://console.cloud.google.com
* Go to API Manager -> Create Credentials -> Service Account Key

<h1>Usage</h1>
* to create 20 machines 
```bash
$ export TF_VAR_USER_COUNT=20
$ source settings.sh
$ packer build packer.json
$ terraform plan
$ terraform apply
```
* to force recreation of the base image and create 20 machines
```bash
$ export TF_VAR_USER_COUNT=20
$ source settings.sh
$ packer build -force packer.json
$ terraform plan
$ terraform apply
```
as the result you will get a list of ssh commands (also in .userfile file)

* to destroy the 20 machines
$ terraform destroy -f

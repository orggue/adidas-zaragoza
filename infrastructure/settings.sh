#!/usr/bin/env bash
export TF_VAR_workshop_network="${TF_VAR_workshop_image:-workshop}"
export TF_VAR_project="${TF_VAR_project:-swisscom-bigdata}"
export TF_VAR_zone="${TF_VAR_zone:-europe-west1-b}"
export TF_VAR_region="${TF_VAR_region:-europe-west1}"
export TF_VAR_machine_type="${TF_VAR_machine_type:-n1-standard-2}"
export TF_VAR_base_image="${TF_VAR_base_image:-ubuntu-1604-xenial-v20170113}"
export TF_VAR_credentials_file_path="${TF_VAR_credentials_file_path:-cs-ag-5ff79512f685.json}"
#export TF_VAR_credentials_file_path="${TF_VAR_credentials_file_path:-~/.config/gcloud/credentials}"
export TF_VAR_user_count="${TF_VAR_user_count:-35}"
export TF_VAR_workshop_image="${TF_VAR_workshop_image:-workshop-image}"
TF_VAR_workshop_names=""
TF_VAR_passwords=""
for (( c=0; c<=($TF_VAR_user_count-1); c++ )); do
  TF_VAR_workshop_names="$TF_VAR_workshop_names\"$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w7 | head -n1 | tr '[:upper:]' '[:lower:]')\"",""
  TF_VAR_passwords="$TF_VAR_passwords\"$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w6 | head -n1 | tr '[:lower:]' '[:upper:]')\"",""
done
export TF_VAR_workshop_names="[${TF_VAR_workshop_names:0:${#TF_VAR_workshop_names}-1}]"
export TF_VAR_passwords=["${TF_VAR_passwords:0:${#TF_VAR_passwords}-1}]"

mkdir upload/

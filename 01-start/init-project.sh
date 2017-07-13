#!/usr/bin/env bash
set -eu

read -p 'Number of participants to create: ' nrofpart
read -p 'Number of exisiting instances: ' existingpart
export PROJECT=$(gcloud config get-value project)
export CUSTOMER_ID=${PROJECT}
export NR_OF_PARTICIPANTS=${nrofpart}
export EXISTING_PARTICIPANTS=${existingpart}

export ZONE=europe-west1-b

export SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format='value(email)' --filter='displayName:participant-sa')
if [[ -z "$SERVICE_ACCOUNT" ]]; then
    echo "Service account participant-sa has to be created"
    exit 1
fi

#./create-participant-vms.sh

gcloud compute instances list

echo "ssh -i participant-key-rsa ${CUSTOMER_ID}@IP"
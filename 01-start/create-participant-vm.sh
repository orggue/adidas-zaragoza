#!/usr/bin/env bash
set -eu

gcloud compute --project "${PROJECT}" instances create "${PARTICIPANT_ID}" \
    --zone "${ZONE}" \
    --machine-type "n1-standard-2" \
    --subnet "default" \
    --metadata "ssh-keys=${CUSTOMER_ID}:${SSH_PUBLIC_KEY}" \
    --service-account "${SERVICE_ACCOUNT}" \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --image "ubuntu-1704-zesty-v20170619a" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "10" --boot-disk-type "pd-ssd" --boot-disk-device-name "${PARTICIPANT_ID}"

sleep 30

gcloud compute scp init-vm.sh ${PARTICIPANT_ID}:~/
gcloud compute ssh ${PARTICIPANT_ID} --command "sed -i 's/CUSTOMER_ID/${CUSTOMER_ID}/g' ~/init-vm.sh"
gcloud compute ssh ${PARTICIPANT_ID} --command "~/init-vm.sh"
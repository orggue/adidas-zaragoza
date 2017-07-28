#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    read -p 'Name of the cluster: ' clustername
else
    clustername=$1
fi

gcloud container clusters create "${clustername}" \
--zone "europe-west1-b" \
--num-nodes "3" \
--username="admin" \
--cluster-version "1.6.7" \
--machine-type "n1-standard-1" \
--disk-size "20" \
--network "default" \
--enable-cloud-logging \
--no-enable-cloud-monitoring

gcloud container clusters get-credentials ${clustername}

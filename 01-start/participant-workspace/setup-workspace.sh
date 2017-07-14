#!/usr/bin/env bash
set -eu

gcloud config set compute/zone europe-west1-b

echo "Participant workspace initialised. gcloud and kubectl are installed and configured."
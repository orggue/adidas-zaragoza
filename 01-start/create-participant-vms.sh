#!/usr/bin/env bash
set -eu

if [ ! -f ./participant-key-rsa ]; then
    ssh-keygen -t rsa -C "${USER_ID}@contianer-solutions.com" -f ./participant-key-rsa -N ''
fi

export SSH_PUBLIC_KEY=$(cat participant-key-rsa.pub)
export PRIVATE_KEY_FILE=participant-key-rsa

for ((i = $EXISTING_PARTICIPANTS + 1; i <= $NR_OF_PARTICIPANTS + $EXISTING_PARTICIPANTS; i++)); do
   echo "Creating Instance for participant $i"
   export PARTICIPANT_ID="participant-$i"
   ./create-participant-vm.sh
   echo "Instance $PARTICIPANT_ID created successfully"
done
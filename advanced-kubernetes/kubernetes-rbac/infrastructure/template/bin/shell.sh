gcloud config set project PROJECT_ID
gcloud config set compute/zone COMPUTE_ZONE
gcloud auth activate-service-account ADMIN_ACCOUNT --key-file=keys/ADMIN_SHORT
gcloud container clusters get-credentials CLUSTER_NAME

# Remove auth provider
head -n-7 < ~/.kube/config > ~/.kube/config2
mv ~/.kube/config2 ~/.kube/config

gcloud auth activate-service-account ALICE_ACCOUNT  --key-file=keys/ALICE_SHORT
gcloud auth activate-service-account BOBBY_ACCOUNT  --key-file=keys/BOBBY_SHORT
gcloud auth activate-service-account MONKEY_ACCOUNT --key-file=keys/MONKEY_SHORT

export ALICE=ALICE_ACCOUNT
export BOBBY=BOBBY_ACCOUNT
export MONKEY=MONKEY_ACCOUNT

export PATH=`pwd`/bin:$PATH

bash

#!/bin/bash
project_id=$1
repository=$2
app_name=$3
echo "project_id: $project_id"
# gcloud auth configure-docker us-east1-docker.pkg.dev   # This is required to authenticate docker to push images to GCP
docker build -t us-east1-docker.pkg.dev/$project_id/$repository/$app_name:latest .
docker push us-east1-docker.pkg.dev/$project_id/$repository/$app_name
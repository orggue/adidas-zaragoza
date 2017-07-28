#!/bin/bash

if [ -z "${1}" ]; then
	version="latest"
else
	version="${1}"
fi

cd nodejs-example
docker build -t localhost:5000/my_nodejs_image:${version} .
cd ..

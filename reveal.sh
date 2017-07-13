#!/bin/bash

docker run -d  -p 8000:1948 -v $PWD:/usr/src/app containersol/reveal-md
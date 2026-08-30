#!/bin/bash

echo "Deploying application..."
docker build -t intern-app .
docker run -d intern-app

echo "Done"

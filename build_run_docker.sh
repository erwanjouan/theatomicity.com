#!/bin/sh
IMAGE_NAME=static_web_hosting
HOST_PORT=8080
docker build -t $IMAGE_NAME .
echo $IMAGE_NAME running on localhost:$HOST_PORT
docker run -p $HOST_PORT:80 $IMAGE_NAME
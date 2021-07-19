# cdsw-engine
Custom builds based on Cloudera's CDSW engine docker images

## build

Build cmds:
```
IMAGE=cdsw-engine-cuda
DOCKER_REPO="scigility/${IMAGE}"
TAG=14-cml-2021.05-1-cuda

docker build --network host -t ${IMAGE}:$TAG -f ${IMAGE}.Dockerfile

```

## deploy to dockerhub

First ensure you are logged in at Docker Hub, for ex via:
```
docker login docker.io
```

Deploy cmds:
```
#docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

docker tag ${IMAGE}:$TAG  ${DOCKER_REPO}:$TAG
docker push ${DOCKER_REPO}:$TAG
```

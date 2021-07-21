# cdsw-engine
Custom builds based on Cloudera's CDSW engine docker images

## build

Build cmds:
```
IMAGE=cdsw-engine-cuda
DOCKER_REPO="scigility/${IMAGE}"
#DOCKER_REPO="scigilityacademy/${IMAGE}"

# load the TAG variable from the file
source VERSION

# Important to set the format docker option, when using "podman" (on Fedora for ex)
#docker build --network host -t ${IMAGE}:$TAG -f ${IMAGE}.Dockerfile
docker build --format docker --network host -t ${IMAGE}:$TAG -f ${IMAGE}.Dockerfile
```

## deploy to dockerhub

First ensure you are logged in at Docker Hub, for ex via:
```
docker login docker.io
```

Deploy cmds:
```
docker tag ${IMAGE}:$TAG  ${DOCKER_REPO}:$TAG
docker push ${DOCKER_REPO}:$TAG
```

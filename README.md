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
#docker build --format docker --network host -t ${IMAGE}:$TAG -f ${IMAGE}.Dockerfile
```

### Build for different CUDA Version

Override the CUDA Version to use using the configurable "build-args":
```

# Versions available as of 2021-07-19: 11.0.221, 11.3.109
CUDA_V_MAJOR=11
CUDA_V_MINOR=3
CUDA_V_PATCH=109
TAG=13-cuda${CUDA_V_MAJOR}.${CUDA_V_MINOR}-2021.07.22-b2

docker build --format docker --network host \
 -t ${IMAGE}:$TAG \
 --build-arg CUDA_V_MAJOR=${CUDA_V_MAJOR} \
 --build-arg CUDA_V_MINOR=${CUDA_V_MINOR}  \
 --build-arg CUDA_V_PATCH=${CUDA_V_PATCH} \
 -f ${IMAGE}.Dockerfile
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

# Dockerfile to build a CUDA-capable CDSW(legacy) engine image
# originally based on: https://docs.cloudera.com/machine-learning/cloud/gpu/topics/ml-custom-cuda-engine.html
# TODO use in build >b2
ARG IMAGE_NAME=docker.repository.cloudera.com/cdsw/engine
ARG IMAGE_TAG=13
FROM ${IMAGE_NAME}:${IMAGE_TAG}
#FROM docker.repository.cloudera.com/cdsw/engine:13

RUN rm -f /etc/apt/sources.list.d/*
RUN apt-get update && apt-get install -y --no-install-recommends \
  gnupg2 curl ca-certificates && \
  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
  echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
  echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
  apt-get purge --autoremove -y curl && \
  rm -rf /var/lib/apt/lists/*

# Versions available as of 2021-07-19: 11.0.221, 11.3.109
ARG CUDA_V_MAJOR=11
ARG CUDA_V_MINOR=0
ARG CUDA_V_PATCH=221

ENV CUDA_VERSION_MINOR     ${CUDA_V_MAJOR}.${CUDA_V_MINOR}
ENV CUDA_VERSION           ${CUDA_V_MAJOR}.${CUDA_V_MINOR}.${CUDA_V_PATCH}
ENV CUDA_PKG_VERSION_MINOR ${CUDA_V_MAJOR}-${CUDA_V_MINOR}
#ENV CUDA_PKG_VERSION ${CUDA_PKG_VERSION_MINOR}=${CUDA_VERSION}-1

LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  cuda-cudart-${CUDA_VERSION_MINOR} \
  cuda-libraries-${CUDA_PKG_VERSION_MINOR} && \
  ln -s cuda-${CUDA_VERSION_MINOR} /usr/local/cuda && \
  rm -rf /var/lib/apt/lists/*

RUN echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
  ldconfig

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
  echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
  
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda-${CUDA_VERSION_MINOR}/targets/x86_64-linux/lib/
    
RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# Note: Using the exact same version as installed currently on Sxx cluster
ENV CUDNN_VERSION 8.2.0.53
ENV CUDNN_VERSION_MAJOR 8
ENV CUDNN_CUDA_VERSION 11.3
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
    
RUN apt-get update && apt-get install -y --no-install-recommends \
  libcudnn${CUDNN_VERSION_MAJOR}=$CUDNN_VERSION-1+cuda${CUDNN_CUDA_VERSION} && \
  apt-mark hold libcudnn${CUDNN_VERSION_MAJOR} && \
  rm -rf /var/lib/apt/lists/*

# 2021-10-26: Add python-3.8 via ppa repo
# inspired from https://stackoverflow.com/questions/68843848/installing-python-3-9-on-cloudera-cdsw-without-sudo
RUN apt-get update && apt-get install -y --no-install-recommends \
  software-properties-common  && \
  add-apt-repository ppa:deadsnakes/ppa  && \
  apt install -y  python3.8  python3-pip  && \
  rm -rf /var/lib/apt/lists/*  
#   && rm /etc/apt/sources.list.d/*

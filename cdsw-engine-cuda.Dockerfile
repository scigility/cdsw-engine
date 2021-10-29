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
#RUN apt-get update && apt-get install -y --no-install-recommends \
#  software-properties-common  && \
#  add-apt-repository ppa:deadsnakes/ppa  && \
#  apt install -y  python3.8  python3-pip  && \
#  rm -rf /var/lib/apt/lists/*  

# 2021-10-29: adding python from source from *official docker image*:
# Ref: https://github.com/docker-library/python/blob/master/3.8/buster/Dockerfile
# 3.8.6: https://github.com/docker-library/python/blob/5590cdd4367f088277bb5494d0a0b0f65e9ab491/3.8/buster/Dockerfile
# ensure local python is preferred over distribution python
## Changes vs the original:
# I replaced the gpg keyserver by hkp://keyserver.ubuntu.com:80
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
		libbluetooth-dev \
		tk-dev \
		uuid-dev \
	&& rm -rf /var/lib/apt/lists/*

ENV GPG_KEY E3FF2839C048B25C084DEBE9B26995E310250568
ENV PYTHON_VERSION 3.8.6

RUN set -ex \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
	&& make install \
	&& rm -rf /usr/src/python \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
			-o \( -type f -a -name 'wininst-*.exe' \) \
		\) -exec rm -rf '{}' + \
	\
	&& ldconfig \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
# Customizations (LH) We do not want override the default python2 links
# RUN cd /usr/local/bin \
# 	&& ln -sf idle3 idle \
# 	&& ln -sf pydoc3 pydoc \
# 	&& ln -sf python3 python \
# 	&& ln -sf python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
#ENV PYTHON_PIP_VERSION 20.3.3
# Customizations (LH): upgrade to later pip
ENV PYTHON_PIP_VERSION 21.3.1
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/5f38681f7f5872e4032860b54e9cc11cf0374932/get-pip.py
ENV PYTHON_GET_PIP_SHA256 6a0b13826862f33c13b614a921d36253bfa1ae779c5fbf569876f3585057e9d2

# Customizations (LH): s/python/python3/ ; s/pip/pip3/
RUN set -ex; \
	\
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	\
	python3 get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip3 --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py


# Cloudera's cdsw-engine (base image) analysis
Since unfortunately, Cloudera does not have it's CDSW build Dockerfile open-sourced
we can only analyse the dockerhub Layers info, which provides most of the CMDs used, but we cannot easily look at any custom files/configs added in the image via "COPY".

Custom builds based on Cloudera's CDSW engine docker images
## Analysis of the cdsw-engine:14
This was the base image used in our custom image build: 
https://hub.docker.com/layers/scigility/cdsw-engine-cuda/14-cuda11.0-py38-2021.10.26-b1/images/sha256-9fa6319bd3a7cc70f19aa4e66aea0ebabdbe7b94590d7d4d09f3753fc5c18a56?context=repo

Below, I copied Layer lines that I found the most relevant install steps, prefixed by the LINE number
* 17: the main apt update & install of deps is done, layer size >1.37GB !:
```
/bin/sh -c apt-get update && apt-get dist-upgrade -y &&   apt-get update && apt-get install -y --no-install-recommends   build-essential   openjdk-8-jdk-headless   pkg-config   cmake   swig   scons   locales   software-properties-common   apt-transport-https   ntp   command-not-found   bash-completion   gettext   libfreetype6   libglib2.0-dev   libgtk2.0.0   gsettings-desktop-schemas   fonts-dejavu   fonts-roboto   apt-utils   texlive-base   texlive-latex-base   texlive-latex-extra   texlive-fonts-extra   texlive-fonts-recommended   texlive-generic-recommended   texlive-extra-utils   texinfo   dvipng   lmodern   tipa   tex-gyre   prosper   file   bsdmainutils   subversion   ftp   nmap   krb5-user   wget   gzip   zip   curl   nano   mercurial   emacs-nox   jed   unzip   htop   tmux   sed   ftp   less   mlocate   info   man-db   manpages   dnsutils   traceroute   rsync   pandoc   mlocate   freetds-bin   net-tools   vim   mysql-client   postgresql-client   at   ed   ssh   lshw   lsof   ltrace   strace   tcpdump   iputils-ping   socat   uml-utilities   iperf   ocaml   info   sqlite3   gfortran   redis-server   lsb-release   procps   s3cmd   awscli   git   netcat   bzip2   libbz2-dev   liblzo2-dev   libsnappy-dev   liblzma-dev   zlib1g-dev   libjpeg-dev   libpng-dev   libtiff5   libxrender1   libsm6   libxext6   libicu-dev   libgdk-pixbuf2.0-dev   tcl   tcl-dev   tk   tk-dev   libglu1-mesa-dev   mesa-common-dev   librtmp-dev   libcairo2-dev   unixodbc-bin   libsqliteodbc   odbc-postgresql   tdsodbc   libfftw3-dev   libgmp-dev   libgomp1   libquadmath0   libsuitesparse-dev   libgsl-dev   libopenblas-dev   liblapack-dev   libkrb5-dev   libsasl2-dev   libauthen-sasl-perl    libsasl2-modules   libsasl2-modules-db   libsasl2-modules-gssapi-mit   libghc-gnutls-dev   ca-certificates   libglpk-dev   libaio-dev   llvm-dev   libhdf5-serial-dev   libgdal-dev   libproj-dev   libyaml-dev   libgeos-dev   libffi-dev   libexpat1   libsqlite3-dev   libxml2   sgml-base   xml-core   libpq-dev   libxt-dev   libcurl4-openssl-dev   libevent-dev   libzmq3-dev   libgdbm-dev   libssl-dev   libkuduclient-dev   libreadline-dev   cpio   &&   apt-get clean &&   apt-get autoremove &&   rm -rf /var/lib/apt/lists/* &&   update-alternatives --install /usr/lib/libblas.so.3 libblas.so.3 /usr/lib/x86_64-linux-gnu/openblas/libblas.so.3 40
```
* 25: ENV PYTHON2_VERSION=2.7.18
* 26: ENV PYTHON3_VERSION=3.6.10
* 29: install of miniconda2 4.8.3 (which sould support py 3.8.x, great!)
```
|1 PIPARGS=--no-cache-dir /bin/sh -c ./install-python.sh ${PYTHON2_VERSION} &&     ./install-python.sh ${PYTHON3_VERSION} &&     ln -sf /usr/local/bin/python2.7 /usr/local/bin/python &&     ln -sf /usr/local/bin/pip2.7 /usr/local/bin/pip &&     wget --quiet https://repo.anaconda.com/miniconda/Miniconda2-py27_4.8.3-Linux-x86_64.sh -O ~/miniconda.sh &&       /bin/bash ~/miniconda.sh -b -p /opt/conda &&       rm ~/miniconda.sh &&       /opt/conda/bin/conda config --system --set auto_update_conda false &&       /opt/conda/bin/conda config --set show_channel_urls yes &&       /opt/conda/bin/conda config --append channels conda-forge &&       /opt/conda/bin/conda config --append channels cloudera &&       /opt/conda/bin/conda config --append channels apache &&       /opt/conda/bin/conda config --append channels anaconda-cluster &&       /opt/conda/bin/conda update conda &&       /opt/conda/bin/conda clean --all --yes
```

* 30
```
  ENV PATH=/home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin
```

* 35: pip installs into dir /var/lib/cdsw/python2-engine-deps
```
|1 PIPARGS=--no-cache-dir /bin/sh -c pip install $PIPARGS -r /build/requirements-frozen2.txt --prefix=/var/lib/cdsw/python2-engine-deps -I &&     pip install $PIPARGS       ipython==5.1.0       requests==2.22.0       simplejson==3.16.0       numpy==1.16.5       pandas==0.24.2       pandas-datareader==0.8.0       py4j==0.10.8.1       futures==3.3.0       matplotlib==2.2.4       seaborn==0.9.0       cython==0.29.13 &&     pip install $PIPARGS kudu-python==1.2.0
```

* 37: prefix=/var/lib/cdsw/python3-engine-deps 
```
|1 PIPARGS=--no-cache-dir /bin/sh -c pip3 install $PIPARGS -r /build/requirements-frozen3.txt --prefix=/var/lib/cdsw/python3-engine-deps -I &&     pip3 install $PIPARGS       ipython==5.1.0       requests==2.22.0       simplejson==3.16.0       numpy==1.17.2       pandas==0.25.1       pandas-datareader==0.8.1       py4j==0.10.8.1       matplotlib==3.1.2       seaborn==0.9.0       cython==0.29.13 &&     pip3 install $PIPARGS kudu-python==1.2.0
```

* 42: SBT install
* 44: TOREE install
* 51: R install with libs into /usr/local/lib/R/lib
```
|1 PIPARGS=--no-cache-dir /bin/sh -c /build/install-r.sh

/bin/sh -c cd R && ./configure --with-x=no --enable-BLAS-shlib --enable-R-shlib --libdir=/usr/local/lib && make && make install
```
<TODO  continue update from engine v14 (below contains still mostly infos from v10!)>
* 58: R post-install:  /usr/local/bin/R 
* 63.. : nodejs installs

* 73: /bin/sh -c pip install /build/python-module &&     cd /build/python2-engine && npm install -g
* 76:  ..idem but "python3-engine"
* 70: ENV R_LIBS_USER=/home/cdsw/R
* 71: ENV R_LIBS=/home/cdsw/R:/usr/local/lib/R/library
* 81 /bin/sh -c cd /build/r-engine && npm install -g .
* 83: /bin/sh -c R CMD INSTALL /build/r-module
* 87 ScalaChunker lib !?
```
/bin/sh -c npm install -g &&     cd scala && 		sbt assembly -Ylog-classpath && 		cp target/scala-2.11/ScalaChunker-assembly-1.0.jar /usr/local/lib/node_modules/scala-engine/bin/ScalaChunker-assembly-1.0.jar
```
* 90 remove java ?!
```
/bin/sh -c apt-get remove -y --purge java-common openjdk-8-jdk-headless && apt-get autoremove -y
```
* 92: Rprofile.site is added!  
COPY file:c2b89c4c2ed2db5c062c6368aeafae8b421756e4ca29b19633ce1c16ee171a46 in /usr/local/lib/R/etc/Rprofile.site 
* 93: /bin/sh -c chown cdsw /usr/local/lib/R/etc/Rprofile.site
* 95: custom pip.conf
```
/bin/sh -c mkdir -p /root/.config/pip &&     printf "[install]\nuser = false" > /root/.config/pip/pip.conf
```
* 91: jupyter install
```
|1 PIPARGS=--no-cache-dir /bin/sh -c pip3 $PIPARGS install jupyter==1.0.0 &&     pip3 $PIPARGS install prompt-toolkit==1.0.15 && pip3 install $PIPARGS prompt-toolkit==1.0.15 --prefix=/var/lib/cdsw/python3-engine-deps
```

Important Learnings
- ONLY Python-wise only miniconda is installed and used. Nothing done related to the default python.
- And only "pip install" cmds, no "conda install"
- The used miniconda is quite old, and did not yet support python 3.8.x:
  Ticket https://github.com/conda/conda/issues/9343#issuecomment-654847276 showed that python 3.8.x support came earliest since 2019-10-xx, and since 2020-03-0x , Miniconda > 4.8.x it's the default
  - release notes did not help here: https://conda.io/projects/continuumio-conda/en/latest/release-notes.html#id64  # 4.7.10 (2019-07-19)


#FILE:    make_tensordocker.sh
#AUTHOR:  Karsten Suhre
#DATE:    Sun Dec 27 15:12:05 +03 2020
#PURPOSE: generate a docker image that runs GPU enabled R tensorflow
#         to run tensorflow with GPU support
#         (1) CUDA and (2) the NVIDIA runtime library for docker NVIDIA-DOCKER2
#         need to be installed on the host
#         see: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html
#         to check whether there is an nvidia GPU: 
#         >lspci | grep -i nvidia
#           0000:73:00.0 VGA compatible controller: NVIDIA Corporation GP102GL [Quadro P6000] (rev a1)
#           0000:73:00.1 Audio device: NVIDIA Corporation GP102 HDMI Audio Controller (rev a1)
#         to check whether CUDA is installed on the host
#         >nvidia-smi
#         remember to activate nvidia-persistenced at host reboot 
#           systemctl enable nvidia-persistenced
#           systemctl start nvidia-persistenced
#         using tensorflow/tensorflow:latest-gpu-jupyter
#           https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#           https://www.tensorflow.org/install/gpu
#           https://www.tensorflow.org/install/docker
#           https://jupyter-notebook.readthedocs.io/en/stable/index.html
#           https://rstudio.com/products/rstudio/download-server/debian-ubuntu/
#
#          use sshfs to mount exchange filesystem
#            sshfs kas2049@hpc007.advcomp.lan:/data /home/acfs/data
#            sshfs kas2049@hpc007.advcomp.lan: /home/acfs/home
#
#          dependencies needed to install devtools ‘usethis’, ‘covr’, ‘httr’, ‘roxygen2’, ‘rversions’ are not available for package ‘devtools"
#          need to install missing dev libs on Ubuntu: libcurl4-openssl-dev libxml2-dev libssl-dev libgit2-dev
#          and libgit2-dev needs to be installed separately
#
#          to push the docker image to a gitlab registry (obsolete - should use github now):
#             docker commit ....
#             docker tag ...
#             docker login gitlab.com
#             docker push  ....
#              credentials: https://ksuhre:4meta-TOOLs@gitlab.com
#
#
#MODIF:   Fri Sep 10 15:56:58 +03 2021
#         - update versions, try to make it run with github
#         - get info on latest version of rstudio here: 
#           https://www.rstudio.com/products/rstudio/download-server/debian-ubuntu/
#              sudo apt-get install gdebi-core
#              wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb
#              sudo gdebi rstudio-server-1.4.1717-amd64.deb
#         - latest bioconductor (May 2021)
#           http://bioconductor.org/news/bioc_3_13_release/#getting-started-with-bioconductor-313
#         - latest tensorflow/tensorflow:latest-gpu-jupyter
#           docker pull tensorflow/tensorflow:latest-gpu-jupyter
#           docker run --rm  -it tensorflow/tensorflow:latest-gpu-jupyter /bin/bash
#
#          - using the github docker registry
#            https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
#              docker login ghcr.io
#              docker push ghcr.io/karstensuhre/IMAGE_NAME:latest
#
#           Mon Nov  8 10:47:22 +03 2021
#           - go to latest version of BioConductor
#             BiocManager::install(version = "3.14")
#             https://www.bioconductor.org/install/
#           - try versioned tensorflow docker images
#             https://hub.docker.com/r/tensorflow/tensorflow/
#             https://hub.docker.com/r/tensorflow/tensorflow/tags/
#             https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/dockerfiles
#           - tensorflow/tensorflow:2.4.1-gpu-jupyter 
#           - rstudio: https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2021.09.0-351-amd64.deb
#
#            Tue Nov  9 15:05:21 +03 2021
#           - add -n option to gdebi command - otherwise it does not install
#           - sometimes wget fails with "Unable to establish SSL connection" and "'wget' call had nonzero exit status"
#
#           - to get around timedatectl warning
#             https://askubuntu.com/questions/1190804/timedatectl-failed-to-create-bus-connection-no-such-file-or-directory
#             need to add "--privileged -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket:ro" to the docker command
#             (not done yet)
#
# Mon 27 Mar 2023 04:40:17 PM +03
#           - creating updated version 2.0
#           - tensorflow/tensorflow:2.4.1-gpu-jupyter ==> tensorflow/tensorflow:2.12.0-gpu-jupyter
#           - rstudio-server-2021.09.0-351-amd64.deb ==> rstudio-server-2023.03.0-386-amd64.deb 
#           - BiocManager::install(version = "3.16") ==> BiocManager::install(version = "3.16")
#           - "krumsieklab/maplet@v1.1.0" ==> "krumsieklab/maplet@v1.2.1"
#           - added a few more libs that prevented installation of devtools
#
#BUGS:    

# if called with option "all", then all scripts are excuted 
opt=${1}

echo "running $0"
[ "$opt" = "" ] && echo "use $0 all to run everything without prompting"

docker image ls tensordocker
echo "Rebuild base docker image? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then
####################################################################
# create the Dockerfile as a here document
####################################################################
cat > tensordocker.dockerfile << 'EOF'
FROM tensorflow/tensorflow:2.12.0-gpu-jupyter
LABEL tensordocker.version=2.0
COPY tensordocker.installscript /
RUN sh /tensordocker.installscript
EXPOSE 8787
EOF
echo '------ tensordocker.dockerfile created ------'

####################################################################
# create the install script that runs in the docker image after the base image is loaded
####################################################################
cat > tensordocker.installscript << 'EOF2'
#!/bin/bash
set -x
echo "running $0"

# get the version of the image
lsb_release -a

export DEBIAN_FRONTEND=noninteractive

# update the distro
apt update -qq
apt-get update -y
apt-get install -y ssh wget 

# following https://cloud.r-project.org/bin/linux/ubuntu/
# include repository to install the latest version of R

# install two helper packages we need
sudo apt install --no-install-recommends software-properties-common dirmngr

# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# install some Linux utilities that were missing at some point (not sure they still do)
apt-get install -y gdebi-core dialog apt-utils vim apt-transport-https software-properties-common libglpk-dev
apt-get install -y libcurl4-openssl-dev libxml2-dev libssl-dev 
apt-get install -y libgit2-dev

# 27 March 2023
apt-get install -y libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

# install R
apt-get install -y r-base r-base-dev

# get rstudio
# https://rstudio.com/products/rstudio/download-server/debian-ubuntu/
# wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.3.1093-amd64.deb
# gdebi -n rstudio-server-1.3.1093-amd64.deb
# update 10 Sep 2021:
# wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb
# gdebi rstudio-server-1.4.1717-amd64.deb
# update 9 Nov 2021:
# wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2021.09.0-351-amd64.deb
# update 27 March 2023
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.03.0-386-amd64.deb 

gdebi -n rstudio-server-2023.03.0-386-amd64.deb 

# create a user 'rstudio' 
adduser rstudio <<PWD
pwd
pwd
rstudio
911
911
911
911
911
911
911
PWD

# install packages inside R
R --no-save << 'EEE'
install.packages("tensorflow")
install.packages("keras")

# install BioConductor
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
# BiocManager::install(version = "3.12")
# update 10 Sep 2021: 
# BiocManager::install(version = "3.13")
# update 8 Noc 2021
# BiocManager::install(version = "3.14")
# update 27 March 2023
BiocManager::install(version = "3.16")

# install devtools and remotes (needed to install MetaboTools and autonomics
BiocManager::install("devtools", update = FALSE)
BiocManager::install("remotes", update = FALSE)

EEE

echo "done running $0"
EOF2
echo '------ tensordocker.installscript created ------'

####################################################################
# build the docker image
####################################################################
echo '----- building docker image -----'
  docker container rm -f tensor_basis
  docker build -t tensordocker -f tensordocker.dockerfile --no-cache . | tee tensordocker.log
  echo "LOG of docker build is in tensordocker.log"
  echo '----------------------------------------'

fi
docker image ls tensordocker

####################################################################
# do some testing
####################################################################

echo "Run some tests? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then
  echo "remember to activate nvidia-persistenced at host reboot"

  echo "echo run nvidia-smi on host"
  nvidia-smi

  echo "echo run nvidia-smi on container"
  docker run --gpus all --rm tensordocker nvidia-smi
  docker run --gpus all --rm tensordocker nvcc --version

  echo "check whether tensorflow works in the container with python"
  docker run --gpus all -it --rm tensordocker \
     python -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"

  echo "check whether tensorflow works in the container with R"
  docker run --gpus all -it --rm tensordocker \
     R --no-save -e "tensorflow::tf_gpu_configured()"

fi

####################################################################
# continue to build the image further
####################################################################

echo "Build version with maplet and autonomics? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then

cat > tensordocker.basis.dockerfile << 'EOF3'
FROM tensordocker
LABEL tensordocker.version=2.0basis
COPY tensordocker.basis.installscript /
RUN sh /tensordocker.basis.installscript
EXPOSE 8787
EOF3

cat > tensordocker.basis.installscript << 'EOF4'
#!/bin/bash
set -x
echo "running $0"

apt-get install -y fortune

R --no-save << 'FFF'

# install MetaboTools
options(download.file.method='wget')

# update to maplet on github https://github.com/krumsieklab/maplet
# devtools::install_github(repo="krumsieklab/maplet@v1.0.1", subdir="maplet")
# update 8 Nov 2021
# devtools::install_github(repo="krumsieklab/maplet@v1.1.0", subdir="maplet")
# update 23 March 2023
devtools::install_github(repo="krumsieklab/maplet@v1.2.1", subdir="maplet")

# install autonomics from https://github.com/bhagwataditya/autonomics
# update 10 Sep 2021
# remotes::install_github('bhagwataditya/autonomics', repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
# update 23 March 2023
BiocManager::install("autonomics")

# install additional packages (if they are not already installed)
pkgs=c(
     "pacman",
     "GeneNet",
     "reshape2",
     "multtest",
     "hash",
     "igraph",
     "d3heatmap",
     "DT",
     "plotly",
     "pROC",
     "caret",
     "car",
     "voronoiTreemap",
     "broom.mixed",
     "lmerTest",
     "ggforce",
     "car",
     "rJava",
     "glmnet",
     "stabs",
     "mboost",
     "glmulti",
     "kableExtra",
     "ggpubr",
     "Rtsne",
     "uwot"
)

print(pkgs)
if (length(pkgs) > 0) {
  for (pkg in pkgs) {
    if (length(find.package(pkg, quiet = TRUE)) == 0) {
      cat('installing', pkg, '\n')
      BiocManager::install(pkg, ask=F,update=T, site_repository = getOption('repos'))
    } else { 
      cat('package', pkg, 'is already installed, skipping ...\\n') 
    } 
  } 
} 

FFF

echo "done running $0"
EOF4

echo '----- building docker image basis -----'
docker build -t tensordocker.basis -f tensordocker.basis.dockerfile --no-cache . | tee tensordocker.basis.log
echo "LOG of docker basis build is in tensordocker.basis.log"
echo '----------------------------------------'

fi

# test if wget always worked 
if [ `grep -c "Unable to establish SSL connection" tensordocker.basis.log` -gt 0 ] ; then 
  echo "WARNING: not all libraries were installed correctly - wget failed to establish SSL connections"
  echo "         the image may be incomplete (check tensordocker.basis.log)"
fi


####################################################################
# testing the basis version
####################################################################
echo "Start the basis version? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then

  docker container rm -f tensor_basis
  docker run --gpus all -v /home/suhre:/home/rstudio/host -v /ssd:/home/rstudio/ssd \
     -it --detach --name tensor_basis -p8899:8888 -p8877:8787 tensordocker.basis 
  docker exec -it tensor_basis rstudio-server start
  echo "to open a root shell use:  docker exec -it tensor_basis /bin/bash"
  echo "to access the rstudio GUI go to http://207.162.246.62:8877"
  echo "to access the jupyter workbook go to http://207.162.246.62:8899"
  echo "and use the below token to log in"
  sleep 3 # wait for the container to start up
  docker exec tensor_basis jupyter notebook list
fi


cat << EEOOFF1

# things to do now :

# push the image to gitbub
docker login ghcr.io
docker tag tensordocker.basis ghcr.io/karstensuhre/tensordocker:2.0
docker push ghcr.io/karstensuhre/tensordocker:2.0

# start the image
docker run --gpus all -v \`pwd\`:/home/rstudio/host -it --detach --name tensor -p8888:8888 -p8787:8787 ghcr.io/karstensuhre/tensordocker:2.0

# start the rstudio-server within the container
docker exec -it tensor rstudio-server start

# login to the container
docker exec -it tensor /bin/bash

# list the jupyter notebook token
docker exec tensor jupyter notebook list

EEOOFF1



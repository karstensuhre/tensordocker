#FILE:    make_tensordocker.sh
#AUTHOR:  Karsten Suhre
#DATE:    Sun Dec 27 15:12:05 +03 2020
#PURPOSE: generate a docker image that runs GPU enabled R tensorflow
#         to run tensorflow with GPU support
#         (1) CUDA and (2) the NVIDIA runtime library for docker NVIDIA-DOCKER2
#         need to be installed on the host
#         see: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html
#         to check whether the is an nvidia GPU: 
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
#          dependencies needed to install devtools ‘usethis’, ‘covr’, ‘httr’, ‘roxygen2’, ‘rversions’ are not available for package ‘devtools"
#          need to install missing dev libs on Ubuntu: libcurl4-openssl-dev libxml2-dev libssl-dev libgit2-dev
#          and libgit2-dev needs to be installed separately
#          to push the docker image to a registry:
#             docker commit ....
#             docker tag ...
#             docker login gitlab.com
#             docker push  ....
#              credentials: https://ksuhre:4meta-TOOLs@gitlab.com
#BUGS:    
#MODIF:   

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
FROM tensorflow/tensorflow:latest-gpu-jupyter
#FROM tensorflow/tensorflow:latest-gpu
LABEL tensordocker.version=1.0
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

# include repository to install the latest version of R
# https://cloud.r-project.org/bin/linux/ubuntu/README.html
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/'

# update the distro
apt-get update -y

# install Linux utilities
apt-get install -y ssh wget gdebi-core dialog apt-utils vim apt-transport-https software-properties-common libglpk-dev
apt-get install -y libcurl4-openssl-dev libxml2-dev libssl-dev 
apt-get install -y libgit2-dev

# install R
apt-get install -y r-base r-base-dev

# get rstudio
# https://rstudio.com/products/rstudio/download-server/debian-ubuntu/
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.3.1093-amd64.deb
gdebi -n rstudio-server-1.3.1093-amd64.deb

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
BiocManager::install(version = "3.12")

# install devtools and remotes (needed to install MetaboTools and autonomics
BiocManager::install("devtools")
BiocManager::install("remotes")

EEE

echo "done running $0"
EOF2
echo '------ tensordocker.installscript created ------'

####################################################################
# build the docker image
####################################################################
echo '----- building docker image -----'
  docker container rm -f tensor_beta
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

echo "Build beta version? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then

cat > tensordocker.beta.dockerfile << 'EOF3'
FROM tensordocker
LABEL tensordocker.version=1.0beta
COPY tensordocker.beta.installscript /
RUN sh /tensordocker.beta.installscript
EXPOSE 8787
EOF3

cat > tensordocker.beta.installscript << 'EOF4'
#!/bin/bash
set -x
echo "running $0"

apt-get install -y fortune

R --no-save << 'FFF'

# install MetaboTools
options(download.file.method='wget')
devtools::install_gitlab(repo='krumsieklab/mt', subdir = 'MetaboTools', auth_token='d_Sqxk2eoXEatrBq7euB')

# install autonomics
remotes::install_github('bhagwataditya/autonomics/autonomics.data',       repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.support',    repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.annotate',   repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.import',     repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.preprocess', repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.plot',       repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.find',       repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.ora',        repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics.integrate',  repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)
remotes::install_github('bhagwataditya/autonomics/autonomics',            repos = BiocManager::repositories(), dependencies = TRUE, upgrade = FALSE)

# install additional packages (if they are not already installed)
pkgs=c(
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
      cat('instaling', pkg, '\n')
      BiocManager::install(pkg, ask=F,update=T, site_repository = getOption('repos'))
    } else { 
      cat('package', pkg, 'is already installed, skipping ...\\n') 
    } 
  } 
} 

FFF

echo "done running $0"
EOF4

# UNCOMMENT THE BELOW TO RUN kldocker
# add kldocker dockerfile
# cat ../kldocker/Dockerfile_bioc | grep -v '^ *FROM' >> tensordocker.beta.dockerfile 
# cp ../kldocker/packagelist.txt .

echo '----- building docker image BETA -----'
docker build -t tensordocker.beta -f tensordocker.beta.dockerfile --no-cache . | tee tensordocker.beta.log
echo "LOG of docker BETA build is in tensordocker.beta.log"
echo '----------------------------------------'

fi


####################################################################
# testing the BETA version
####################################################################
echo "Start the beta version? [yN]"
if [ "$opt" = "all" ] ; then dummy=y ; else read dummy ; fi
if [ "$dummy" = "y" -o "$dummy" = "Y" ]  ; then

  docker container rm -f tensor_beta
  docker run --gpus all -v /home/suhre:/home/rstudio/host -v /ssd:/home/rstudio/ssd \
     -it --detach --name tensor_beta -p8899:8888 -p8877:8787 tensordocker.beta 
  docker exec -it tensor_beta rstudio-server start
  echo "to open a root shell use:  docker exec -it tensor_beta /bin/bash"
  echo "to access the rstudio GUI go to http://207.162.246.62:8877"
  echo "to access the jupyter workbook go to http://207.162.246.62:8899"
  echo "and use the below token to log in"
  sleep 3 # wait for the container to start up
  docker exec tensor_beta jupyter notebook list
fi

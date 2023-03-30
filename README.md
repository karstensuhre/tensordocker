# tensordocker

This repository provides a docker installation of R, rstudio, BioConductor together with maplet and autonomics in a CUDA enabled keras/tensorflow image. The github page for the image is [here](https://github.com/karstensuhre/tensordocker/pkgs/container/tensordocker).


## Running the docker image

To install the image from the command line: 
```bash
docker pull ghcr.io/karstensuhre/tensordocker:2.0
```

To run the docker image (adapt the -v option to mount the required local directory):
```bash
docker run -v /home:/home/rstudio/host -it --detach --name tensor -p8888:8888 -p8787:8787 ghcr.io/karstensuhre/tensordocker:2.0
docker exec tensor rstudio-server start
```

or using WSL
```bash
docker.exe run -v "C:\\Users":/home/rstudio/host -it --detach --name tensor -p8888:8888 -p8787:8787 ghcr.io/karstensuhre/tensordocker:2.0
docker.exe exec tensor rstudio-server start
```

Note that this command mounts the entire home directory (-v option). You may want to change this to a more limited scope.

To access the rstudio server:
* http://localhost:8787 (rstudio interface, user: rstudio, password: pwd)

To access the tensorflow jupyter notebook:
* http://localhost:8888 (tensorflow jupyter interface, token required - see below)

To obtain the jupyter login token:
```bash
docker exec tensor jupyter notebook list
```

To obtain a shell in the container:
```bash
docker exec -it tensor /bin/bash
```

## Creating the docker image from scratch

Note: this part is ONLY needed if you wish to recreate your own docker image.
It is NOT needed if you download the docker image from github.io (as explained above).
The script [make_tensordocker.sh](https://github.com/karstensuhre/tensordocker/blob/main/make_tensordocker.sh) can be used to generate the docker image from scratch.
Check out the head of [make_tensordocker.sh](https://github.com/karstensuhre/tensordocker/blob/main/make_tensordocker.sh) where I left useful comments and links.

To run the script interactively in steps and answer Y/N: 
```bash
./make_tensordocker.sh
```

To run the entire script without interactive prompting to create the image in one go:
```bash
./make_tensordocker.sh all
```

## Working with the docker image

Caution: When using *library(keras)* in R for the first time, **DO NOT** install a python library. It is already there. Answer **NO** to the install prompt! 

To test tensorflow:
```R
tensorflow::tf_gpu_configured()
```

You can run [mnist_example.R](https://github.com/karstensuhre/tensordocker/blob/main/mnist_example.R) for testing keras/tensorflow.

To update/install [maplet](https://github.com/krumsieklab/maplet) from the latest commit:
```R
devtools::install_github(repo="krumsieklab/maplet", subdir="maplet")
```


## Using GPU support

To use NVIDIA GPU support, [CUDA](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html) needs to be installed first.
Then run the following as root (once after boot):
```bash
sudo nvidia-persistenced
```

TO check if CUDA is working alright:
```bash
nvidia-smi
```

To start the docker image with GPU support use the --gpus option:
```bash
docker run --gpus all -v `pwd`:/home/rstudio/host -it --detach --name tensor -p8888:8888 -p8787:8787 ghcr.io/karstensuhre/tensordocker:2.0
```

Using rstudio you can then pull this github repository using the GIT functionality of R and then run [mnist_example.R](https://github.com/karstensuhre/tensordocker/blob/main/mnist_example.R) for testing the performance of the GPU. FOr comparision, there is also a python version that performs the same actions [mnist_example.py](https://github.com/karstensuhre/tensordocker/blob/main/mnist_example.py). It can runs be executed inside rstudio.

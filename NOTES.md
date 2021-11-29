# Notes

### Mounting a file system inside a docker image using sshfs

```bash
# start the docker image with the option --privileged=true
docker run --privileged=true -it --name container image /bin/bash

# install sshfs into the docker image
apt-get install sshfs

# run sshfs
sshfs -o uid=1000 -o gid=100 user@remote.machine.org:/data /mount/point
```

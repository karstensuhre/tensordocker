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


### How to compute log-p values in R using lm() summary stats

This works especially for p-values < 1E-320 which would otherwise be represented as zero. Try the below with N=10000 for an example!

```R
# create a simulated data set
N = 100
x = runif(N)
y = x + runif(N)
plot(x,y)

# compute a linear model
s0 = summary(lm(y ~ x))
print(s0)
print(s0$coef)

# get statistic and pvalue from the summary
t = s0$coef["x","Estimate"] / s0$coef["x","Std. Error"]
p = s0$coef["x","Pr(>|t|)"]

# compute the pvalue using the pt() function, the following two values should be identical
p
2*pt(-abs(t),df=N-2, log=FALSE)

# same for the log pvalue (this is the natural log)
log(p)
pt(-abs(t),df=N-2, log=TRUE) + log(2)


# the same for log10 ( pvalue )
log10(p)
log10(exp(1)) * ( pt(-abs(t),df=N-2, log=TRUE) + log(2) )

# thus: log10p = log10(exp(1)) * ( pt(-abs(beta/se),df=N-2, log=TRUE) + log(2) )
# where beta is the estimate of the effect size from the linear model and se its standard error 
```



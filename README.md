# arch
Minimalistic base image of Arch linux.
Many improvements inspired by [this stackoverflow answer](https://unix.stackexchange.com/questions/2027/how-do-i-minimize-disk-space-usage/233401#233401)

Size of uncompressed image is approximately 236 Mb.

# build

We are using most current bootstrap image which is usually released on the first of each month.

```
make build DOCKER=docker
```

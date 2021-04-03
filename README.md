# arch
Minimalistic base image of Arch linux.
Many improvements inspired by [this stackoverflow answer](https://unix.stackexchange.com/questions/2027/how-do-i-minimize-disk-space-usage/233401#233401)

Size of uncompressed image is approximately 236 Mb.
Image takes advantage of Arch Linux archives from the same day as this month's bootstrap release date.
This is to prevent issues that may arise due to updates GPG signing keys or updates to base packages that may be released during the month.

# build

We are using most recent bootstrap image which is usually released on the first of each month.

To build current image using podman:

```
make build
```

To build current image using docker:

```
make build DOCKER=docker
```

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

Note: sometimes bootstrap image is not released on the first of given month, in such case add BOOTSTRAP_DAY parameter when building the image and set it to another day which does not result in error.


## building images before June 2025

In June 2025 mirrors switched bootstrap file naming convention. If you wish to build images based on bootstrap from before June 2025 you'll need to include `${ARCH_BOOTSTRAP_VERSION}` in `ARCH_BOOTSTRAP_URL` in `Dockerfile`:

```diff
-RUN ARCH_BOOTSTRAP_URL=${ARCH_MIRROR}/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-${ARCH_BOOTSTRAP_VERSION}-x86_64.tar.zst \
+RUN ARCH_BOOTSTRAP_URL=${ARCH_MIRROR}/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-x86_64.tar.zst \
```

In July 2025 sig url cought up with the above change, to build images before July 2025 you'll need to include `${ARCH_BOOTSTRAP_VERSION}` in `ARCH_BOOTSTRAP_SIG_URL` in `Dockerfile`:

```diff
-    && ARCH_BOOTSTRAP_SIG_URL=https://archlinux.org/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-${ARCH_BOOTSTRAP_VERSION}-x86_64.tar.zst.sig \
+    && ARCH_BOOTSTRAP_SIG_URL=https://archlinux.org/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-x86_64.tar.zst.sig \
```

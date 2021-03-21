# arch
Minimalistic base image of Arch linux.
Many improvements inspired by [this stackoverflow answer](https://unix.stackexchange.com/questions/2027/how-do-i-minimize-disk-space-usage/233401#233401)

Size of uncompressed image is approximately 236 Mb.

# build

If Arch Linux archives exist at given date then you should be able to build an image using that as mirrors.

Example - build image like it was 2nd of January 2015:

```bash
make build ARCHIVE_DAY=02 ARCHIVE_MONTH=01 ARCHIVE_YEAR=2015 DOCKER=docker
```

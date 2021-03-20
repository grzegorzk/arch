SHELL=/bin/bash

DOCKER=podman

DAY=01
MONTH=$(shell date +%m)
YEAR=$(shell date +%Y)

IMG_NAME=arch

list:
	@ $(MAKE) -pRrq -f Makefile : 2>/dev/null \
		| grep -e "^[^[:blank:]]*:$$\|#.*recipe to execute" \
		| grep -B 1 "recipe to execute" \
		| grep -e "^[^#]*:$$" \
		| sed -e "s/\(.*\):/\1/g" \
		| sort

build:
	@ ${DOCKER} build \
		--build-arg ARCH_ARCHIVE_YEAR=${YEAR} \
		--build-arg ARCH_ARCHIVE_MONTH=${MONTH} \
		--build-arg ARCH_ARCHIVE_DAY=${DAY} \
		-t ${IMG_NAME} .;

run:
	@ ${DOCKER} run \
		--net=host -it --rm \
		${IMG_NAME} \
		/bin/bash

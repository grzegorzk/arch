SHELL=/bin/bash

DOCKER=podman
DOCKER_SECRET="${CURDIR}"/docker_access_token.secret

ARCHIVE_DAY=01
ARCHIVE_MONTH=$(shell date +%m)
ARCHIVE_YEAR=$(shell date +%Y)

BOOTSTRAP_DAY=01
BOOTSTRAP_MONTH=$(shell date +%m)
BOOTSTRAP_YEAR=$(shell date +%Y)

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
		--build-arg ARCH_ARCHIVE_YEAR=${ARCHIVE_YEAR} \
		--build-arg ARCH_ARCHIVE_MONTH=${ARCHIVE_MONTH} \
		--build-arg ARCH_ARCHIVE_DAY=${ARCHIVE_DAY} \
		--build-arg ARCH_BOOTSTRAP_YEAR=${BOOTSTRAP_YEAR} \
		--build-arg ARCH_BOOTSTRAP_MONTH=${BOOTSTRAP_MONTH} \
		--build-arg ARCH_BOOTSTRAP_DAY=${BOOTSTRAP_DAY} \
		-t ${IMG_NAME} .;

run:
	@ ${DOCKER} run \
		--net=host -it --rm \
		${IMG_NAME} \
		/bin/bash

push:
	@ $(MAKE) -s build DOCKER=docker;
	@ cat "${DOCKER_SECRET}" | docker login --username techgk --password-stdin
	@ docker tag ${IMG_NAME} techgk/arch:${ARCHIVE_YEAR}${ARCHIVE_MONTH}${ARCHIVE_DAY} \
		&& docker push techgk/arch:${ARCHIVE_YEAR}${ARCHIVE_MONTH}${ARCHIVE_DAY};
	@ docker tag ${IMG_NAME} techgk/arch:latest \
		&& docker push techgk/arch:latest;


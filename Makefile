SHELL=/bin/bash

DOCKER=podman
DOCKER_SECRET="${CURDIR}"/docker_access_token.secret

BOOTSTRAP_DAY=01
BOOTSTRAP_MONTH=$(shell date +%m)
BOOTSTRAP_YEAR=$(shell date +%Y)

PACMAN_ARCHIVES_DAY=01
PACMAN_ARCHIVES_MONTH=$(shell date +%m)
PACMAN_ARCHIVES_YEAR=$(shell date +%Y)


IMG_NAME=techgk/arch:${PACMAN_ARCHIVES_YEAR}${PACMAN_ARCHIVES_MONTH}${PACMAN_ARCHIVES_DAY}


list:
	@ $(MAKE) -pRrq -f Makefile : 2>/dev/null \
		| grep -e "^[^[:blank:]]*:$$\|#.*recipe to execute" \
		| grep -B 1 "recipe to execute" \
		| grep -e "^[^#]*:$$" \
		| sed -e "s/\(.*\):/\1/g" \
		| sort

build:
	@ ${DOCKER} build \
		--build-arg ARCH_BOOTSTRAP_YEAR=${BOOTSTRAP_YEAR} \
		--build-arg ARCH_BOOTSTRAP_MONTH=${BOOTSTRAP_MONTH} \
		--build-arg ARCH_BOOTSTRAP_DAY=${BOOTSTRAP_DAY} \
		--build-arg PACMAN_ARCHIVES_DAY=${PACMAN_ARCHIVES_DAY} \
		--build-arg PACMAN_ARCHIVES_MONTH=${PACMAN_ARCHIVES_MONTH} \
		--build-arg PACMAN_ARCHIVES_YEAR=${PACMAN_ARCHIVES_YEAR} \
		-t ${IMG_NAME} .;

run:
	@ ${DOCKER} run \
		--net=host -it --rm \
		${IMG_NAME} \
		/bin/bash

push:
	@ $(MAKE) -s build DOCKER=docker;
	@ cat "${DOCKER_SECRET}" | docker login --username techgk --password-stdin
	@ docker push ${IMG_NAME}
	@ docker tag ${IMG_NAME} techgk/arch:latest \
		&& docker push techgk/arch:latest;


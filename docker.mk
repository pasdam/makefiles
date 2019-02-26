# This makefile contains target related to docker.
# It expects the PROJECT_NAME variable to be defined, as it will be used as
# image name for all the commands.
# To use the automatically generated image's tag, the project must be in a git
# repository, as the tag will be the sha of the latest commit, plus the suffix
# ".dirty" if the repository contains uncommitted files.

ifndef DOCKER_IMAGE_TAG
__GIT_UNCOMMITTED_FILES := $(shell git status -s)
ifeq (__GIT_UNCOMMITTED_FILES, "")
	DOCKER_IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2> /dev/null)
else
	DOCKER_IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2> /dev/null).dirty
endif
endif

## docker-build: Build the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
.PHONY: docker-build
docker-build:
ifneq (__GIT_UNCOMMITTED_FILES, "")
	@echo "\033[33mThe repository contains local changes, this image should only be used for testing\033[0m";
endif
	@docker build --tag $(PROJECT_NAME):$(DOCKER_IMAGE_TAG) .

## docker-clean: Remove the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
##               This command WON'T delete any intermediate images, so those
##               should be manually removed.
.PHONY: docker-clean
docker-clean:
	@docker rmi $(PROJECT_NAME):$(DOCKER_IMAGE_TAG) || true

## docker-run: Run a docker container from the image with the tag
##             <PROJECT_NAME>: <DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##             defined it will be the git revision, plus ".dirty" suffix if the
##             repository contains uncommitted files. The container will be
##             automatically removed once stopped.
.PHONY: docker-run
docker-run: | docker-build
	@docker run -it --rm $(PROJECT_NAME):$(DOCKER_IMAGE_TAG)

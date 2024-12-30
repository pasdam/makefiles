# This makefile contains target related to docker.
# PROJECT_NAME is used as image name for all the commands. By default it's
# assumed to be the name of the folder where the command is executed, to
# specify a different one just define the PROJECT_NAME variable in your main
# makefile.
# To use the automatically generated image's tag, the project must be in a git
# repository, as the tag will be the sha of the latest commit, plus the suffix
# ".dirty" if the repository contains uncommitted files.

PROJECT_NAME ?= $(shell basename $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
DIRTY_SUFFIX := .dirty
DOCKER_IMAGE_TAG ?=
DOCKER_PATH ?= .
DOCKER_ENABLE_LATEST ?=
DOCKER_REPO ?=
DOCKERFILE_NAME ?= Dockerfile
DOCKERFILE_PATH ?= $(DOCKER_PATH)/$(DOCKERFILE_NAME)
ifneq ($(DOCKER_REPO),)
DOCKER_IMAGE_NAME := $(DOCKER_REPO)/$(PROJECT_NAME)
else
DOCKER_IMAGE_NAME := $(PROJECT_NAME)
endif
ifeq ($(DOCKER_IMAGE_TAG),)
__GIT_UNCOMMITTED_FILES := $(shell git status --porcelain | wc -l | bc)
DOCKER_IMAGE_TAG := $(shell git rev-parse --short HEAD 2> /dev/null)
ifneq "$(__GIT_UNCOMMITTED_FILES)" "0"
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG)$(DIRTY_SUFFIX)
endif
endif

## docker-build: Build the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
##               Set DOCKER_ENABLE_LATEST=true to tag the result image with
##               "latest".
.PHONY: docker-build
docker-build:
ifneq "$(__GIT_UNCOMMITTED_FILES)" "0"
	@echo "\033[33mThe repository contains local changes ($(__GIT_UNCOMMITTED_FILES) uncommitted files), this image should only be used for testing\033[0m";
endif
	@docker build --tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) --file $(DOCKERFILE_PATH) $(DOCKER_PATH)
	@echo "Image tag: "$(DOCKER_IMAGE_TAG)
ifeq ($(DOCKER_ENABLE_LATEST), true)
	@docker build --tag $(DOCKER_IMAGE_NAME):latest --file $(DOCKERFILE_PATH) $(DOCKER_PATH)
endif

## docker-clean: Remove the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
##               This command WON'T delete any intermediate images, so those
##               should be manually removed.
.PHONY: docker-clean
docker-clean:
	@docker rmi $(PROJECT_NAME):$(DOCKER_IMAGE_TAG) || true

## docker-push: Push the docker image with the tag
##              <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##              defined it will be the git revision.
##              Set DOCKER_ENABLE_LATEST=true to push the image with "latest"
##              tag as well.
.PHONY: docker-push
docker-push:
ifeq ($(patsubst %$(DIRTY_SUFFIX),,$(lastword $(DOCKER_IMAGE_TAG))),)
	$(error The image ${DOCKER_IMAGE_TAG} is only meant for local usage, unable to push it)
endif
	@docker push $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
ifeq ($(DOCKER_ENABLE_LATEST),true)
	@docker push $(DOCKER_IMAGE_NAME):latest
endif

## docker-run: Run a docker container from the image with the tag
##             <PROJECT_NAME>: <DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##             defined it will be the git revision, plus ".dirty" suffix if the
##             repository contains uncommitted files. The container will be
##             automatically removed once stopped.
.PHONY: docker-run
docker-run: | docker-build
	@docker run -it --rm $(PROJECT_NAME):$(DOCKER_IMAGE_TAG)

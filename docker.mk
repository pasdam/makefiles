# This makefile contains target related to docker.
# PROJECT_NAME is used as image name for all the commands. By default it's
# assumed to be the name of the folder where the command is executed, to
# specify a different one just define the PROJECT_NAME variable in your main
# makefile.
# To use the automatically generated image's tag, the project must be in a git
# repository, as the tag will be the sha of the latest commit, plus the suffix
# ".dirty" if the repository contains uncommitted files.

PROJECT_NAME ?= $(shell basename $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
DOCKER_PATH ?= .
DOCKERFILE_NAME ?= Dockerfile
DOCKERFILE_PATH ?= $(DOCKER_PATH)/$(DOCKERFILE_NAME)

## docker-build: Build the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
.PHONY: docker-build
docker-build: | docker-generate-tag
ifneq (__GIT_UNCOMMITTED_FILES, "")
	@echo "\033[33mThe repository contains local changes, this image should only be used for testing\033[0m";
endif
	@docker build --tag $(PROJECT_NAME):$(DOCKER_IMAGE_TAG) --file $(DOCKERFILE_PATH) $(DOCKER_PATH)
	@docker build --tag $(PROJECT_NAME):latest-local --file $(DOCKERFILE_PATH) $(DOCKER_PATH)

## docker-clean: Remove the docker image with the tag
##               <PROJECT_NAME>:<DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##               defined it will be the git revision, plus ".dirty" suffix if
##               the repository contains uncommitted files.
##               This command WON'T delete any intermediate images, so those
##               should be manually removed.
.PHONY: docker-clean
docker-clean: | docker-generate-tag
	@docker rmi $(PROJECT_NAME):$(DOCKER_IMAGE_TAG) || true

## docker-run: Run a docker container from the image with the tag
##             <PROJECT_NAME>: <DOCKER_IMAGE_TAG>, if DOCKER_IMAGE_TAG is not
##             defined it will be the git revision, plus ".dirty" suffix if the
##             repository contains uncommitted files. The container will be
##             automatically removed once stopped.
.PHONY: docker-run
docker-run: | docker-generate-tag docker-build
	@docker run -it --rm $(PROJECT_NAME):$(DOCKER_IMAGE_TAG)

docker-generate-tag:
	@$(eval __GIT_UNCOMMITTED_FILES := $(shell git status -s))
	@$(eval DOCKER_IMAGE_TAG := $(shell git rev-parse --short HEAD 2> /dev/null))

	@if [ ! -z "$(__GIT_UNCOMMITTED_FILES)" ]; then \
		echo "The repo has uncommitted files"; \
		$(eval DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG).dirty) \
	fi;
	@echo "Image tag: "$(DOCKER_IMAGE_TAG)

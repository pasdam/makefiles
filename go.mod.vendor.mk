# This makefile contains helper targets for go projects that are using go
# modules (with vendoring).
# If you use this file, you probably should also include go.mk.
# It expects the PROJECT_NAME variable to be defined, as it will be used as
# name for the artifact.

GO_MAIN_DIR ?= .

## go-build: Build the app
.PHONY: go-build
go-build: | go-dep-clean go-dep-download
	@go build -mod=vendor -v -o $(BUILD_DIR)/$(PROJECT_NAME) ${GO_MAIN_DIR}

## go-dep-download: Download all the dependencies
.PHONY: go-dep-download
go-dep-download: | go-dep-clean
	@go mod vendor

## go-dep-clean: Remove unused dependencies
.PHONY: go-dep-clean
go-dep-clean:
	@go mod tidy

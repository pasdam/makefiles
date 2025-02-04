# This makefile contains helper targets for go projects that are using go
# modules (without vendoring).
# If you use this file, you probably should also include go.mk.
# It expects the PROJECT_NAME variable to be defined, as it will be used as
# name for the artifact.

GO_MAIN_DIR ?= .
GO_MOD_DIR ?= .
PROJECT_NAME ?= $(shell basename $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

## go-build: Build the go app
.PHONY: go-build
go-build: | go-dep-clean go-dep-download
	@go build -v -o $(BUILD_DIR)/$(PROJECT_NAME) $(GO_MAIN_DIR)

## go-dep-clean: Remove unused go dependencies
.PHONY: go-dep-clean
go-dep-clean:
	@go mod tidy

## go-dep-download: Download all go dependencies
.PHONY: go-dep-download
go-dep-download: | go-dep-clean
	@go mod download

## go-dep-upgrade: Upgrade all go dependencies
.PHONY: go-dep-upgrade
go-dep-upgrade:
	@go get -C $(GO_MOD_DIR) -u ./...
	@go mod -C $(GO_MOD_DIR) tidy

## go-test: Run unit tests
.PHONY: go-test
go-test:
	@cd ${GO_MOD_DIR} && go test -gcflags=-l ./...

# This makefile contains helper targets for go projects.
# It expect the main.go file to be in the same directory as the main makefile.
# It also expects the PROJECT_NAME variable to be defined, as it will be used as
# name for the artifact.

BUILD_DIR ?= .build
COVERAGE_OUTPUT_DIR ?= $(BUILD_DIR)/coverage
GO_MAIN_DIR ?= .
PROJECT_NAME ?= $(shell basename $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

## go-clean: Remove go build files
.PHONY: go-clean
go-clean:
	@rm -f $(BUILD_DIR)/$(PROJECT_NAME)
	@rm -f $(COVERAGE_OUTPUT_DIR)

## go-coverage: Generate global code coverage report
.PHONY: go-coverage
go-coverage: $(COVERAGE_OUTPUT_DIR) | __go-pkg-list
	@echo "Go - Checking coverage for the following packages: ${GO_PKG_LIST}"
	@go test -gcflags=-l -v ${GO_PKG_LIST} -coverprofile $(COVERAGE_OUTPUT_DIR)/pls_cp.out
	@go tool cover -html=$(COVERAGE_OUTPUT_DIR)/pls_cp.out -o $(COVERAGE_OUTPUT_DIR)/coverage.html
	@go tool cover -func=$(COVERAGE_OUTPUT_DIR)/pls_cp.out
	@echo "You can find coverage report at $(COVERAGE_OUTPUT_DIR)/coverage.html"

## go-check: Run linter, perform unit tests, and verify the coverage
.PHONY: go-check
go-check: | __go-pkg-list go-lint go-coverage
	@go test -gcflags=-l -v -race -short ${GO_PKG_LIST}
	@go test -gcflags=-l -v -msan -short ${GO_PKG_LIST}

## go-install: Install the artifact
.PHONY: go-install
go-install:
	@go install ${GO_MAIN_DIR}

## go-lint: Lint the files
.PHONY: go-lint
go-lint: | __go-pkg-list
	@golint -set_exit_status ${GO_PKG_LIST}

## go-run: Run the app locally
.PHONY: go-run
go-run:
	@go run ${GO_MAIN_DIR}

__go-pkg-list:
ifeq ($(origin GO_PKG_LIST), undefined)
	$(eval GO_PKG_LIST ?= $(shell go list ./... | grep -v /vendor/))
endif

$(COVERAGE_OUTPUT_DIR):
	@mkdir -p $@

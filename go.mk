# This makefile contains helper targets for go projects.
# It expect the main.go file to be in the same directory as the main makefile.
# It also expects the PROJECT_NAME variable to be defined, as it will be used as
# name for the artifact.

## go-clean: Remove go build files
.PHONY: go-clean
go-clean:
	@rm -f $(BUILD_DIR)/$(PROJECT_NAME)

## go-coverage: Generate global code coverage report
.PHONY: go-coverage
go-coverage: | __go-pkg-list
	@go test -v ${GO_PKG_LIST} -coverprofile /tmp/pls_cp.out || true
	@go tool cover -html=/tmp/pls_cp.out -o /tmp/coverage.html
	@echo "You can find coverage report at /tmp/coverage.html"

## go-check: Run linter, perform unit tests, and verify the coverage
.PHONY: go-check
go-check: | __go-pkg-list go-lint go-coverage
	@go test -v -race -short ${GO_PKG_LIST}
	@go test -v -msan -short ${GO_PKG_LIST}

## go-lint: Lint the files
.PHONY: go-lint
go-lint: | __go-pkg-list
	@golint -set_exit_status ${GO_PKG_LIST}

## go-run: Run the app locally
.PHONY: go-run
go-run:
	@go run .

## go-test: Run unit tests
.PHONY: go-test
go-test: | __go-pkg-list
	@go test ${GO_PKG_LIST}

__go-pkg-list:
ifeq ($(origin GO_PKG_LIST), undefined)
	$(eval GO_PKG_LIST ?= $(shell go list ./... | grep -v /vendor/))
endif

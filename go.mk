# This makefile contains helper targets for go projects.
# It expect the main.go file to be in the same directory as the main makefile.

GO_PKG_LIST := $(shell go list ./... | grep -v /vendor/)

## go-build: Build the binary file
.PHONY: go-build
go-build:
	@go build -v -o $(BUILD_DIR)/$(PROJECT_NAME) .

## go-clean: Remove go build files
.PHONY: go-clean
go-clean:
	@rm -f $(BUILD_DIR)/$(PROJECT_NAME)

## go-coverage: Generate global code coverage report
.PHONY: go-coverage
go-coverage:
	@go test -v ${GO_PKG_LIST} -coverprofile /tmp/pls_cp.out
	@go tool cover -html=/tmp/pls_cp.out -o /tmp/coverage.html
	@echo "You can find coverage report at /tmp/coverage.html"

## go-inspect: Run data race detector
.PHONY: go-inspect
go-inspect: | lint test coverage
	@go test -v -race -short ${GO_PKG_LIST}
	@go test -v -msan -short ${GO_PKG_LIST}

## go-lint: Lint the files
.PHONY: go-lint
go-lint:
	@golint -set_exit_status ${GO_PKG_LIST}

## go-run: Run the app locally
.PHONY: go-run
go-run:
	@go run .

## go-test: Run unit tests
.PHONY: go-test
go-test:
	@go test ${GO_PKG_LIST}

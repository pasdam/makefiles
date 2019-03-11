# This makefile contains helper targets for go projects that are using go
# modules (without vendoring).
# If you use this file, you probably should also include go.mk.

## go-build: Build the app
.PHONY: go-build
go-build: | go-dep-clean go-dep-download
	@go build -v -o $(BUILD_DIR)/$(PROJECT_NAME) .

## go-dep-download: Download all the dependencies
.PHONY: go-dep-download
go-dep-download: | go-dep-clean
	@go mod download

## go-dep-clean: Remove unused dependencies
.PHONY: go-dep-clean
go-dep-clean:
	@go mod tidy

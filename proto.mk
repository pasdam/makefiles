# This contains build targets for proto files.
# It requires the following to be declared:
#	- PROTO_ROOT: root folder containing the proto packages
#	- PROTO_PATH: path of the service proto
#	- API_CONF_PATH: path of the API configuration yaml to use to generate the reverse proxy
#
# Optional variables:
#	- PROTO_GO_OUT_DIR: output folder where generate the stubs and the reverse proxy for Go

PROTO_GO_OUT_DIR ?= pkg/gen
PROTOC_PARAMS ?=

## proto-clean: Remove all artifacts generated from proto
.PHONY: proto-clean
proto-clean: 
	@rm -rf $(PROTO_GO_OUT_DIR)/*

## proto-generate-gateway: Generates a reverse proxy for the GRPC service
.PHONY: proto-generate-gateway
proto-generate-gateway:
	@protoc $(PROTOC_PARAMS) -I$(PROTO_ROOT) --grpc-gateway_out=logtostderr=true,grpc_api_configuration=$(API_CONF_PATH):$(PROTO_GO_OUT_DIR) $(PROTO_PATH)

## proto-generate-go-stub: Generates the (Go) server stubs from the proto
.PHONY: proto-generate-go-stub
proto-generate-go-stub:
	@protoc $(PROTOC_PARAMS) -I$(PROTO_ROOT) --go_out=plugins=grpc:$(PROTO_GO_OUT_DIR) $(PROTO_PATH)

## proto-install-dep: Install the Go packages required to use the proto
.PHONY: proto-install-dep
proto-install-dep:
	@go get google.golang.org/grpc
	@go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
	@go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
	@go get -u github.com/golang/protobuf/protoc-gen-go

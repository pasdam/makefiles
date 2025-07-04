COMPOSE_BUILD_DIR ?= .build/compose
COMPOSE_DOWN_ARGS ?=
COMPOSE_FILES ?= compose.yaml
COMPOSE_LAST_MODIFIED_TAGS_YAML ?= compose.last-modified-tags.yaml
COMPOSE_LAST_MODIFIED_TAGS_PREREQUISITES ?=
COMPOSE_UP_ARGS ?= -d
COMPOSE_UP_PREREQUISITES ?=
COMPOSE_BUILD_PREREQUISITES ?= $(COMPOSE_UP_PREREQUISITES)
COMPOSE_FILES_WITH_VOLUMES :? $(COMPOSE_FILES)
COMPOSE_VOLUME_FILES ?= $(shell cat $(COMPOSE_FILES_WITH_VOLUMES) | grep -E '^\s+\- \./.*:ro$$' | sed -E 's| *\- \./||' | sed 's|:.*||' | sort | uniq | tr '\n' ' ')

COMPOSE_FILES_ARGS := $(shell echo " $(COMPOSE_FILES)" | sed 's| | -f |g')
COMPOSE_FILES_ARGS_DOWN := $(addprefix -f , $(shell echo " $(COMPOSE_FILES)" | (xargs ls -d 2>/dev/null)))

## compose-build: Build the docker images used in the compose files
.PHONY: compose-build
compose-build: $(COMPOSE_BUILD_PREREQUISITES)
	@docker compose $(COMPOSE_FILES_ARGS) build

## compose-clean: Clean generated compose files
.PHONY: compose-clean
compose-clean: compose-down
	@rm -f $(COMPOSE_LAST_MODIFIED_TAGS_YAML)

## compose-down: Stop the docker compose environment
.PHONY: compose-down
compose-down:
	@docker compose $(COMPOSE_FILES_ARGS_DOWN) down $(COMPOSE_DOWN_ARGS)
	@rm -f $(COMPOSE_BUILD_DIR)/compose-up.mk.target

## compose-generate-config-tags: Generate a compose file with tags for each
##                               service, with the timestamp of the last
##                               modified read-only volume, to force the
##                               container re-creation
.PHONY: compose-generate-config-tags
compose-generate-config-tags: $(COMPOSE_LAST_MODIFIED_TAGS_YAML)

## compose-up: Start the docker compose environment
compose-up: $(COMPOSE_BUILD_DIR)/compose-up.mk.target

# Internal targets
# ================

$(COMPOSE_LAST_MODIFIED_TAGS_YAML): $(COMPOSE_FILES) $(COMPOSE_VOLUME_FILES) $(COMPOSE_LAST_MODIFIED_TAGS_PREREQUISITES)
	@1>&2 echo "Generating $@ because $? have changed"
	@set -e; \
		merged_compose=$$(yq eval-all '. as $$item ireduce ({}; . * $$item )' $(COMPOSE_FILES)); \
		services=$$(printf '%s' "$$merged_compose" | yq '.services | keys | .[]'); \
		for service in $$services; do \
			volumes=$$(printf '%s' "$$merged_compose" | yq -r ".services.$${service}.volumes[]"); \
			if [ "$$volumes" = '' ]; then continue; fi; \
			lastModificationSeconds=0; \
			while IFS= read -r volume; do \
				case $$volume in ./*:ro) \
					volume=$$(echo $$volume | sed 's|:.*||'); \
					if [ ! -e "$$volume" ]; then echo "[WARNING] File $$volume does not exist"; continue; fi; \
					volumeModificationSeconds=$$(date -r $$volume +%s); \
					lastModificationSeconds=$$(( volumeModificationSeconds > lastModificationSeconds ? volumeModificationSeconds : lastModificationSeconds )); \
				esac; \
			done <<< "$$volumes" ; \
			output=$$(printf '%s' "$$output" | yq ".services.$$service.labels.\"com.pasdam.volumes-last-modified-timestamp\" |= $$lastModificationSeconds"); \
		done; \
		printf '%s' "$$output" > $@

$(COMPOSE_BUILD_DIR)/compose-up.mk.target: $(COMPOSE_BUILD_DIR) $(COMPOSE_LAST_MODIFIED_TAGS_YAML) $(COMPOSE_VOLUME_FILES) $(COMPOSE_UP_PREREQUISITES)
	@1>&2 echo "Compose - Running compose up because $? changed"
	@docker compose $(COMPOSE_FILES_ARGS) -f $(COMPOSE_LAST_MODIFIED_TAGS_YAML) up $(COMPOSE_UP_ARGS)
	@touch $@

$(COMPOSE_BUILD_DIR):
	@mkdir -p $@

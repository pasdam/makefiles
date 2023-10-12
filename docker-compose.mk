COMPOSE_TAGS_LOCAL_YAML ?= compose.local.yaml
COMPOSE_FILES_ARGS ?= -f compose.yaml
COMPOSE_LOCAL_MK ?= compose.local.mk
COMPOSE_UP_ARGS ?= -d

COMPOSE_FILES := $(shell echo $(COMPOSE_FILES_ARGS) | sed 's|-f ||g')

## compose-down: Stop the docker compose environment
.PHONY: compose-down
compose-down:
	@docker compose $(COMPOSE_FILES_ARGS) down

## compose-generate-config-tags: Generate a compose file with tags for each
##                               service, with the timestamp of the last
##                               modified read-only volume, to force the
##                               container re-creation
.PHONY: compose-generate-config-tags
compose-generate-config-tags:
	@1>&2 echo "Generating docker-compose with last modified tags"
	@set -e; \
		merged_compose=$$(yq eval-all '. as $$item ireduce ({}; . * $$item )' $(COMPOSE_FILES)); \
		services=$$(printf "%s" "$$merged_compose" | yq '.services | keys | .[]'); \
		for service in $$services; do \
			volumes=$$(printf "%s" "$$merged_compose" | yq -r ".services.$${service}.volumes[]"); \
			if [ "$$volumes" = "" ]; then continue; fi; \
			lastModificationSeconds=0; \
			while IFS= read -r volume; do \
				case $$volume in ./*:ro) \
					volume=$$(echo $$volume | sed "s|:.*||"); \
					if [ ! -e "$$volume" ]; then echo "[WARNING] File $$volume does not exist"; continue; fi; \
					volumeModificationSeconds=$$(date -r $$volume +%s); \
					lastModificationSeconds=$$(( volumeModificationSeconds > lastModificationSeconds ? volumeModificationSeconds : lastModificationSeconds )); \
				esac; \
			done <<< "$$volumes" ; \
			output=$$(printf "%s" "$$output" | yq '.services.'"$$service"'.labels."com.pasdam.volumes-last-modified-timestamp" |= '$$lastModificationSeconds''); \
		done; \
		printf "%s" "$$output" > $(COMPOSE_TAGS_LOCAL_YAML)

## compose-generate-config-tags-target: Generate a makefile with a target to
##                                      calculate the last-modified-timestamp
##                                      tag for each container
.PHONY: compose-generate-config-tags-target
compose-generate-config-tags-target: $(COMPOSE_LOCAL_MK)

## compose-up: Start the docker compose environment
.PHONY: compose-up
compose-up: ${COMPOSE_TAGS_LOCAL_YAML}
	@docker compose $(COMPOSE_FILES_ARGS) -f $(COMPOSE_TAGS_LOCAL_YAML) up $(COMPOSE_UP_ARGS)

# Internal targets
# ================

# Generate the makefile with the target to calculate the last-modified-timestamp
# tag for each container
$(COMPOSE_LOCAL_MK): $(COMPOSE_FILES)
	@1>&2 echo "Generating the target to update the last-modified-timestamp tags for the compose services"
	@deps=$$(cat $(COMPOSE_FILES) | grep -E '\- \./.*:ro$$' | sed -E 's| *\- \./||' | sed 's|:.*||' | sort | uniq | tr '\n' ' ') && \
		printf '$(COMPOSE_TAGS_LOCAL_YAML): %s\n	@$$(MAKE) compose-generate-config-tags\n' "$$deps" > $(COMPOSE_LOCAL_MK)

COMPOSE_FILES ?= compose.yaml
COMPOSE_LAST_MODIFIED_TAGS_YAML ?= compose.last-modified-tags.yaml
COMPOSE_UP_ARGS ?= -d
COMPOSE_UP_PREREQUISITES ?=
COMPOSE_VOLUME_FILES ?= $(shell cat $(COMPOSE_FILES) | grep -E '\- \./.*:ro$$' | sed -E 's| *\- \./||' | sed 's|:.*||' | sort | uniq | tr '\n' ' ')

COMPOSE_FILES_ARGS := $(shell echo " $(COMPOSE_FILES)" | sed 's| | -f |g')

## compose-down: Stop the docker compose environment
.PHONY: compose-down
compose-down:
	@docker compose $(COMPOSE_FILES_ARGS) down

## compose-generate-config-tags: Generate a compose file with tags for each
##                               service, with the timestamp of the last
##                               modified read-only volume, to force the
##                               container re-creation
.PHONY: compose-generate-config-tags
compose-generate-config-tags: $(COMPOSE_LAST_MODIFIED_TAGS_YAML)

## compose-up: Start the docker compose environment
.PHONY: compose-up
compose-up: $(COMPOSE_LAST_MODIFIED_TAGS_YAML) $(COMPOSE_VOLUME_FILES) $(COMPOSE_UP_PREREQUISITES)
	@docker compose $(COMPOSE_FILES_ARGS) -f $(COMPOSE_LAST_MODIFIED_TAGS_YAML) up $(COMPOSE_UP_ARGS)

# Internal targets
# ================

$(COMPOSE_LAST_MODIFIED_TAGS_YAML): $(COMPOSE_VOLUME_FILES)
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

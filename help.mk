# Include this makefile to automatically add an help target.
# To document a target use the following syntax (without quotes):
# "## <command>: <description>"
#
# It also supports multiline description:
# "## <command>: <description: first line>"
# "              <description: second line>"

## help: Display this help screen
# TODO: write the target in a more elegant way
.PHONY: help
help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | awk '\
		BEGIN { FS = "(:|^) +"}; \
		/^[a-zA-Z0-9\-]+: .*/ { printf "\033[36m%-30s\033[0m%s\n", $$1, $$2; next }; \
		/^ +.*/ { printf "\033[36m%-30s\033[0m", ""; printf $$2; for (i=3; i<=NF; i++) { printf ":%s", $$i }; printf "\n" } \
		'

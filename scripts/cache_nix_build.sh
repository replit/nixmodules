#!/usr/bin/env bash
# Builds and uploads a nix package and its run-time and build-time dependencies to our Nix cahce.

set -eo pipefail

nix build $@

nix-store -qR --include-outputs $(nix-store -qd $(nix path-info $@)) \
	| grep -v '\.drv$' \
	| xargs nix copy --to https://nix-build-cache.replit.com?secret-key=./nix_build_cache_signing_key



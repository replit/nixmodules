#! /usr/bin/env bash
set -exuo pipefail

nix fmt -- --check .

git grep writeShellScriptBin | grep -v "Please use writeShellApplication" && \
    (echo "Please use writeShellApplication instead of writeShellScriptBin" && \
         exit 1) || true

NIX_FLAGS=(
    --extra-experimental-features nix-command
    --extra-experimental-features flakes
)

echo "Evaluate modules derivations"
nix eval "${NIX_FLAGS[@]}" --file scripts/module-registry-test.nix
nix eval "${NIX_FLAGS[@]}" .#modules --json
nix eval "${NIX_FLAGS[@]}" .#deploymentModules --json
nix build "${NIX_FLAGS[@]}" .#checks.x86_64-linux.module-registry --no-link
nix build "${NIX_FLAGS[@]}" .#checks.x86_64-linux.pip-user-site --no-link
nix build "${NIX_FLAGS[@]}" .#checks.x86_64-linux.pnpm-nodejs --no-link

# The standalone lockfile OCI helper reconstructs old bundles, not current implementations.
if git grep -n -E 'builtins[.]getFlake|(^|[^[:alnum:]_])getFlake[[:space:]]|github:replit/nixmodules/' -- '*.nix' ':!pkgs/mk-phony-ocis/default.nix'; then
    echo "Module implementations must be defined in-tree, not imported from old nixmodules flakes"
    exit 1
fi

nix develop "${NIX_FLAGS[@]}" --command echo Hello, world

nix eval .#bundle

nix build .#bundle-oci-check --no-link

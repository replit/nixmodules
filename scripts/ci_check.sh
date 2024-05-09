#! /usr/bin/env bash
set -exuo pipefail

nix fmt -- --check .

git grep writeShellScriptBin | grep -v "Please use writeShellApplication" && \
    (echo "Please use writeShellApplication instead of writeShellScriptBin" && \
         exit 1) || true

NIX_FLAGS="--extra-experimental-features nix-command --extra-experimental-features flakes --extra-experimental-features discard-references"

echo "Evaluate modules derivations"
nix eval $NIX_FLAGS .#modules --json

nix develop $NIX_FLAGS

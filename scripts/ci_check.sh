#! /usr/bin/env bash
set -exuo pipefail

nix fmt -- --check .

NIX_FLAGS="--extra-experimental-features nix-command --extra-experimental-features flakes --extra-experimental-features discard-references"

echo "Evaluate modules derivations"
nix eval $NIX_FLAGS .#modules --json

echo "Build upgrade maps"
nix build $NIX_FLAGS .#upgrade-maps
cat result/auto-upgrade.json
cat result/recommend-upgrade.json

echo "Build active modules"
nix build $NIX_FLAGS .#active-modules
cat result
nix develop $NIX_FLAGS

echo "Verify modules.json"
python scripts/lock_modules.py -v
python scripts/check_modules.py

echo "Verify upgrade maps"
python scripts/check_upgrade_maps.py

echo "Build new/updated modules"
python scripts/build_changed_modules.py origin/main

echo "Build moduleit example"
cd pkgs/moduleit
./moduleit.sh example.nix

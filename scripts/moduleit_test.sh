#! /usr/bin/env bash

nixpkgs_rev=$(nix run --inputs-from . nixpkgs#jq -- -r '.nodes.nixpkgs.locked.rev' flake.lock)
cd /tmp
wget "https://github.com/nixos/nixpkgs/archive/${nixpkgs_rev}.tar.gz" -q
tar xzf "${nixpkgs_rev}.tar.gz"
export NIX_PATH="nixpkgs=$PWD/nixpkgs-${nixpkgs_rev}"
cd -
cd pkgs/moduleit
./moduleit.sh example.nix
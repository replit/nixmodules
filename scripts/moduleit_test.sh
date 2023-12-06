#! /usr/bin/env bash

nixpkgs_rev=$(nix run --inputs-from . nixpkgs#jq -- -r '.nodes."nixpkgs-unstable".locked.rev' flake.lock)
cd /tmp
curl "https://github.com/nixos/nixpkgs/archive/${nixpkgs_rev}.tar.gz" -L -o nixpkgs.tar.gz
tar xzf "nixpkgs.tar.gz"
export NIX_PATH="nixpkgs-unstable=$PWD/nixpkgs-${nixpkgs_rev}"
cd -
cd pkgs/moduleit
./moduleit.sh example.nix
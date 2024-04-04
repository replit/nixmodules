#! /usr/bin/env bash
set -exuo pipefail

nix fmt -- --check .


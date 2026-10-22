{ lib, writeShellApplication, coreutils, bash, writeText }:
{ name, runtimeInputs, env, builder }:
let
  attributes = writeText "${name}-attributes" ''
    declare -A env=(
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "[${lib.escapeShellArg key}]=${lib.escapeShellArg (toString value)}") env)}
    )
    declare -A outputs=([out]="$IMAGE_WORK/output")
  '';
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ coreutils bash ] ++ runtimeInputs;
  text = ''
    if [ "$#" -ne 1 ]; then
      echo "usage: ${name} <new-output-directory>" >&2
      exit 2
    fi
    destination=$(realpath -m -- "$1")
    case "$destination" in
      /nix/store|/nix/store/*)
        echo "Image output must be outside /nix/store" >&2
        exit 2
        ;;
    esac
    mkdir -- "$destination"
    work=""
    complete=false
    cleanup() {
      if [ -n "$work" ]; then
        chmod -R u+w -- "$work"
        rm -rf -- "$work"
      fi
      if [ "$complete" = false ]; then rm -rf -- "$destination"; fi
    }
    trap cleanup EXIT
    work=$(mktemp -d "''${destination}.work.XXXXXX")
    export IMAGE_WORK="$work"
    cp ${attributes} "$work/.attrs.sh"
    (
      cd "$work"
      ${bash}/bin/bash -euo pipefail ${builder}
    ) >&2
    cp -a --reflink=auto "$work/output/." "$destination/"
    complete=true
    printf '%s\n' "$destination"
  '';
}

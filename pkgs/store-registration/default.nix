{ closureInfo
, coreutils
, runCommand
}:
{ rootPaths }:

let
  closure = closureInfo { inherit rootPaths; };
in
runCommand "nixmodules-store-registration-v1"
{
  nativeBuildInputs = [ coreutils ];
} ''
  mkdir -p "$out"
  printf '1\n' > "$out/format-version"
  cp ${closure}/registration "$out/registration"
  LC_ALL=C sort -u ${closure}/store-paths > "$out/store-paths"
  cd "$out"
  sha256sum format-version registration store-paths > SHA256SUMS
''

{runCommand, lib, revstring, bundle-image, pigz }:

let
  label = "nixmodules-${revstring}";
in

runCommand label {} ''
  echo "making tarball..."
  mkdir -p $out
  tar --use-compress-program=${pigz}/bin/pigz -Scf $out/disk.raw.tar.gz ${bundle-image}/disk.raw
''

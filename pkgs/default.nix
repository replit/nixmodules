{ pkgs, nixpkgs, self }:
let
  mkModule = path: pkgs.callPackage ./moduleit/entrypoint.nix {
    configPath = path;
  };
  revstring = builtins.substring 0 7 self.rev or "dirty";
in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  rust = mkModule ./rust;
  go = mkModule ./go;
  swift = mkModule ./swift;

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" [
    { name = go.name; path = go; }
    { name = rust.name; path = rust; }
    { name = swift.name; path = swift; }
  ];

  rev = pkgs.writeText "rev" revstring;

  bundle-image-closure-info = pkgs.buildPackages.closureInfo { rootPaths = [bundle]; };

  bundle-image = pkgs.runCommand "nixmodules-${revstring}.tar.gz" {} ''
    tar --sort=name --mtime='@1' --owner=0 --group=0 --numeric-owner -czvf $out -T ${bundle-image-closure-info}/store-paths
  '';
}

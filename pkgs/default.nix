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

  bundle-image = pkgs.callPackage "${nixpkgs}/nixos/lib/make-ext4-fs.nix" ({
    storePaths = [ bundle ];
    volumeLabel = "nixmodules";
  });
}

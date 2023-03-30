{ pkgs, self }:
let
  mkModule = path: pkgs.callPackage ./moduleit/entrypoint.nix {
    configPath = path;
  };
in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  rust = mkModule ./rust;
  go = mkModule ./go;
  swift = mkModule ./swift;

  bundle = pkgs.linkFarm "nixmodules-bundle-${builtins.substring 0 7 self.rev or "dirty"}" [
    { name = go.name; path = go; }
    { name = rust.name; path = rust; }
    { name = swift.name; path = swift; }
  ];
}

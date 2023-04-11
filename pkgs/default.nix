{ pkgs, nixpkgs, nixmodules-stable, self }:

with pkgs.lib;

let
  mkModule = path: pkgs.callPackage ./moduleit/entrypoint.nix {
    configPath = path;
  };
  revstring = builtins.substring 0 7 self.rev or "dirty";

  modules = rec {
    go = go_1;
    go_1 = mkModule ./go;

    rust = rust_1;
    rust_1 = mkModule ./rust;

    swift = swift_1;
    swift_1 = mkModule ./swift;
  };

  modulesList = (mapAttrsToList (name: value: { inherit name; path = value;}) modules);

in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" modulesList;

  bundle-stable = nixmodules-stable.packages.${pkgs.system}.bundle;

  registry = pkgs.writeTextFile { name = "registry.json"; text = builtins.toJSON modules;};

  registry-stable = nixmodules-stable.packages.${pkgs.system}.registry;

  rev = pkgs.writeText "rev" revstring;

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle registry bundle-stable registry-stable revstring; };
}

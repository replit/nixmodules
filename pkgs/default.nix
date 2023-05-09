{ pkgs, nixpkgs, nixmodules-stable, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value;}) modules
  );

  bundle-stable = nixmodules-stable.packages.${pkgs.system}.bundle;

  registry = pkgs.writeTextFile { name = "registry.json"; text = builtins.toJSON modules;};

  registry-stable = nixmodules-stable.packages.${pkgs.system}.registry;

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-image = pkgs.callPackage ./bundle-image { inherit bundle registry bundle-stable registry-stable revstring; };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };
}

{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  registry = ../modules.json;
in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  active-modules = import ./active-modules {
    inherit pkgs self registry;
  };

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  bundle-locked = pkgs.callPackage ./bundle-locked { inherit revstring; };

  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-squashfs = pkgs.callPackage ./bundle-squashfs {
    inherit bundle-locked revstring active-modules upgrade-maps registry;
  };

  # devsqsh = import ./devsqsh { inherit upgrade-maps pkgs self revstring; module = modules."python-3.10"; };

}
// modules
// (mapAttrs'
  (name: value:
    nameValuePair
    ("devsqsh-${name}")
    (import ./devsqsh { inherit pkgs self revstring; module-name = name; module = value; }))  modules)

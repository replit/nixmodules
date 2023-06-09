{ pkgs, self }:

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
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  active-modules = import ./active-modules {
    inherit pkgs;
    inherit self;
  };

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  bundle-locked = pkgs.callPackage ./bundle-locked { inherit revstring; };

  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-squashfs = pkgs.callPackage ./bundle-squashfs {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

} // modules

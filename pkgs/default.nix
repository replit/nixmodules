{ flake, pkgs }:

with pkgs.lib;

let
  inherit (flake) modules revstring revstring_long;
in

modules // rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  active-modules = pkgs.callPackage ./active-modules {
    inherit flake;
  };

  upgrade-maps = pkgs.callPackage ./upgrade-maps { };

  bundle-locked = pkgs.callPackage ./bundle-locked {
    inherit flake;
  };

  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked active-modules upgrade-maps flake;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball {
    inherit bundle-image flake;
  };

  bundle-squashfs = pkgs.callPackage ./bundle-squashfs {
    inherit bundle-locked active-modules upgrade-maps flake;
  };
}

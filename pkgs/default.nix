args @ {
  pkgs,
  current-modules,
  revstring,
  revstring_long,
  ...
}:

with pkgs.lib;

current-modules // rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  modules = current-modules;

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) current-modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  active-modules = import ./active-modules args;

  upgrade-maps = pkgs.callPackage ./upgrade-maps { };

  bundle-locked = import ./bundle-locked args;

  bundle-image = import ./bundle-image (args // {
    inherit bundle-locked active-modules upgrade-maps;
  });

  bundle-image-tarball = import ./bundle-image-tarball (args // {
    inherit bundle-image;
  });

  bundle-squashfs = import ./bundle-squashfs (args // {
    inherit bundle-locked active-modules upgrade-maps;
  });
}

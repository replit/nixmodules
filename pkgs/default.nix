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

  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-locked-fn = { moduleIds }: pkgs.callPackage ./bundle-locked {
    inherit moduleIds;
    inherit revstring;
  };

  bundle-locked = bundle-locked-fn {
    moduleIds = null;
  };

  bundle-squashfs-fn = { moduleIds }: pkgs.callPackage ./bundle-squashfs {
    bundle-locked = bundle-locked-fn {
      inherit moduleIds;
    };
    inherit active-modules upgrade-maps revstring;
  };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = null;
  };

  basic-bundle-locked = bundle-locked-fn {
    moduleIds = ["python-3.10" "nodejs-18"];
  };

  basic-bundle-squashfs = bundle-squashfs-fn {
    moduleIds = ["python-3.10" "nodejs-18"];
  };

} // modules

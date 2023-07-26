{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ./modules.json);
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
    inherit all-modules;
  };

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-locked-fn = { modulesLocks }: pkgs.callPackage ./bundle-locked {
    inherit modulesLocks;
    inherit revstring;
  };

  bundle-locked = bundle-locked-fn {
    moduleIds = null;
  };

  bundle-squashfs-fn = { moduleIds }:
    let
      modulesLocks = import ./filter-modules-locks {
        inherit pkgs;
        inherit moduleIds;
      };
    in
    pkgs.callPackage ./bundle-squashfs {
      bundle-locked = bundle-locked-fn {
        inherit modulesLocks;
      };
      active-modules = import ./active-modules {
        inherit pkgs;
        inherit self;
        all-modules = modulesLocks;
      };
      registry = modulesLocks;
      inherit upgrade-maps revstring;
    };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = null;
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" ];
  };

} // modules

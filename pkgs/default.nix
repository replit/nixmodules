{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ../modules.json);

  bundle-locked-fn = { modulesLocks }: pkgs.callPackage ./bundle-locked {
    inherit modulesLocks;
    inherit revstring;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs;
      inherit moduleIds;
    };
    inherit revstring;
  };

  bundle-squashfs-fn = { moduleIds ? null, upgrade-maps }:
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

  bundle-locked = bundle-locked-fn {
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs;
    };
  };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" ];
    inherit upgrade-maps;
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    # customize these IDs for dev. They can be like "python-3.10:v10-20230711-6807d41" or "python-3.10"
    # publish your feature branch first and make sure modules.json is current, then
    # in goval dir (next to nixmodules), run `make custom-nixmodules-disk` to use this disk in conman
    moduleIds = [ "python-3.10:v5-20230613-622effa" "python-3.10:v6-20230614-6eb09f7" "python-3.10" ];
    inherit upgrade-maps;
  };

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = [ "nodejs-18" ]; };

  bundle-phony-ocis = mkPhonyOCIs { };

} // modules

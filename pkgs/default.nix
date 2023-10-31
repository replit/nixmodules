{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ../modules.json);

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  bundle-locked-fn = { modulesLocks }: pkgs.callPackage ./bundle-locked {
    inherit modulesLocks;
    inherit revstring;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs upgrade-maps;
      inherit moduleIds;
    };
    inherit revstring;
  };

  bundle-squashfs-fn = { moduleIds ? null, upgrade-maps }:
    let
      modulesLocks = import ./filter-modules-locks {
        inherit pkgs upgrade-maps;
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
  inherit upgrade-maps;

  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  lkl = pkgs.callPackage ./lkl { };

  active-modules = import ./active-modules {
    inherit pkgs;
    inherit self;
    inherit all-modules;
  };


  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-locked = bundle-locked-fn {
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs upgrade-maps;
    };
  };

  all-historical-modules = mapAttrs
    (moduleId: module:
      let
        flake = builtins.getFlake "github:replit/nixmodules/${module.commit}";
        shortModuleId = elemAt (strings.splitString ":" moduleId) 0;
      in
      flake.modules.${shortModuleId})
    all-modules;

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" "docker" ];
    inherit upgrade-maps;
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    # customize these IDs for dev. They can be like "python-3.10:v10-20230711-6807d41" or "python-3.10"
    # publish your feature branch first and make sure modules.json is current, then
    # in goval dir (next to nixmodules), run `make custom-nixmodules-disk` to use this disk in conman
    # There is no need to check in changes to this.
    moduleIds = [ "python-3.10" "nodejs-18" ];
    inherit upgrade-maps;
  };

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = [ "nodejs-18" ]; };

  all-phony-oci-bundles = mapAttrs
    (moduleId: module:
      let
        flake = builtins.getFlake "github:replit/nixmodules/${module.commit}";
        shortModuleId = elemAt (strings.splitString ":" moduleId) 0;
      in
      mkPhonyOCI {
        inherit moduleId;
        module = flake.deploymentModules.${shortModuleId};
      })
    all-modules;

  bundle-phony-ocis = mkPhonyOCIs { };

  inherit all-modules;

  deploymentModules = self.deploymentModules;

} // modules

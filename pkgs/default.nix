{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI revstring;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs moduleIds;
    };
  };

  modulesMap = modules: mapAttrs (name: drv: {
      commit = revstring_long;
      path = drv.outPath;
    }) modules;

  modulesMapJSON = modules: pkgs.writeTextFile {
    name = "modules.json";
    text = builtins.toJSON (modulesMap modules);
  };

  bundle-fn = { moduleIds ? null }:
    let filteredModules = if moduleIds == null
      then modules else
      filterAttrs (moduleId: _: elem moduleId moduleIds) modules;
    in
      pkgs.linkFarm "nixmodules-bundle" ([
        {
          name = "etc/nixmodules/modules.json";
          path = modulesMapJSON filteredModules;
        }
        {
          name = "etc/nixmodules/registry.json";
          path = pkgs.callPackage ./registry {
            modulesMap = (modulesMap filteredModules);
            inherit self;
          };
        }
      ] ++ (mapAttrsToList (name: value: { inherit name; path = value; }) filteredModules));

  bundle-squashfs-fn = { moduleIds ? null, diskName ? "disk.raw" }:
    pkgs.callPackage ./bundle-image {
      bundle = bundle-fn moduleIds;
      inherit revstring diskName;
    };

  # customize these IDs for dev. In goval dir (next to nixmodules),
  # run `make custom-nixmodules-disk` to use this disk in conman
  # There is no need to check in changes to this.
  testModules = ["python-3.10" "nodejs-20"];

in
rec {
  inherit upgrade-maps;

  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = bundle-fn { };

  custom-bundle = bundle-fn {
    moduleIds = testModules;
  };

  test-registry = pkgs.callPackage ./registry {
    modulesMap = (modulesMap testModules);
    inherit self;
  };

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-image = bundle-squashfs-fn { };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" "nodejs-20" "docker" "replit" ];
    diskName = "disk.sqsh";
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    moduleIds = testModules;
    diskName = "disk.sqsh";
  };

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = testModules; };

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

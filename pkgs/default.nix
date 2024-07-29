{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;

  dev-module-ids = [ "python-3.10" "python-3.12" "nodejs-18" "nodejs-20" "docker" "replit" "replit-rtld-loader" ];

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  bundle-fn = pkgs.callPackage ./bundle { inherit self; };

  bundle-squashfs-fn = { moduleIds ? null, diskName ? "disk.raw" }:
    pkgs.callPackage ./bundle-image {
      bundle = bundle-fn { inherit moduleIds; };
      inherit revstring diskName;
    };

in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = bundle-fn { };

  custom-bundle = bundle-fn {
    moduleIds = dev-module-ids;
  };

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-image = bundle-squashfs-fn { };

  # For prod use: builds the Nixmodules disk image
  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  # For dev use: builds the shared Nixmodules disk
  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = dev-module-ids;
    diskName = "disk.sqsh";
  };

  # For dev use: with goval's `make custom-nixmodules-disk`
  custom-bundle-squashfs = bundle-squashfs-fn {
    moduleIds = dev-module-ids;
    diskName = "disk.sqsh";
  };

  phony-oci-bundles = mapAttrs
    (moduleId: _:
      mkPhonyOCI {
        inherit moduleId;
        module = self.deploymentModules.${moduleId};
      })
    modules;

  deploymentModules = self.deploymentModules;

} // modules

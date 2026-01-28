{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;

  dev-module-ids = [
    "python-3.10"
    "python-3.11"
    "nodejs-18"
    "nodejs-20"
    "nodejs-22"
    "go-1.21"
    "docker"
    "replit"
    "replit-rtld-loader"
    "ruby"
    "ruby-3.2"
    "postgresql-16"
  ];

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci {
    ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default;
  };

  bundle-fn = pkgs.callPackage ./bundle { inherit self; };

  bundle-squashfs-fn =
    { moduleIds ? null
    , diskName ? "disk.raw"
    ,
    }:
    pkgs.callPackage ./bundle-image {
      bundle = bundle-fn { inherit moduleIds; };
      inherit revstring diskName;
    };

  disk-script-fn =
    { moduleIds ? null
    ,
    }:
    pkgs.callPackage ./disk-script {
      bundle = bundle-fn { inherit moduleIds; };
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

  disk-script-dev = disk-script-fn {
    moduleIds = dev-module-ids;
  };

  disk-script = disk-script-fn { };

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
    (
      moduleId: _:
        mkPhonyOCI {
          inherit moduleId;
          module = self.deploymentModules.${moduleId};
        }
    )
    modules;

  deploymentModules = self.deploymentModules;

}
  // modules

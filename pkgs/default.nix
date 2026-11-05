{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;

  dev-module-ids = [
    "python-3.10"
    "python-3.11"
    "nodejs-20"
    "nodejs-22"
    "nodejs-24"
    "go-1.25"
    "docker"
    "replit"
    "replit-rtld-loader"
    "ruby-3.2"
    "postgresql-16"
  ];

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci {
    ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default;
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

  prefixedPackages = prefix: mapAttrs' (name: value: nameValuePair "${prefix}.${name}" value);

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

in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  nixmodules-mirror-inputs = pkgs.linkFarm "nixmodules-mirror-inputs-${revstring_long}" [
    {
      name = "development";
      path = bundle;
    }
    {
      name = "deployment";
      path = bundle-fn { deployment = true; };
    }
    {
      name = "module-registry";
      path = self.checks.x86_64-linux.module-registry;
    }
    {
      name = "flake-toolchain";
      path = self.checks.x86_64-linux.flake-toolchain;
    }
    {
      name = "pip-user-site";
      path = self.checks.x86_64-linux.pip-user-site;
    }
  ];

  nixmodules-mirror-publish = pkgs.callPackage ./nixmodules-mirror-publish.nix {
    mirrorInputs = nixmodules-mirror-inputs;
  };

  bundle = bundle-fn { };

  node-python-runtime-oci = pkgs.callPackage ./runtime-oci {
    inherit self;
  };

  custom-bundle = bundle-fn {
    moduleIds = dev-module-ids;
  };

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  bundle-image = bundle-squashfs-fn { };

  # For prod use: builds the Nixmodules disk image
  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  disk-script = pkgs.callPackage ./disk-script {
    inherit bundle;
  };

  disk-script-dev = pkgs.callPackage ./disk-script-dev {
    bundle = bundle-fn {
      moduleIds = dev-module-ids;
    };
  };

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

}
// modules
// mapAttrs' (id: module: nameValuePair "shell.${id}" module.shellPackage) self.modules
// mapAttrs' (id: module: nameValuePair "deployment-shell.${id}" module.shellPackage) self.deploymentModules
// prefixedPackages "deploymentModules" self.deploymentModules
  // prefixedPackages "phony-oci-bundles" phony-oci-bundles

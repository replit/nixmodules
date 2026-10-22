{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs-23_05.url = "github:nixos/nixpkgs/nixos-23.05";
  inputs.nixpkgs-24_11.url = "github:nixos/nixpkgs/nixos-24.11";
  inputs.nixpkgs-25_05.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.nixpkgs-master.url = "github:nixos/nixpkgs/master";
  inputs.nixpkgs-staging.url = "github:nixos/nixpkgs/staging-next";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-nodejs.url = "github:nixos/nixpkgs/5873d3da531a3a8320c9e639e2147eccbe7f2d0d";
  inputs.nixpkgs-node24.url = "github:nixos/nixpkgs/dc0146be65ada0333393ac87b6ff45a4a8e9b722";
  inputs.nixpkgs-php.url = "github:nixos/nixpkgs/8c259fc0dd1f3ccc1aaf4f9156ab16b7328b5a4f";
  inputs.nixpkgs-docker.url = "github:nixos/nixpkgs/fcb54ddcc974cff59bdfb7c1ac9e080299763d2d";
  inputs.nixpkgs-zig.url = "github:nixos/nixpkgs/ecb441f22067ba1d6312f4932a7c64efa8d19a7b";
  inputs.zig-overlay.url = "github:mitchellh/zig-overlay/ee376d4012e3c853123ca7083af852313235407c";
  inputs.zig-overlay.inputs.nixpkgs.follows = "nixpkgs-zig";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nil.url = "github:oxalica/nil";
  inputs.nil.inputs.nixpkgs.follows = "nixpkgs";
  inputs.prybar.url = "github:replit/prybar";
  inputs.prybar.inputs.nixpkgs.follows = "nixpkgs";
  inputs.java-language-server.url = "github:replit/java-language-server";
  inputs.java-language-server.inputs.nixpkgs.follows = "nixpkgs-23_05";
  inputs.ztoc-rs.url = "github:replit/ztoc-rs";
  inputs.ztoc-rs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.replit-rtld-loader.url = "github:replit/replit_rtld_loader";
  inputs.replit-rtld-loader.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixpkgs-23_05, nixpkgs-24_11, nixpkgs-25_05, nixpkgs-master, nixpkgs-staging, nixpkgs-nodejs, nixpkgs-node24, nixpkgs-php, nixpkgs-docker, nixpkgs-zig, zig-overlay, prybar, java-language-server, nil, fenix, replit-rtld-loader, ... }:
    let
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [
          self.overlays.default
          prybar.overlays.default
          java-language-server.overlays.default
          nil.overlays.default
          fenix.overlays.default
          replit-rtld-loader.overlays.default
        ];
        # replbox and databricks-cli have unfree licenses
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "@replit/replbox"
          "databricks-cli"
        ];
      };

      pkgs-23_05 = mkPkgs nixpkgs-23_05 "x86_64-linux";
      pkgs-24_11 = mkPkgs nixpkgs-24_11 "x86_64-linux";
      pkgs-25_05 = mkPkgs nixpkgs-25_05 "x86_64-linux";
      # TODO: once nodejs update lands in unstable, switch to that
      pkgs-master = mkPkgs nixpkgs-master "x86_64-linux";
      pkgs-staging = mkPkgs nixpkgs-staging "x86_64-linux";
      pkgs-php = import nixpkgs-php { system = "x86_64-linux"; };
      pkgs-nodejs = import nixpkgs-nodejs { system = "x86_64-linux"; };
      pkgs-node24 = import nixpkgs-node24 { system = "x86_64-linux"; };
      # Keep the shipped toolchains pinned while moving their module definitions in-tree.
      pkgs-docker = import
        (nixpkgs-docker.legacyPackages.x86_64-linux.applyPatches {
          name = "nixpkgs-unstable-patched";
          src = nixpkgs-docker;
          patches = [ ];
        })
        { system = "x86_64-linux"; };
      pkgs-zig = import nixpkgs-zig {
        system = "x86_64-linux";
        overlays = [ zig-overlay.overlays.default ];
      };
      nodejs-22 = pkgs-nodejs.nodejs_22;
      nodejs-24 = pkgs-node24.nodejs_24;
      deno-src = pkgs-nodejs.fetchFromGitHub {
        owner = "denoland";
        repo = "deno";
        tag = "v2.9.8";
        fetchSubmodules = true;
        hash = "sha256-piJetMgFpg8xzEveqRQEq4kJINaLRDOrHp7Nd0z8wok=";
      };
      deno-cargoDeps = pkgs-nodejs.rustPlatform.fetchCargoVendor {
        pname = "deno";
        version = "2.9.8";
        src = deno-src;
        hash = "sha256-LNYXzS0oespQMeT/1fGcOvaDy5ErVeY7jUPL19OgeZ4=";
      };
      deno = pkgs-nodejs.deno.overrideAttrs (_: {
        version = "2.9.8";
        src = deno-src;
        cargoDeps = deno-cargoDeps;
      });
      uv = pkgs-nodejs.uv;

      patched-unstable = nixpkgs.legacyPackages.x86_64-linux.applyPatches {
        name = "nixpkgs-unstable-patched";
        src = nixpkgs;
        patches = [
          # rexml broke solargraph at some point in the past.
          # Attempting to run:
          #   echo 'x = (5 + "hey")' > main.rb
          #   /nix/store/.../ruby /nix/store/.../bin/solargraph typecheck main.rb
          # curently emits a bunch of "Unrecognized RBS type:" warnings, followed by
          # "0 problems found."
          # This patch used to apply, but even when massaged to apply to the
          # current unstable HEAD, still produces the same result:
          # ./patches/rexml.patch
        ];
      };

      pkgs = mkPkgs patched-unstable "x86_64-linux";
      pkgs-aarch64-darwin = mkPkgs patched-unstable "aarch64-darwin";
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;

        lib = prev.lib // {
          mkWrapper-replit_ld_library_path = package: final.stdenvNoCC.mkDerivation {
            name = "${package.name}-wrapped";
            inherit (package) meta version;

            buildInputs = [ pkgs.makeWrapper ];
            buildCommand = ''
              if [ ! -d ${package}/bin ]; then
                echo "No bin directory found in ${package}"
                exit 1
              fi

              mkdir -p $out/bin

              for bin in ${package}/bin/*; do
                local binName=$(basename $bin)
                cat >$out/bin/$binName <<-EOF
              #!${final.bash}/bin/bash
              if [ -n "\''${REPLIT_LD_LIBRARY_PATH-}" ]; then
                if test "\''${REPLIT_RTLD_LOADER:-}" = "1" && test "\''${REPLIT_NIX_CHANNEL:-}" != "legacy"
                then
                  # activate RTLD loader!
                  export LD_AUDIT="${pkgs.replit-rtld-loader}/rtld_loader.so"
                else
                  export LD_LIBRARY_PATH="\$REPLIT_LD_LIBRARY_PATH:\$LD_LIBRARY_PATH"
                fi
              fi
              exec "$bin" "\$@"
              EOF
                chmod +x $out/bin/$binName
              done
            '';
          };
        };

      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      formatter.aarch64-darwin = pkgs-aarch64-darwin.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self;
      };
      checks.x86_64-linux.module-registry =
        assert import ./scripts/module-registry-test.nix;
        assert builtins.attrNames self.modules == builtins.attrNames self.deploymentModules;
        assert builtins.attrNames self.activeModules == builtins.attrNames self.activeDeploymentModules;
        assert builtins.all
          (id:
            builtins.hasAttr id self.modules
            && builtins.hasAttr id self.deploymentModules
            && !(builtins.hasAttr id self.activeModules)
            && !(builtins.hasAttr id self.activeDeploymentModules))
          [ "docker" "zig-0.11" ];
        pkgs.writeText "module-registry-check" "ok";
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          python310
          pigz
          coreutils
          findutils
          e2fsprogs
          gnutar
          gzip
        ];
      };
    } // (
      import ./pkgs/modules {
        inherit pkgs;
        inherit pkgs-23_05;
        inherit pkgs-24_11;
        inherit pkgs-25_05;
        inherit pkgs-master;
        inherit pkgs-staging;
        inherit deno uv;
        inherit nodejs-22 nodejs-24;
        inherit pkgs-php;
        inherit pkgs-docker pkgs-zig;
      }
    );
}

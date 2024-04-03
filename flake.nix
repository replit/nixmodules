{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/?rev=7c4c20509c4363195841faa6c911777a134acdf3";
  # inputs.fenix.url = "github:nix-community/fenix";
  # inputs.fenix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.nixd.url = "github:nix-community/nixd";
  # inputs.nixd.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.prybar.url = "github:replit/prybar";
  # inputs.prybar.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.java-language-server.url = "github:replit/java-language-server";
  # inputs.java-language-server.inputs.nixpkgs.follows = "nixpkgs-unstable";
  # inputs.ztoc-rs.url = "github:replit/ztoc-rs";
  # inputs.ztoc-rs.inputs.nixpkgs.follows = "nixpkgs-unstable";
  inputs.replit-rtld-loader.url = "github:replit/replit_rtld_loader";
  inputs.replit-rtld-loader.inputs.nixpkgs.follows = "nixpkgs-unstable";

  outputs = { self, nixpkgs-unstable, replit-rtld-loader, ... }:
    let
      nixpkgs = nixpkgs-unstable;
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [
          self.overlays.default
          # prybar.overlays.default
          # java-language-server.overlays.default
          # nixd.overlays.default
          # fenix.overlays.default
          replit-rtld-loader.overlays.default
        ];
        # replbox has an unfree license
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "@replit/replbox"
        ];
      };

      pkgs-23_05 = mkPkgs nixpkgs "x86_64-linux";

      pkgs = mkPkgs nixpkgs-unstable "x86_64-linux";
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
                export LD_LIBRARY_PATH="\$REPLIT_LD_LIBRARY_PATH:\$LD_LIBRARY_PATH"
              fi
              exec "$bin" "\$@"
              EOF
                chmod +x $out/bin/$binName
              done
            '';
          };

          mkModuleEnableOption =
            { name, description }: prev.lib.mkOption {
              default = false;
              example = true;
              description = "Whether to enable ${name}.";
              type = prev.lib.types.bool;
            } // {
              moduleName = name;
              moduleDescription = description;
            };

          mkBundleModule = (import ./pkgs/bundle-util).mkBundleModule;
        };
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self pkgs-23_05;
      };
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
      }
    );
}

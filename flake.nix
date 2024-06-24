{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nil.url = "github:oxalica/nil";
  inputs.nil.inputs.nixpkgs.follows = "nixpkgs";
  inputs.prybar.url = "github:replit/prybar";
  inputs.prybar.inputs.nixpkgs.follows = "nixpkgs";
  inputs.java-language-server.url = "github:replit/java-language-server";
  inputs.java-language-server.inputs.nixpkgs.follows = "nixpkgs";
  inputs.ztoc-rs.url = "github:replit/ztoc-rs";
  inputs.ztoc-rs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.replit-rtld-loader.url = "github:replit/replit_rtld_loader";
  inputs.replit-rtld-loader.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixpkgs-unstable, prybar, java-language-server, nil, fenix, replit-rtld-loader, ... }:
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
        # replbox has an unfree license
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "@replit/replbox"
        ];
      };

      pkgs-23_05 = mkPkgs nixpkgs "x86_64-linux";

      patched-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux.applyPatches {
        name = "nixpkgs-unstable-patched";
        src = nixpkgs-unstable;
        patches = [
          # rexml breaks this version of nixpkgs
          ./patches/rexml.patch
        ];
      };

      pkgs = mkPkgs patched-unstable "x86_64-linux";
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
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self;
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

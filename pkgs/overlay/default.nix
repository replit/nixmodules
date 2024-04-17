{ pkgs, self }:
final: prev: {
  moduleit = self.packages.${prev.system}.moduleit;

  python-versions = pkgs.callPackage ../python-versions { };

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
      { name, description }: prev.lib.mkOption
        {
          default = false;
          example = true;
          description = "Whether to enable ${name}.";
          type = prev.lib.types.bool;
        } // {
        moduleName = name;
        moduleDescription = description;
      };

    mkBundleModule = (import ../bundle-util).mkBundleModule;
  };
}
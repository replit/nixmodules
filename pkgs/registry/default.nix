{ self, pkgs, modulesMap }:
with pkgs.lib;
let
  modules = mapAttrs
    (
      module-id: moduleLockInfo:
        let
          module = self.modules.${module-id};
          module-info = (builtins.fromJSON (builtins.unsafeDiscardStringContext module.text));
          version = get-version-num tag;
        in
        {
          id = module-id;
          inherit (moduleLockInfo) commit path;
        } // module-info
    )
    modulesMap;
  registry = foldlAttrs
    (acc: moduleId: module:
      {
        languageServers = acc.languageServers ++
          mapAttrsToList
            (lsp-id: lsp: {
              id = lsp-id;
              inherit moduleId;
            } // lsp)
            module.languageServers;
        formatters = acc.formatters ++
          mapAttrsToList
            (formatter-id: formatter: {
              id = formatter-id;
              inherit moduleId;
            } // formatter)
            module.formatters;
        packagers = acc.packagers ++
          mapAttrsToList
            (packager-id: packager: {
              id = packager-id;
              inherit moduleId;
            } // packager)
            module.packagers;
        modules = acc.modules ++ [
          {
            inherit (module) id name description displayVersion commit path;
          }
        ];
      }
    )
    {
      languageServers = [ ];
      formatters = [ ];
      packagers = [ ];
      modules = [ ];
    }
    modules;
in
pkgs.stdenv.mkDerivation {
  pname = "registry";
  version = "1";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    echo '${builtins.toJSON registry}' > $out
  '';
  passthru = {
    # this allows you to query for this info without building it:
    # nix eval .#registry.info --json
    info = registry;
  };
}

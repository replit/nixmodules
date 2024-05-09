# Returns a derivation that creates a registry.json containing the available modules,
# languageServers, packagers, formatters and associated info.
{ pkgs, modules }:
with pkgs.lib;
let
  modulesInfo = mapAttrs
    (
      module-id: module:
        let
          module-info = (builtins.fromJSON (builtins.unsafeDiscardStringContext module.text));
          version = get-version-num tag;
        in
        {
          id = module-id;
          path = module.outPath;
        } // module-info
    )
    modules;
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
            inherit (module) id name description path;
            displayVersion = module.displayVersion or "";
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
    modulesInfo;
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

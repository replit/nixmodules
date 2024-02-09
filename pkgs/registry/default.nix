{ self, pkgs, modulesLocks }:
with pkgs.lib;
let
  mapping = import ../upgrade-maps/mapping.nix pkgs;
  isTerminal = mod: !((mapping.${mod} or false).auto or false);
  shortModuleId = (module-id:
    let
      parts = strings.splitString ":" module-id;
    in
    elemAt parts 0
  );
  versionTag = (module-id:
    let
      parts = strings.splitString ":" module-id;
    in
    elemAt parts 1
  );
  get-version-num = (tag:
    let
      tag-parts = strings.splitString "-" tag;
      version-str = elemAt tag-parts 0;
      version = toInt (substring 1 (stringLength version-str) version-str);
    in
    version
  );
  latestModulesLocks = filterAttrs (module-id: _: isTerminal module-id) modulesLocks;
  latestModules = mapAttrs
    (
      module-id: moduleLockInfo:
        let
          module = self.modules.${shortModuleId module-id};
          module-info = (builtins.fromJSON (builtins.unsafeDiscardStringContext module.text));
          parts = strings.splitString ":" module-id;
          short-id = elemAt parts 0;
          tag = elemAt parts 1;
          version = get-version-num tag;
        in
        {
          id = short-id;
          inherit version;
          inherit tag;
          inherit (moduleLockInfo) commit path;
        } // module-info
    )
    (filterAttrs (module-id: _: builtins.hasAttr (shortModuleId module-id) self.modules) latestModulesLocks);
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
            inherit (module) id name description displayVersion version tag commit path;
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
    latestModules;
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

# active-modules is a hydrated version of `nix eval .#modules --json` which contains for each module
# * name
# * description
# * tag
# * version
# * all historical tags
# meant to be used by the module registry UI

# to see for yourself, do:
# nix build .#active-modules
# cat result | jq

# or
# nix eval .#active-modules.meta.info --json | jq

{ flake, lib, stdenv }:
with lib;
let
  active-modules = flake.modules;
  get-version = (tag:
    let
      tag-parts = strings.splitString "-" tag;
      version-str = elemAt tag-parts 0;
      version = toInt (substring 1 (stringLength version-str) version-str);
    in
    version
  );
  all-modules-list = (attrsets.mapAttrsToList (name: value: { registry-id = name; commit = value.commit; path = value.path; }) flake.all-modules);
  active-modules-registry =
    foldr
      (
        entry: registry:
          let
            parts = strings.splitString ":" entry.registry-id;
            module-id = elemAt parts 0;
            tag = elemAt parts 1;
            version = get-version tag;
            module-info = (builtins.fromJSON (builtins.unsafeDiscardStringContext active-modules.${module-id}.text));
            new-entry = {
              inherit (entry) commit path;
              inherit version;
              inherit tag;
              inherit (module-info) name description;
            };
          in
          if ! builtins.hasAttr module-id active-modules then
            registry
          else
            if builtins.hasAttr module-id registry then
              let prev-entry = registry.${module-id};
              in
              if prev-entry.version > new-entry.version then
                registry // {
                  ${module-id} = prev-entry // {
                    tags = prev-entry.tags ++ [ tag ];
                  };
                }
              else
                registry // {
                  ${module-id} = new-entry // {
                    tags = prev-entry.tags ++ [ tag ];
                  };
                }
            else
              registry // {
                ${module-id} = new-entry // {
                  tags = [ tag ];
                };
              }
      )
      { }
      all-modules-list;
in
stdenv.mkDerivation {
  pname = "active-modules";
  version = "1";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    echo '${builtins.toJSON active-modules-registry}' > $out
  '';
  passthru = {
    # this allows you to query for this info wo building it:
    # nix eval .#active-modules.info --json
    info = active-modules-registry;
  };
}

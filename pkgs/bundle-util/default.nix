{
/*
This utility creates a module that implements a bundle, which has
these features:
1. the the bundle is enabled, it enables by default a list of child modules,
  aka the "content" of the bundle
2. exposes its content as a list of module ID strings via the `content`
  option

Example:

pkgs/bundles/nodejs/default.nix
```nix
{ pkgs, config, ... }:
pkgs.lib.mkBundleModule {
  id = "nodejs";
  name = "Node.js Tools Bundle";
  description = "Development tools for the Node.js JavaScript runtime";
  contents = [
    "interpreters.nodejs"
    "languageServers.typescript-language-server"
    "debuggers.node-dap"
    "formatters.prettier"
    "packagers.nodejs-packager"
  ];
  inherit pkgs config;
}
```
  */
  mkBundleModule = {id, name, description, contents, pkgs, config}:
    with pkgs.lib;
    let
      cfg = config.bundles.${id};
      generateBundleConfig = contents:
        (foldl' (acc: member:
          let
            elems = strings.splitString "." member;
            nestedEnabled = elems:
              if elems == []
              then
                { enable = mkDefault true; }
              else
                { ${head elems} = nestedEnabled (lists.drop 1 elems); };
          in
            acc // (nestedEnabled elems)
        ) {} contents);
      in
      {
        options = {
          bundles.${id} = {
            enable = mkModuleEnableOption {
              inherit name description;
            };

            contents = mkOption {
              type = types.listOf types.str;
              description = "Modules included with this bundle";
              default = contents;
            };
          };
        };

        config = mkIf cfg.enable (generateBundleConfig contents);
      };
}
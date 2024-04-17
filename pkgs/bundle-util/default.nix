{
  /*
    This utility creates a module that implements a bundle, which has
    these features:
    1. if the bundle is enabled, it enables by default a list of submodules
    2. exposes its submodules as a list of module ID strings via the `submodules`
    option

    Example:

    pkgs/bundles/nodejs/default.nix
    ```nix
    { pkgs, config, ... }:
    pkgs.lib.mkBundleModule {
    id = "nodejs";
    name = "Node.js Tools Bundle";
    description = "Development tools for the Node.js JavaScript runtime";
    submodules = [
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
  mkBundleModule = { id, name, description, submodules, pkgs, config }:
    with pkgs.lib;
    let
      cfg = config.bundles.${id};
      /*
      enablePath - generates an enable config defaulted to true
        for a submodules identified as 'elems' and merges it with an existing config.
      elems - result of spliting a module ID on "." e.g. ["interpreters" "nodejs"]
      config - an existing nested config, e.g.
        {
          interpreters = {
            nodejs = {
              enable = mkDefault true;
            };
          };
        }
      */
      enablePath = elems: config:
        if elems == [ ]
        then
          { enable = mkDefault true; }
        else
          let
            first = head elems;
            nestedConfig = enablePath (drop 1 elems) (config.${first} or { });
          in
          config // ({
            ${first} = nestedConfig;
          });
      /*
      mkBundleConfig - creates nested config of enable values defaulted to true
        from the passed in submodules list. e.g.

        mkBundleConfig ['a.b' 'c.d'] =>
        {
          a = {
            b = { enable = mkDefault true; };
          };
          c = {
            d = { enable = mkDefault true; };
          };
        }
      */
      mkBundleConfig = submodules:
        foldl'
          (config: moduleId:
            let elems = strings.splitString "." moduleId;
            in enablePath elems config
          )
          { }
          submodules;
    in
    {
      options = {
        bundles.${id} = {
          enable = mkModuleEnableOption {
            inherit name description;
          };

          submodules = mkOption {
            type = types.listOf types.str;
            description = "Modules included with this bundle";
            default = submodules;
          };
        };
      };

      config = mkIf cfg.enable (mkBundleConfig submodules);
    };
}
{ pkgs, lib, config, ... }:
let
  cfg = config.bundles.nodejs;
  availableVersions = {
    ${pkgs.nodejs_18.version} = pkgs.nodejs_18;
    ${pkgs.nodejs_20.version} = pkgs.nodejs_20;
  };
in
with pkgs.lib; {
  options = {
    bundles.nodejs = {
      enable = mkModuleEnableOption {
        name = "Node.js Tools Bundle";
        description = "Development tools for the Node.js JavaScript runtime";
      };

      members = mkOption {
        type = types.listOf types.str;
        description = "Modules included with this bundle";
        default = [
          "interpreters.nodejs"
          "languageServers.typescript-language-server"
          "debuggers.node-dap"
          "formatters.prettier"
          "packagers.nodejs-packager"
        ];
      };
    };
  };

  config = mkIf cfg.enable
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
    ) {} (mkDefault cfg.members));
  # {
  #   interpreters.nodejs.enable = mkDefault true;
  #   languageServers.typescript-language-server.enable = mkDefault true;
  #   debuggers.node-dap.enable = mkDefault true;
  #   formatters.prettier.enable = mkDefault true;
  #   packagers.nodejs-packager.enable = mkDefault true;
  # };
}
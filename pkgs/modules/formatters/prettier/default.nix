{ pkgs, lib, config, ... }:
let cfg = config.formatters.prettier;
  nodejs = config.interpreters.nodejs._nodejs;
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };
in
with pkgs.lib; {

  options = {
    formatters.prettier = {
      enable = mkModuleEnableOption {
        name = "Prettier";
        description = "An opinionated code formatter";
      };

      extensions = mkOption {
        type = types.listOf (types.str);
        description = "Extensions to use prettier for";
        default = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".html" ];
      };

      # nodejsVersion = mkOption {
      #   type = types.enum ["18" "20"];
      #   description = "Node.js version for prettier";
      #   default = "20";
      # };
    };
  };

  config = mkIf cfg.enable {
    # formatters.prettier.nodejsVersion = mkIf config.interpreters.nodejs.enable (mkDefault config.interpreters.nodejs.version);

    replit.dev = {
      packages = [
        nodepkgs.prettier
      ];

      formatters.prettier = {
        name = "Prettier";
        language = "javascript";
        extensions = cfg.extensions;
        start = {
          # Resolve to first prettier in path
          args = [ "prettier" "--stdin-filepath" "$file" ];
        };
        stdin = true;
      };
    };
  };

}
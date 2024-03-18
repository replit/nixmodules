{ pkgs, lib, config, ... }:
let cfg = config.formatters.prettier;
  nodejs = pkgs.${"nodejs_${cfg.nodejsVersion}"};
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };
in
with lib; {

  options = {
    formatters.prettier = {
      enable = mkEnableOption "Prettier Formatter";

      extensions = mkOption {
        type = types.listOf (types.str);
        default = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".html" ];
      };

      nodejsVersion = mkOption {
        type = types.enum ["18" "20"];
        default = "20";
      };
    };
  };

  config = mkIf cfg.enable {
    formatters.prettier.nodejsVersion = mkIf config.interpreters.nodejs.enable (mkDefault config.interpreters.nodejs.version);

    replit.dev = {
      packages = [
        nodepkgs.prettier
      ];

      formatters.prettier = {
        name = "Prettier";
        language = "javascript";
        extensions = cfg.extensions;
        displayVersion = "${nodepkgs.prettier.version} (Node ${nodejs.version})";
        start = {
          # Resolve to first prettier in path
          args = [ "prettier" "--stdin-filepath" "$file" ];
        };
        stdin = true;
      };
    };
  };

}
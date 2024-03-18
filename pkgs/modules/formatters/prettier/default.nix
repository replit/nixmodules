{ pkgs, lib, config, ... }:
let cfg = config.prettier;
  nodejs = pkgs.${"nodejs_${cfg.nodejsVersion}"};
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };
in
with lib; {

  options = {
    prettier.enable = mkEnableOption "Prettier Formatter";

    prettier.extensions = mkOption {
      type = types.listOf (types.str);
      default = [ ".js" ".jsx" ".ts" ".tsx" ".json" ".html" ];
    };

    prettier.nodejsVersion = mkOption {
      type = types.enum ["18" "20"];
      default = "20";
    };
  };

  config = mkIf cfg.enable {

    replit.dev = mkIf cfg.enable {
      packages = [
        nodepkgs.prettier
      ];

      formatters.prettier = {
        name = "Prettier";
        displayVersion = "${nodepkgs.prettier.version} (Node ${lib.versions.majorMinor nodejs.version})";
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
{ pkgs, lib, config, ... }:
let
  cfg = config.typescript-language-server;
  nodejs = pkgs.${"nodejs_${cfg.nodejsVersion}"};
  nodepkgs = pkgs.nodePackages.override {
    inherit nodejs;
  };
  typescript-language-server = nodepkgs.typescript-language-server.override {
    # TODO: we can get rid of this patch once >=4.2.0 is in the nixpkgs-unstable we use.
    # but we want this version because of https://github.com/typescript-language-server/typescript-language-server/pull/831
    version = "4.2.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-4.2.0.tgz";
      hash = "sha256-sg0O1uw6L3LDlPKTbXXsXVYwR+c7HH5c89xNIefEov8=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/typescript-language-server" \
        --suffix PATH : ${pkgs.lib.makeBinPath [ nodepkgs.typescript ]}
    '';
  };
in
with lib; {
  options = {
    typescript-language-server.enable = mkEnableOption "TypeScript Language Server";

    typescript-language-server.extensions = mkOption {
      type = types.listOf (types.str);
      default = [];
    };

    typescript-language-server.nodejsVersion = mkOption {
      type = types.enum ["18" "20"];
      default = "20";
    };
  };

  config = mkIf cfg.enable {
    replit.dev.languageServers.typescript-language-server = mkIf cfg.enable {
      name = "TypeScript Language Server";
      displayVersion = "${typescript-language-server.version} (Node ${lib.versions.majorMinor nodepkgs.nodejs.version})";
      language = "javascript";
      start = "${typescript-language-server}/bin/typescript-language-server --stdio";
      extensions = cfg.extensions;
      initializationOptions = {
        tsserver.fallbackPath = "${nodepkgs.typescript}/lib/node_modules/typescript/lib";
      };
    };
  };
}

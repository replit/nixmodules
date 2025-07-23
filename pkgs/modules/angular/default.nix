{ nodejs }:
{ pkgs, lib, ... }:

let
  nodeVersion = lib.versions.major nodejs.version;

  nodepkgs = nodejs.pkgs;

  angular-language-server = pkgs.callPackage ../../angular-language-server { };

  language = "angular";
in

{
  id = "angular-node-${nodeVersion}";
  name = "Angular Tools with Node.js";
  displayVersion = nodeVersion;
  description = ''
    Angular development tools including Node.js, Bun, pnpm, yarn, Angular language server.
  '';

  imports = [
    (import ../typescript-language-server {
      inherit nodepkgs;
    })
  ];

  replit = {
    packages = [
      pkgs.bun
      nodejs
      nodepkgs.pnpm
      nodepkgs.yarn
      angular-language-server
    ];

    env = {
      XDG_CONFIG_HOME = "$REPL_HOME/.config";
      npm_config_prefix = "$REPL_HOME/.config/npm/node_global";
      PATH = "$XDG_CONFIG_HOME/npm/node_global/bin:$REPL_HOME/node_modules/.bin";
    };

    dev.runners.dev-runner = {
      name = "package.json watch script";
      inherit language;
      start = "${nodejs}/bin/npm run watch";
    };

    dev.languageServers.angular-language-server = {
      name = "Angular Language Server";
      inherit language;
      start = "${angular-language-server}/bin/ngserver --stdio --tsProbeLocations node_modules,${nodepkgs.typescript}/lib/node_modules/typescript/lib --ngProbeLocations node_modules,${angular-language-server}/lib/node_modules/@angular/language-server/node_modules";
      extensions = [ ".html" ];
    };
  };
}


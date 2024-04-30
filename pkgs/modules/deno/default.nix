{ pkgs, lib, ... }:

let
  inherit (pkgs) deno;
  version = lib.versions.major deno.version;

  extensions = [ ".json" ".jsonc" ".js" ".jsx" ".ts" ".tsx" ];
in

{
  id = "deno-${version}";
  name = "Deno Tools";
  description = ''
    Tools for working with Deno:
    * Deno
    * Deno language server
  '';

  replit.packages = [
    deno
  ];

  replit.runners.deno-script-runner = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    fileParam = true;
    start = "${deno}/bin/deno run --allow-all $file";
  };

  replit.dev.languageServers.deno = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    start = "${deno}/bin/deno lsp --quiet";
  };
}

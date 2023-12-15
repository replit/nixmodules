{ pkgs, lib, ... }:

let
  inherit (pkgs) deno;
  version = lib.versions.major deno.version;

  extensions = [ ".json" ".jsonc" ".js" ".jsx" ".ts" ".tsx" ];

  deno-runner-name = "deno-with-env-permissions";
  deno-runner = pkgs.writeShellApplication {
    name = deno-runner-name;
    runtimeInputs = [
      deno
    ];
    text = builtins.readFile ./deno-with-env-perms.sh;
  };
in

{
  id = "deno-${version}";
  name = "Deno Tools";

  replit.packages = [
    deno
    deno-runner
  ];

  replit.runners.deno = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    optionalFileParam = true;
    start = "${deno-runner}/bin/${deno-runner-name} $file";
  };

  replit.dev.languageServers.deno = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    start = "${deno}/bin/deno lsp --quiet";
  };
}

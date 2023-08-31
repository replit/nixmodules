{ pkgs, lib, ... }:

let
  deno = pkgs.deno;
  version = lib.versions.majorMinor deno.version;

  extensions = [ ".json" ".jsonc" ".js" ".jsx" ".ts" ".tsx" ];

  deno-runner-name = "deno-with-env-perms";
  deno-runner = pkgs.writeShellApplication {
    name = deno-runner-name;
    runtimeInputs = [
      deno
      pkgs.jq
    ];
    text = builtins.readFile ./deno-with-env-perms.sh;
  };
in

{
  id = "deno-${version}";
  name = "Deno Tools";

  packages = [
    deno
    deno-runner
  ];

  # TODO: make script that reads env vars to pass perms args to deno cli
  replit.runners.deno = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    optionalFileParam = true;
    start = "${deno-runner}/bin/${deno-runner-name} $file";
  };

  replit.languageServers.deno = {
    name = "deno";
    language = "javascript";
    inherit extensions;
    start = "${deno}/bin/deno lsp --quiet";
  };
}

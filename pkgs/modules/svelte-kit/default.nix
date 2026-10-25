{ nodejs }:
{ pkgs, lib, ... }:

let
  node-version = lib.versions.major nodejs.version;
  svelte-language-server = pkgs.svelte-language-server.override { inherit nodejs; };
in
{
  id = "svelte-kit-node-${node-version}";
  name = "SvelteKit Tools with Node.js";
  displayVersion = node-version;
  description = ''
    Svelte Kit development tools. Includes Node.js, Svelte language server.
  '';

  replit = {
    packages = [
      nodejs
    ];

    # Nothing required for deployment because app compiles to a static site
    dev.runners.dev-server = {
      name = "package.json dev script";
      language = "svelte";
      extensions = [
        ".svelte"
        ".js"
        ".ts"
      ];

      start = "${nodejs}/bin/npm run dev";
    };

    dev.languageServers.svelte-language-server = {
      name = "Svelte Language Server";
      language = "svelte";
      extensions = [ ".svelte" ".js" ".ts" ];
      start = "${svelte-language-server}/bin/svelteserver --stdio";
    };
  };
}

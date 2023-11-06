{ pkgs-unstable, ... }:

{
  id = "svelte-kit-node-20";
  name = "SvelteKit with Node.js 20 Tools";

  replit = {
    packages = with pkgs-unstable; [
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

      start = "${pkgs-unstable.nodejs}/bin/npm run dev";
    };

    dev.languageServers.svelte-language-server = {
      name = "Svelte Language Server";
      language = "svelte";
      extensions = [ ".svelte" ".js" ".ts" ];
      start = "${pkgs-unstable.nodePackages.svelte-language-server}/bin/svelteserver --stdio";
    };
  };
}

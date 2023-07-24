{ pkgs-unstable, ... }:

{
  id = "svelte-kit-node-20";
  name = "SvelteKit with Node.js 20 Tools";
  imports = [
    (import ../typescript-language-server {
      nodepkgs = pkgs-unstable.nodePackages;
    })
  ];

  packages = with pkgs-unstable; [
    nodejs
  ];

  replit = {
    runners.dev-server = {
      name = "package.json dev script";
      language = "svelte";
      extensions = [
        ".svelte"
        ".js"
        ".ts"
      ];

      start = "${pkgs-unstable.nodejs}/bin/npm run dev";
    };

    languageServers.typescript-language-server.extensions = [
      ".ts"
      ".js"
    ];

    languageServers.svelte-language-server = {
      name = "Svelte Language Server";
      language = "svelte";
      extensions = [ ".svelte" ".js" ".ts" ];
      start = "${pkgs-unstable.nodePackages.svelte-language-server}/bin/svelteserver --stdio";
    };
  };
}

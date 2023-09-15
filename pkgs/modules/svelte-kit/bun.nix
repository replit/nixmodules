{ pkgs-unstable, lib, ... }:

let
  bun = pkgs-unstable.callPackage ../../bun { };

  community-version = lib.versions.majorMinor bun.version;
in

{
  id = "svelte-kit-bun-${community-version}";
  name = "SvelteKit with Bun ${community-version} Tools";

  imports = [
    (import ../run-package-json {
      runPackageJsonScript = "${bun}/bin/bun run";
      runFileScript = "${bun}/bin/bun";
    })
  ];

  packages = [
    bun
  ];

  replit = {
    runners."package.json" = {
      language = "svelte";
      extensions = [
        ".svelte"
        ".js"
        ".ts"
      ];
    };

    languageServers.svelte-language-server = {
      name = "Svelte Language Server";
      language = "svelte";
      extensions = [ ".svelte" ".js" ".ts" ];
      start = "${pkgs-unstable.nodePackages.svelte-language-server}/bin/svelteserver --stdio";
    };
  };
}

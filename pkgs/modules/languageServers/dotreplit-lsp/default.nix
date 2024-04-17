{ pkgs, config, ... }:
with pkgs.lib;
let
  cfg = config.languageServers.dotreplit-lsp;
  # use changes from https://github.com/tamasfe/taplo/pull/510
  # the above PR adds the `-c` flag to the `taplo lsp` command, which is
  # necessary to support our schema. There are a couple of paths forward
  # for replacing this derivation:
  # option 1:
  # - the above pr is merged
  # - new taplo version is released https://github.com/tamasfe/taplo/pull/502 (with my change)
  # - nixpkgs-unstable gets the updated version
  # - we update to nixpkgs-unstable that contains the updated taplo version
  # option 2:
  # - given that taplo currently consumes >1 mb of memory, it'd be nice to have
  #   a custom bin that wraps taplo-lsp crate that *only* provides lsp for .replit
  #   files. this should reduce the amount of consumed memory by a good amount.
  # - use the above custom bin
  taplo = pkgs.rustPlatform.buildRustPackage rec {
    pname = "taplo";
    version = "0.patched";
    src = pkgs.fetchFromGitHub {
      owner = "cdmistman";
      repo = "taplo";
      rev = "22eff1f7775e48eee8b50518c67f992b4595ab61";
      hash = "sha256-63fm8pH03TJd4QBuhIxtttoEAaBnc9TuHGKCMK4YGP0=";
    };

    cargoHash = "sha256-4OSCN2zCrlBHihZn7TCNZp4mCREpvrpKsfMSNP95GNc=";
    buildFeatures = [ "lsp" ];
  };

  taplo-config = pkgs.writeText "taplo-config.toml" ''
    include = ["**/.replit"]

    [schema]
    enabled = true
    path = "/etc/replit/dotreplit.schema.json"
  '';
in
{
  options = {
    languageServers.dotreplit-lsp = {
      enable = mkModuleEnableOption {
        name = ".replit Language Server";
        description = "Autocompletion help and more for editing .replit";
      };
    };
  };

  config = mkIf cfg.enable {
    replit.dev.languageServers.dotreplit-lsp = {
      name = ".replit LSP";
      language = "dotreplit";
      start = "${taplo}/bin/taplo lsp -c ${taplo-config} stdio";
    };
  };
}


{ pkgs, ... }:

let
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
  taplo = pkgs.rustPlatform.buildRustPackage {
    pname = "taplo";
    version = "0.patched";
    src = pkgs.fetchFromGitHub {
      owner = "tamasfe";
      repo = "taplo";
      rev = "acec15f897cb57fc33999779f875db58fd89945d";
      hash = "sha256-NjjRDvmZwYAcn0W5qnxS1Qr8DaOE93XNr6q57uvB2LE=";
    };

    cargoHash = "sha256-6vT1/3gV0A6ActfRrkmtxhv8+Wq+EZ4q6Pgvb+CdJDs=";
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
  id = "replit";
  name = "Base Replit Tools";
  description = ''
    Replit tools. Includes .replit language server.
  '';

  replit.dev.languageServers.dotreplit-lsp = {
    name = ".replit LSP";
    language = "dotreplit";
    start = "${taplo}/bin/taplo lsp -c ${taplo-config} stdio";
  };
}


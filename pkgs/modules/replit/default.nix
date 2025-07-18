{ pkgs, ... }:

let
  # use patched version of taplo to fix schema validation errors causing excessive lsp errors
  # specifically, the patch addresses error span issues with unexpected properties in .replit files
  # https://github.com/tamasfe/taplo/pull/664
  taplo = pkgs.rustPlatform.buildRustPackage {
    pname = "taplo";
    version = "0.patched";
    src = pkgs.fetchFromGitHub {
      owner = "cdmistman";
      repo = "taplo";
      rev = "only-share-spans-of-unexpected-properties";
      hash = "sha256-1GYmZZlFaa1w3zFfSlM7o4PXwjfKH3YnZbGWzBnobM4=";
    };

    cargoHash = "sha256-ejqrzSam1kuMRYQKV6O/LYTkik3XoO0HDth9N9YqrSI=";
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

  replit.env = {
    REPLIT_LD_AUDIT = "${pkgs.replit-rtld-loader}/rtld_loader.so";
  };

  replit.dev.languageServers.dotreplit-lsp = {
    name = ".replit LSP";
    language = "dotreplit";
    start = "${taplo}/bin/taplo lsp -c ${taplo-config} stdio";
  };
}

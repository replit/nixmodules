{ pkgs, lib, ... }:

let
  version = "0.286.0";
  databricks-cli = pkgs.stdenvNoCC.mkDerivation {
    pname = "databricks-cli";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/databricks/cli/releases/download/v${version}/databricks_cli_${version}_linux_amd64.tar.gz";
      hash = "sha256-lf6q0c9iZVNvIzLVrptTe0YudpFDVDdZXMWR8lOObw8=";
    };

    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 databricks $out/bin/databricks
      runHook postInstall
    '';
  };
in
{
  id = "databricks-cli";
  name = "Databricks CLI";
  description = ''
    The Databricks CLI is a command-line tool for interacting with
    Databricks. It provides commands to manage Databricks resources
    such as workspaces, jobs, clusters, libraries, and Databricks
    apps from the command line.
  '';
  displayVersion = version;

  replit.packages = [
    databricks-cli
  ];
}

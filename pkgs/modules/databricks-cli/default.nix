{ pkgs, lib, ... }:

let
  # Replit fork of databricks/cli, based on upstream v0.299.0 plus the
  # `sync: add --concurrency and --retry-timeout flags` patch (#1) that
  # pid2's deploy path needs.
  #
  # See https://github.com/replit/databricks-cli/releases for tags. To bump:
  # rebase replit/databricks-cli `main` onto a newer upstream tag, retag
  # vX.Y.Z-replit.<n>, push, then update version + hash + vendorHash here.
  version = "0.299.0-replit.1";
  databricks-cli = pkgs.buildGoModule {
    pname = "databricks-cli";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "replit";
      repo = "databricks-cli";
      rev = "v${version}";
      hash = "sha256-mrsxKw9pIgP14SBQH4+OAGpBPfKINtVACXMR7qEhfLY=";
    };

    vendorHash = "sha256-IcKEzXfmReVCUzMyPC3Y2BRXWwGoB8Gdd3y5p6FtxI0=";

    excludedPackages = [
      "bundle/internal"
      "acceptance"
      "integration"
      "tools/testrunner"
      "tools/testmask"
    ];

    postPatch = ''
      substituteInPlace bundle/deploy/terraform/init_test.go \
        --replace-fail "cli/0.0.0-dev" "cli/${version}"
    '';

    ldflags = [
      "-X github.com/databricks/cli/internal/build.buildVersion=${version}"
    ];

    postBuild = ''
      mv "$GOPATH/bin/cli" "$GOPATH/bin/databricks"
    '';

    # Tests are skipped in the nix sandbox. The Databricks CLI test suite
    # has a long tail of tests that try to resolve workspace clients, hit
    # the network, or otherwise depend on a working environment that the
    # nix sandbox does not provide. Each upstream bump tends to add new
    # offenders; rather than maintain an ever-growing -skip= regex (and
    # debug new entries on every rebase), we trust upstream's CI and skip
    # the whole checkPhase. Same pattern as `pkgs/modules/python/uv` and
    # the docker stack.
    doCheck = false;

    meta = {
      description = "Databricks CLI (Replit fork)";
      mainProgram = "databricks";
      homepage = "https://github.com/replit/databricks-cli";
      changelog = "https://github.com/replit/databricks-cli/releases/tag/v${version}";
      license = lib.licenses.databricks;
    };
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

    This is the Replit fork (https://github.com/replit/databricks-cli),
    based on upstream v0.299.0 with the --concurrency and --retry-timeout
    flags added to `databricks sync` for faster, more reliable deploys.
  '';
  displayVersion = version;

  replit.packages = [
    databricks-cli
  ];
}

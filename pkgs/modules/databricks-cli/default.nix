{ pkgs, lib, ... }:

let
  # Replit fork of databricks/cli. Adds --concurrency and --retry-timeout
  # flags to `databricks sync`. Based on upstream v0.290.2, the same release
  # nixpkgs is on, so the test skip list below stays in sync with nixpkgs'.
  # Source: https://github.com/replit/databricks-cli (replit-main branch)
  upstreamVersion = "0.290.2";
  rev = "4928653c0620fb73b20d57dda4a26a233c2546f1";
  version = "${upstreamVersion}-replit-${builtins.substring 0 8 rev}";
  databricks-cli = pkgs.buildGoModule {
    pname = "databricks-cli";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "replit";
      repo = "databricks-cli";
      inherit rev;
      hash = "sha256-wTceEtlE2EnOe2noUWTsN0DzMIJxV8yLvyQu2M3Ts8E=";
    };

    vendorHash = "sha256-8PJ2M5L8DkL4ydtUQbw0wKvt+5rVYbOAAGvURkSMm/o=";

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

    checkFlags =
      "-skip="
      + (lib.concatStringsSep "|" [
        # Need network
        "TestConsistentDatabricksSdkVersion"
        "TestTerraformArchiveChecksums"
        "TestExpandPipelineGlobPaths"
        "TestRelativePathTranslationDefault"
        "TestRelativePathTranslationOverride"
        "TestWorkspaceVerifyProfileForHost"
        "TestWorkspaceVerifyProfileForHost/default_config_file_with_match"
        "TestWorkspaceResolveProfileFromHost"
        "TestWorkspaceResolveProfileFromHost/no_config_file"
        "TestBundleConfigureDefault"
        # Use uv venv which doesn't work with nix
        # https://github.com/astral-sh/uv/issues/4450
        "TestVenvSuccess"
        "TestPatchWheel"
        # Fails in nix sandbox due to missing home/cache directory
        "TestCacheDirEnvVar"
      ]);

    nativeCheckInputs = [
      pkgs.gitMinimal
      (pkgs.python3.withPackages (
        ps: with ps; [
          setuptools
          wheel
        ]
      ))
    ];

    preCheck = ''
      # Some tests depend on git and remote url
      git init
      git remote add origin https://github.com/databricks/cli.git
    '';

    meta = {
      description = "Databricks CLI";
      mainProgram = "databricks";
      homepage = "https://github.com/replit/databricks-cli";
      changelog = "https://github.com/databricks/cli/releases/tag/v${upstreamVersion}";
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
  '';
  displayVersion = version;

  replit.packages = [
    databricks-cli
  ];
}

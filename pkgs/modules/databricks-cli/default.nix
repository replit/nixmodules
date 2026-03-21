{ pkgs, lib, ... }:

let
  version = "0.286.0";
  databricks-cli = pkgs.buildGoModule {
    pname = "databricks-cli";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "databricks";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-iCmxHjIYznqed6BMQKtuYHJNFPy+3XrNzSXfhtyzPJk=";
    };

    vendorHash = "sha256-TNUI2VQVKnxTiKQg9Bj3qDK2w3oOjO0rdrtTlFIhTzA=";

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
      homepage = "https://github.com/databricks/cli";
      changelog = "https://github.com/databricks/cli/releases/tag/v${version}";
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

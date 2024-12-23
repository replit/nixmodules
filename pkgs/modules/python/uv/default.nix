{ lib
, stdenv
, cmake
, fetchFromGitHub
, installShellFiles
, pkg-config
, rustPlatform
, versionCheckHook
, python3Packages
, nix-update-script
,
}:

rustPlatform.buildRustPackage rec {
  pname = "uv";
  version = "0.5.11"; # Technically 8 versions ahead of 0.5.11

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    rev = "ddc290feb4ed2de4740c786af2436cf1f82a3190";
    hash = "sha256-/hm70Vptk0eg9MMzgbpkOg/x6mNJBTZ/25kfqiYc/7Y=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-k+ABi0xgtpuDwCEgUIqrG7m56iSeYMsDTvtC0YHoCwE=";

  nativeBuildInputs = [
    cmake
    installShellFiles
    pkg-config
  ];

  dontUseCmakeConfigure = true;

  RUSTFLAGS = "-Z threads=8";

  cargoBuildFlags = [
    "--package"
    "uv"
  ];

  # Tests require python3
  doCheck = false;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    export HOME=$TMPDIR
    installShellCompletion --cmd uv \
      --bash <($out/bin/uv --generate-shell-completion bash) \
      --fish <($out/bin/uv --generate-shell-completion fish) \
      --zsh <($out/bin/uv --generate-shell-completion zsh)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgramArg = [ "--version" ];
  doInstallCheck = true;

  passthru = {
    tests.uv-python = python3Packages.uv;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Extremely fast Python package installer and resolver, written in Rust";
    homepage = "https://github.com/astral-sh/uv";
    changelog = "https://github.com/astral-sh/uv/blob/${version}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ GaetanLepage ];
    mainProgram = "uv";
  };
}

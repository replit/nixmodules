{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, installShellFiles
, buildPackages
, versionCheckHook
, nix-update-script
,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ty";
  version = "0.0.21";

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "ty";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-/R0nw9V0IhuTxRaZNydvk/xGC5V1gYHQxBkAU/Cjsmw=";
  };

  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    rm ${finalAttrs.cargoRoot}/crates/ty/tests/file_watching.rs
  '';

  cargoRoot = "ruff";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoBuildFlags = [ "--package=ty" ];

  cargoHash = "sha256-NaWWX6EAVkEg/KQ+Up0t2fh/24fnTo6i5dDZoOWErjg=";

  nativeBuildInputs = [ installShellFiles ];

  preCheck = ''
    export CARGO_BIN_EXE_ty="$PWD"/target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/ty
  '';

  cargoTestFlags = [
    "--package=ty"
    "--package=ty_python_semantic"
    "--package=ty_test"
  ];

  checkFlags = [
    "--skip=python_environment::ty_environment_and_active_environment"
    "--skip=python_environment::ty_environment_and_discovered_venv"
    "--skip=python_environment::ty_environment_is_only_environment"
    "--skip=python_environment::ty_environment_is_system_not_virtual"
    "--skip=mdtest::generics/pep695/functions.md"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      installShellCompletion --cmd ty \
        --bash <(${emulator} $out/bin/ty generate-shell-completion bash) \
        --fish <(${emulator} $out/bin/ty generate-shell-completion fish) \
        --zsh <(${emulator} $out/bin/ty generate-shell-completion zsh)
    ''
  );

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Extremely fast Python type checker and language server, written in Rust";
    homepage = "https://github.com/astral-sh/ty";
    changelog = "https://github.com/astral-sh/ty/blob/${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "ty";
    maintainers = with lib.maintainers; [
      bengsparks
      figsoda
      GaetanLepage
    ];
  };
})

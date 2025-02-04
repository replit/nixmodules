fenix-channel-name:
{ pkgs, ... }:
let
  rust-channel-name = if fenix-channel-name == "latest" then "nightly" else fenix-channel-name;
  channel = pkgs.fenix."${fenix-channel-name}";

  stripped-toolchain = pkgs.fenix.combine ([
    (channel.withComponents [
      "cargo"
      "llvm-tools"
      "rust-src"
      "rust-std"
      "rustc"
    ])
  ] ++ (
    if fenix-channel-name == "nightly" then [
      pkgs.fenix.targets.wasm32-wasi.${fenix-channel-name}.rust-std
      pkgs.fenix.targets.wasm32-unknown-unknown.${fenix-channel-name}.rust-std
    ] else [ ]
  ));

  toolchain = pkgs.fenix.combine ([
    channel.toolchain
  ] ++ (
    if fenix-channel-name == "nightly" then [
      pkgs.fenix.targets.wasm32-wasi.${fenix-channel-name}.rust-std
      pkgs.fenix.targets.wasm32-unknown-unknown.${fenix-channel-name}.rust-std
    ] else [ ]
  ));

  # TODO: fenix doesn't give the rustc stable version :(
  displayVersion = if fenix-channel-name == "stable" then "stable" else channel.cargo.version;
in
{
  id = "rust-${rust-channel-name}";
  name = "Rust Tools (${rust-channel-name})";
  inherit displayVersion;
  description = ''
    Rust development tools. Includes Rust compiler, Cargo, Rust analyzer.
  '';

  replit.packages = [
    stripped-toolchain
    pkgs.clang
    pkgs.pkg-config
  ];

  replit.dev.packages = [
    toolchain
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.cargo = {
    name = "cargo run";
    language = "rust";

    start = "${toolchain}/bin/cargo run";
    fileParam = false;
  };

  replit.dev.languageServers.rust-analyzer = {
    name = "rust-analyzer";
    language = "rust";

    start = "${toolchain}/bin/rust-analyzer";

    initializationOptions = {
      cargo.sysroot = "${toolchain}";
    };
  };

  replit.dev.packagers.rust = {
    name = "Cargo";
    language = "rust";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };

  replit.env = {
    CARGO_HOME = "$XDG_DATA_HOME/.cargo";
  };
}

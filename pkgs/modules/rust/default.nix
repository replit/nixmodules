fenix-channel-name:
{ pkgs, ... }:
let
  rust-channel-name = if fenix-channel-name == "latest" then "nightly" else fenix-channel-name;
  channel = pkgs.fenix."${fenix-channel-name}";
in
{
  id = "rust-${rust-channel-name}";
  name = "Rust Tools (${rust-channel-name})";

  replit.packages = [
    (channel.withComponents [
      "cargo"
      "llvm-tools"
      "rust-src"
      "rust-std"
      "rustc"
    ])

    pkgs.clang
    pkgs.pkg-config
  ];

  replit.dev.packages = [
    channel.toolchain
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.cargo = {
    name = "cargo run";
    language = "rust";

    start = "${channel.toolchain}/bin/cargo run";
    fileParam = false;
  };

  replit.dev.languageServers.rust-analyzer = {
    name = "rust-analyzer";
    language = "rust";

    displayVersion = rust-channel-name;
    start = "${channel.toolchain}/bin/rust-analyzer";

    initializationOptions = {
      cargo.sysroot = "${channel.toolchain}";
    };
  };

  replit.dev.packagers.rust = {
    name = "Rust";
    language = "rust";
    displayVersion = rust-channel-name;
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };

  replit.env = {
    CARGO_HOME = "$REPL_HOME/.cargo";
  };
}

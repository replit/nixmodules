{ pkgs, lib, ... }:
let
  inherit (pkgs.fenix.stable) toolchain;
in
{
  id = "rust-stable";
  name = "Rust Tools";

  replit.dev.packages = with toolchain; [
    toolchain

    pkgs.clang
    pkgs.pkg-config
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
    name = "Rust";
    language = "rust";
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

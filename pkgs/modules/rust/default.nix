{ pkgs, ... }:
let
  inherit (pkgs.fenix) stable;
in
{
  id = "rust-stable";
  name = "Rust Tools";

  replit.packages = [
    (stable.withComponents [
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
    stable.toolchain
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.cargo = {
    name = "cargo run";
    language = "rust";

    start = "${stable.toolchain}/bin/cargo run";
    fileParam = false;
  };

  replit.dev.languageServers.rust-analyzer = {
    name = "rust-analyzer";
    language = "rust";

    start = "${stable.toolchain}/bin/rust-analyzer";

    initializationOptions = {
      cargo.sysroot = "${stable.toolchain}";
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

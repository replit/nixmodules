{ pkgs, lib, ... }:
let
  clang = pkgs.clang_20;
  run-extensions = [ ".c" ]; # use this list for file-param runners because
  # we don't want .h files to be runnable
  clang-compile = import ../../clang-compile {
    inherit pkgs;
    inherit clang;
  };
  dap-cpp = pkgs.callPackage ../../dap-cpp { };
  dap-cpp-messages = import ../../dap-cpp/messages.nix;

  clang-version = lib.versions.major clang.version;
in
{
  id = "c-clang${clang-version}";
  name = "C Tools (with Clang)";
  displayVersion = clang-version;
  description = ''
    Tools for working with C programming language. Includes Clang compiler, and ccls language server.
  '';

  replit.packages = [
    clang
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.clang-project = {
    name = "Clang: Project";
    compile = "${clang-compile}/bin/clang-compile $file c all";
    fileParam = true;
    language = "c";
    start = "./main.c.bin";
  };

  # TODO: add back single runners/debuggers when we have multiple runners
  # we want to avoid an unstable first runner for users
  # that do not have multiple runners turned on

  # replit.runners.clang-single = {
  #   name = "Clang: Single File";
  #   compile = "${clang-compile}/bin/clang-compile $file c single";
  #   fileParam = true;
  #   language = "c";
  #   extensions = run-extensions;
  #   start = "./\${file}.bin";
  # };

  replit.dev.languageServers.ccls = {
    name = "ccls";
    language = "c";
    start = "${pkgs.ccls}/bin/ccls";
  };
}

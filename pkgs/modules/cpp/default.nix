{ pkgs, lib, ... }:
let
  clang = pkgs.clang_14;
  clang-compile = import ../../clang-compile {
    inherit pkgs;
    inherit clang;
  };
  dap-cpp = pkgs.callPackage ../../dap-cpp { };
  dap-cpp-messages = import ../../dap-cpp/messages.nix;

  clang-version = lib.versions.major clang.version;
in
{
  id = "cpp-clang${clang-version}";
  name = "C++ Tools (with Clang)";
  displayVersion = clang-version;
  description = ''
    Tools for working with C++:
    * Clang compiler
    * GDB debugger
    * ccls language server
  '';

  replit.packages = [
    clang
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.clang-project = {
    name = "Clang++: Project";
    compile = "${clang-compile}/bin/clang-compile $file cpp all";
    fileParam = true;
    language = "cpp";
    start = "./main.cpp.bin";
  };

  # TODO: add single runners/debuggers when we have priority for runners

  replit.dev.languageServers.ccls = {
    name = "ccls";
    language = "cpp";
    start = "${pkgs.ccls}/bin/ccls";
  };

  replit.dev.debuggers.gdb-project = {
    name = "GDB C++: Project";
    language = "cpp";
    start = "${dap-cpp}/bin/dap-cpp";
    fileParam = false;
    compile = "${clang-compile}/bin/clang-compile main.cpp cpp all debug";
    transport = "stdio";
    initializeMessage = dap-cpp-messages.dapInitializeMessage;
    launchMessage = dap-cpp-messages.dapLaunchMessage "./main.cpp.bin";
  };
}

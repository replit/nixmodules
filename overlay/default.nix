final: prev: {
  bun = final.callPackage ./bun { };

  clang-compile = final.callPackage ./clang-compile { };

  dap-cpp = final.callPackage ./dap-cpp { };

  dapPython = final.callPackage ./dapPython {
    pypkgs = prev.pythonPackages;
  };

  java-debug = final.callPackage ./java-debug { };

  jdt-language-server = final.callPackage ./jdt-language-server { };

  phpactor = final.callPackage ./phpactor { };

  pip = final.callPackage ./pip { };

  poetry = final.callPackage ./poetry { };

  python-lsp-server = final.callPackage ./python-lsp-server { };

  replbox = final.callPackage ./replbox { };

  stderred = final.callPackage ./stderred {
    inherit (prev) stderred;
  };
}

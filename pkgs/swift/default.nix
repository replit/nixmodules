{ pkgs, ... }:
let
  swiftc-wrapper = pkgs.stdenv.mkDerivation {
    name = "swiftc-wrapper";
    buildInputs = [ pkgs.makeWrapper ];
    src = ./.;


    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.swift}/bin/swiftc $out/bin/swiftc \
        --set PATH ""
    '';
  };
in
{
  name = "SwiftTools";
  version = "1.0";

  packages = with pkgs; [
    swiftc-wrapper
    swift
  ];

  replit.runners.swift = {
    name = "Swift";
    language = "swift";
    start = "${pkgs.swift}/bin/swift $file";
    fileParam = true;

    productionOverride = {
      start = "./\${file%.swift}.bin";
      compile = "${swiftc-wrapper}/bin/swiftc $file -o \${file%.swift}.bin";
      fileParam = true;
    };
  };

  replit.languageServers.sourcekit = {
    name = "SourceKit";
    language = "swift";

    start = "${pkgs.swift}/bin/sourcekit-lsp";
  };

}

{ pkgs, lib, ... }:
let
  inherit (pkgs) swift;

  swift-version = lib.versions.majorMinor (
    if builtins.hasAttr "version" swift
    then swift.version
    else (builtins.parseDrvName swift.name).version
  );

  swiftc-wrapper = pkgs.stdenv.mkDerivation {
    name = "swiftc-wrapper";
    buildInputs = [ pkgs.makeWrapper ];
    src = ./.;


    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${swift}/bin/swiftc $out/bin/swiftc \
        --set PATH ""
    '';
  };
in
{
  id = "swift-${swift-version}";
  name = "Swift Tools";

  packages = [
    swiftc-wrapper
    swift
  ];

  replit.runners.swift = {
    name = "Swift";
    language = "swift";
    start = "${swift}/bin/swift $file";
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

    start = "${swift}/bin/sourcekit-lsp";
  };

}

{ pkgs-23_05, lib, ... }:
let
  pkgs = pkgs-23_05;
  swift-version = lib.versions.majorMinor pkgs.swift.version;

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
  id = "swift-${swift-version}";
  name = "Swift Tools";
  displayVersion = swift-version;
  description = ''
    Swift development tools. Includes:
    * Swift compiler
    * Sourcekit language server
  '';

  replit.packages = with pkgs; [
    swiftc-wrapper
    swift
  ];

  # TODO: should compile a binary to be used in deployment
  replit.runners.swift = {
    name = "Swift";
    language = "swift";
    start = "${pkgs.swift}/bin/swift $file";
    fileParam = true;
  };

  replit.dev.languageServers.sourcekit = {
    name = "SourceKit";
    language = "swift";

    start = "${pkgs.swift}/bin/sourcekit-lsp";
  };

}

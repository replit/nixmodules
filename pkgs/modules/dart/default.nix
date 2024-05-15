{ pkgs, lib, ... }:
let dart-version = lib.versions.majorMinor pkgs.dart.version;
in {
  id = "dart-${dart-version}";
  name = "Dart Tools";
  displayVersion = dart-version;
  description = ''
    Tools for working with Dart:
    * Dart
    * Dart language server
    * Dart pub package manager
  '';

  replit.packages = [
    pkgs.dart
  ];

  replit.runners.dart = {
    name = "dart";
    language = "dart";

    start = "${pkgs.dart}/bin/dart main.dart";
  };

  replit.dev.languageServers.dart-pub = {
    name = "dart";
    language = "dart";

    start = "${pkgs.dart}/bin/dart language-server";
  };

  replit.dev.packagers.dart-pub = {
    name = "Dart pub";
    language = "dart-pub";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

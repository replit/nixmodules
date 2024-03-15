{ pkgs, lib, ... }:
let dart-version = lib.versions.majorMinor pkgs.dart.version;
in {
  id = "dart-${dart-version}";
  name = "Dart Tools";

  replit.packages = [
    pkgs.dart
  ];

  replit.runners.dart = {
    name = "dart";
    language = "dart";

    start = "${pkgs.dart}/bin/dart main.dart";
  };

  replit.dev.languageServers.dart-lsp = {
    name = "dart LSP";
    language = "dart";

    displayVersion = "Dart ${pkgs.dart.version}";
    start = "${pkgs.dart}/bin/dart language-server";
  };

  replit.dev.packagers.dart-pub = {
    name = "dart pub";
    language = "dart-pub";
    displayVersion = "Dart ${pkgs.dart.version}";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

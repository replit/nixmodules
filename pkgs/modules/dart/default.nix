{ dart }:
{ pkgs, lib, ... }:
let dart-version = lib.versions.majorMinor pkgs.dart.version;
in {
  id = "dart-${dart-version}";
  name = "Dart Tools";

  packages = [
    dart
  ];

  replit.runners.dart = {
    name = "dart";
    language = "dart";

    start = "${dart}/bin/dart main.dart";
  };

  replit.languageServers.dart-pub = {
    name = "dart";
    language = "dart";

    start = "${dart}/bin/dart language-server";
  };

  replit.packagers.dart-pub = {
    name = "dart pub";
    language = "dart-pub";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

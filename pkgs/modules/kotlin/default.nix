{ pkgs, lib, ... }:

let
  inherit (pkgs) kotlin;

  version = lib.versions.major kotlin.version;

  extensions = [ ".kt" ".kts" ".java" ];
in

{
  id = "kotlin-${version}";
  name = "Kotlin Tools";

  imports = [
    ../java/upm-maven.nix
  ];

  packages = [
    kotlin
    pkgs.gradle
    pkgs.maven
  ];

  replit.languageServers.kotlin = {
    name = "Kotlin Language Server";
    language = "kotlin";
    inherit extensions;

    start = "${pkgs.kotlin-language-server}/bin/kotlin-language-server";
  };

  replit.runners.kotlin = {
    name = "Kotlin (Java)";
    language = "kotlin";
    inherit extensions;
    compile = "${kotlin}/bin/kotlinc -d main.jar main.kt";
    start = "${kotlin}/bin/kotlin -classpath main.jar MainKt";
  };
}

{ pkgs-23_05, lib, ... }:

let
  pkgs = pkgs-23_05;

  graalvm = pkgs.graalvm19-ce;

  short-graalvm-version = lib.versions.majorMinor graalvm.version;

  graal-compile-command = "${graalvm}/bin/javac -classpath .:target/dependency/* -d . $(find . -type f -name '*.java')";

  jdt-language-server = pkgs.callPackage ../../jdt-language-server { };

  java-language-server = pkgs.java-language-server;

  run-lsp = pkgs.writeShellApplication {
    name = "run-lsp";
    text = ''
      # Allow setting this env var to diagnose the lsp
      if [[ -n "''${JAVA_LANGUAGE_SERVER_LOG-}" ]]; then
        ${java-language-server}/bin/java-language-server --logFile "$JAVA_LANGUAGE_SERVER_LOG"
      else
        ${java-language-server}/bin/java-language-server
      fi
    '';
  };
in

{
  id = "java-graalvm${short-graalvm-version}";
  name = "Java Tools (with Graal VM)";
  description = ''
    Development tools for Java programming language. Includes GraalVM, Maven, and Java language server.
  '';
  displayVersion = graalvm.version;

  replit.packages = [
    graalvm
    pkgs.maven
  ];

  replit.runners.graal = {
    name = "GraalVM ${short-graalvm-version}";
    displayVersion = graalvm.version;
    language = "java";

    compile = graal-compile-command;
    start = "${graalvm}/bin/java -classpath .:target/dependency/* Main";
  };

  replit.dev.packagers.maven = {
    name = "Maven";
    language = "java-maven";
    features = {
      enabledForHosting = false;
      packageSearch = true;
      guessImports = false;
    };
  };

  replit.dev.languageServers.java-language-server = {
    name = "Java Language Server";
    displayVersion = java-language-server.version;
    language = "java";

    start = "${run-lsp}/bin/run-lsp";
    configuration.java.home = graalvm.outPath;
    configuration.java.setSystemPath = true;
  };
}

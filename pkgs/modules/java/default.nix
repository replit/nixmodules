{ pkgs-23_05, lib, ... }:

let
  pkgs = pkgs-23_05;

  graalvm = pkgs.graalvm19-ce;

  graalvm-version = lib.versions.majorMinor graalvm.version;

  graal-compile-command = "${graalvm}/bin/javac -classpath .:target/dependency/* -d . $(find . -type f -name '*.java')";

  jdt-language-server = pkgs.callPackage ../../jdt-language-server { };

  java-language-server = pkgs.java-language-server;

  java-debug = pkgs.callPackage ../../java-debug {
    inherit jdt-language-server;
    jdk = pkgs.graalvm11-ce;
  };

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
  id = "java-graalvm${graalvm-version}";
  name = "Java Tools (with Graal VM)";

  replit.packages = [
    graalvm
    pkgs.maven
  ];

  replit.runners.graal = {
    name = "GraalVM ${graalvm-version}";
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

  replit.dev.debuggers.java-debug = {
    name = "Jave Debug";
    language = "java";
    extensions = [ ".java" ];

    transport = "localhost:0";
    compile = graal-compile-command;
    start = "${java-debug}/bin/java-debug";

    initializeMessage = {
      command = "initialize";
      arguments = {
        adapterID = "cppdbg";
        clientID = "replit";
        clientName = "replit.com";
        columnsStartAt1 = true;
        linesStartAt1 = true;
        locale = "en-us";
        pathFormat = "path";
        supportsInvalidatedEvent = true;
        supportsProgressReporting = true;
        supportsRunInTerminalRequest = true;
        supportsVariablePaging = true;
        supportsVariableType = true;
      };
    };

    launchMessage = {
      command = "launch";
      arguments = {
        classPaths = [ "." ];
        mainClass = "Main";
      };
    };
  };

  replit.languageServers.jdt = {
    name = "JDT Language Server";
    language = "java";

    start = "${jdt-language-server}/bin/jdt-language-server";
  };
}

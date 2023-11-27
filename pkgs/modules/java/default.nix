# TODO: fix this
# there's maven issues with java-debug and java-language-server
{ pkgs, lib, ... }:

let
  graalvm = pkgs.graalvm-ce;

  graalvm-version = lib.versions.major graalvm.version;

  graal-compile-command = "${graalvm}/bin/javac -classpath .:target/dependency/* -d . $(find . -type f -name '*.java')";

  jdt-language-server = pkgs.callPackage ../../jdt-language-server { };

  java-language-server = pkgs.java-language-server.override {
    jdk = pkgs.graalvm-ce;
  };

  # TODO: java-debug doesn't work with java 21 :( gotta either update the repo or
  # use a different graalvm version, which i'm not 100% convinced will work off
  # the bat but also this nixmodule is currently unused so just kicking cans i guess
  # java-debug = pkgs.callPackage ../../java-debug {
  #   inherit jdt-language-server;
  #   jdk = pkgs.graalvm-ce;
  # };

  run-lsp = pkgs.writeShellScriptBin "run-lsp" ''
    # Allow setting this env var to diagnose the lsp
    if [[ $JAVA_LANGUAGE_SERVER_LOG ]]; then
      ${java-language-server}/bin/java-language-server --logFile $JAVA_LANGUAGE_SERVER_LOG
    else
      ${java-language-server}/bin/java-language-server
    fi
  '';

in

{
  id = "java-${graalvm-version}-graalvm";
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

  # replit.dev.debuggers.java-debug = {
  # name = "Jave Debug";
  # language = "java";
  # extensions = [ ".java" ];

  # transport = "localhost:0";
  # compile = graal-compile-command;
  # start = "${java-debug}/bin/java-debug";

  # initializeMessage = {
  # command = "initialize";
  # arguments = {
  # adapterID = "cppdbg";
  # clientID = "replit";
  # clientName = "replit.com";
  # columnsStartAt1 = true;
  # linesStartAt1 = true;
  # locale = "en-us";
  # pathFormat = "path";
  # supportsInvalidatedEvent = true;
  # supportsProgressReporting = true;
  # supportsRunInTerminalRequest = true;
  # supportsVariablePaging = true;
  # supportsVariableType = true;
  # };
  # };

  # launchMessage = {
  # command = "launch";
  # arguments = {
  # classPaths = [ "." ];
  # mainClass = "Main";
  # };
  # };
  # };

  replit.dev.languageServers.java-language-server = {
    name = "Java Language Server";
    language = "java";

    start = "${run-lsp}/bin/run-lsp";
    configuration.java.home = graalvm.outPath;
    configuration.java.setSystemPath = true;
  };
}

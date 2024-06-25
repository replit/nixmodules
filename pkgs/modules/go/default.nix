{ go, gopls }:
{ pkgs, lib, ... }:
let
  goversion = lib.versions.majorMinor go.version;

  formatter = import ../../formatter {
    inherit pkgs;
  };
  run-gofmt = pkgs.writeShellApplication {
    name = "run-gofmt";
    runtimeInputs = [ pkgs.bash ];
    extraShellCheckFlags = [ "-x" ];
    text = ''
      #!/bin/bash

      # Source the shared options parsing script
      source ${formatter}/bin/parse-formatter-options "$@"

      # Translate parsed arguments into gofmt options
      gofmt_args=()

      # Apply edit flag
      if [[ "$apply" == "true" ]]; then
        gofmt_args+=("-w")
      fi

      # Append the file path
      gofmt_args+=("$file")

      # Execute the command
      gofmt "''${gofmt_args[@]}"
    '';
  };

in
{
  id = "go-${goversion}";
  name = "Go Tools";
  displayVersion = goversion;
  description = ''
    Go development tools. Includes Go compiler, Go fmt formatter, Gopls - Go language server.
  '';

  replit.packages = [
    go
  ];

  replit.dev.packages = [
    gopls
  ];

  # TODO: should compile a binary to use in deployment and not include the runtime
  replit.runners.go-run = {
    name = "go run";
    language = "go";

    start = "${go}/bin/go run $REPL_HOME";
  };

  replit.dev.formatters.go-fmt = {
    name = "go fmt";
    language = "go";
    start = {
      args = [ "${run-gofmt}/bin/run-gofmt" "-f" "$file" ];
    };
    stdin = false;
  };

  replit.dev.languageServers.gopls = {
    name = "gopls";
    language = "go";

    start = "${gopls}/bin/gopls";
  };
}

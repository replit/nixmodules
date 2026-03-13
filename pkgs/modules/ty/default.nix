{ pkgs, lib, ... }:
let
  ty = pkgs.callPackage ../../ty { };

  formatter = import ../../formatter {
    inherit pkgs;
  };

  run-ruff-format = pkgs.writeShellApplication {
    name = "run-ruff-format";
    runtimeInputs = [
      pkgs.bash
      pkgs.ruff
    ];
    extraShellCheckFlags = [ "-x" ];
    text = ''
      #!/bin/bash

      # Source the shared options parsing script
      source ${formatter}/bin/parse-formatter-options "$@"

      if [[ "$apply" == "true" ]]; then
        if [[ "$stdinMode" == "true" ]]; then
          ruff format --stdin-filename "$file" - > "$file"
        else
          ruff format --quiet "$file"
        fi
        exit 0
      fi

      if [[ "$stdinMode" == "true" ]]; then
        ruff format --stdin-filename "$file" -
      else
        ruff format --stdin-filename "$file" - < "$file"
      fi
    '';
    checkPhase = ''
      cat > test.py << 'EOF'
      def greet(  name:str ) ->None:
          print( f"hello, {name}" )
      EOF

      $out/bin/run-ruff-format -f test.py > output.py
      printf 'def greet(name: str) -> None:\n    print(f"hello, {name}")\n' > expected.py
      if ! diff expected.py output.py; then
        echo "format output doesn't match expectation"
        exit 1
      fi

      cp test.py applied.py
      $out/bin/run-ruff-format --apply -f applied.py
      if ! diff expected.py applied.py; then
        echo "apply format output doesn't match expectation"
        exit 1
      fi
    '';
  };
in
{
  id = lib.mkDefault "ty";
  name = lib.mkDefault "ty LSP";
  displayVersion = lib.mkDefault ty.version;
  description = lib.mkDefault ''
    Ty is an extremely fast Python type checker from Astral with an integrated language server.
  '';
  replit.dev.languageServers.ty = {
    name = "ty";
    displayVersion = ty.version;
    language = "python3";
    start = "${ty}/bin/ty server";
  };

  replit.dev.formatters.ruff = {
    name = "Ruff";
    displayVersion = pkgs.ruff.version;
    language = "python3";
    extensions = [ ".py" ];
    start = {
      args = [ "${run-ruff-format}/bin/run-ruff-format" ];
    };
    stdin = true;
  };

  replit.env = {
    PATH = lib.mkDefault "${ty}/bin";
  };
}

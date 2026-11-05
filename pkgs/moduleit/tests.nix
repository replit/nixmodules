{ pkgs }:
let
  inherit (pkgs) lib;
  runtime = pkgs.runCommand "module-shell-test-runtime" { } ''
    mkdir -p "$out/bin" "$out/nix-support"
    printf '#!/bin/sh\nexit 0\n' > "$out/bin/runtime"
    chmod +x "$out/bin/runtime"
    cat > "$out/nix-support/setup-hook" <<'HOOK'
    : "$NIX_CC"
    echo "A runtime-only build hook was sourced" >&2
    return 1
    HOOK
  '';
  ide = pkgs.writeText "module-shell-test-ide" "IDE-only dependency";
  definition = {
    id = "fixture";
    name = "Fixture";
    replit = {
      packages = [ runtime ];
      env = {
        A_DEPENDENT = "$Z_BASE/child";
        Z_BASE = "$REPL_HOME/base";
        BRACED = "\${Z_BASE}/braced";
        LITERAL = "$(touch /tmp/nixmodules-shell-injection) `false` \" ' \\";
        PYTHONPATH = "$PYTHONPATH/suffix";
        MISSING = "$NOT_PRESENT";
        EMPTY = "";
        MULTILINE = "first=line\nsecond=line";
        MODE = "deployment";
        PATH = "$Z_BASE/bin";
      };
      runners.fixture = {
        name = "Fixture";
        language = "fixture";
        start = "${runtime}/bin/runtime $file";
      };
      dev = {
        env.MODE = "development";
        languageServers.fixture = {
          name = "Fixture server";
          language = "fixture";
          start = "${ide} $file";
        };
      };
    };
  };
  mkModule = deployment: configPath: pkgs.callPackage ./entrypoint.nix {
    inherit deployment configPath;
    pkgs-23_05 = pkgs;
    pkgs-24_11 = pkgs;
  };
  development = mkModule false definition;
  deployment = mkModule true definition;
  applyAliases = import ../upgrade-map/apply.nix { alias = "fixture"; };
  self = {
    modules = applyAliases {
      fixture = development;
      override = mkModule false {
        id = "override";
        name = "Override";
        replit.env.MODE = "last";
      };
    };
    deploymentModules = applyAliases { fixture = deployment; };
  };
  legacyBundle = pkgs.callPackage ../bundle { inherit self; };
  mkBundle = import ../bundle/api.nix { inherit pkgs self; };
  deploymentBundle = mkBundle { moduleIds = [ "alias" ]; deployment = true; };
  closure = pkgs.closureInfo { rootPaths = [ development.shellPackage ]; };
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  lazyModule = mkModule false {
    id = "lazy";
    name = "Lazy";
    replit.packages = throw "moduleId must not evaluate packages or output paths";
  };
  cycle = pkgs.callPackage ./shell-package.nix {
    name = "cycle";
    moduleId = "cycle";
    module = pkgs.writeText "cycle" "{}";
    packages = [ ];
    env = { A = "$B"; B = "$A"; };
  };
  decoy = pkgs.writeShellApplication { name = "runtime"; text = "exit 1"; };
  # What nix develop does: capture the env in a build, then run shellHook in the user's shell.
  shellSmoke = pkgs.runCommand "module-shell-smoke"
    {
      nativeBuildInputs = [ decoy self.modules.alias.shellPackage self.modules.override.shellPackage ];
      shellHook = "export USER_HOOK_MODE=$MODE";
    } ''
    test -z "''${MODE-}"
    export REPL_HOME="/tmp/project with spaces"
    eval "$shellHook"
    test "$MODE" = development
    test "$USER_HOOK_MODE" = development
    test "$A_DEPENDENT" = "$REPL_HOME/base/child"
    test "$(command -v runtime)" = "${runtime}/bin/runtime"
    test "$REPLIT_MODULES" = "${development.shellPackage}/share/replit/modules:${self.modules.override.shellPackage}/share/replit/modules"
    touch "$out"
  '';
in
assert lazyModule.moduleId == "lazy";
assert fails (mkBundle { moduleIds = [ "missing" ]; }).outPath;
assert fails (mkBundle { moduleIds = [ "fixture" "missing" ]; }).outPath;
assert fails (mkBundle { moduleIds = [ "missing" ]; deployment = true; }).outPath;
assert (legacyBundle { moduleIds = [ "fixture" "missing" ]; }).outPath
  == (legacyBundle { moduleIds = [ "fixture" ]; }).outPath;
assert (legacyBundle { moduleIds = [ "missing" ]; }).outPath
  == (legacyBundle { moduleIds = [ ]; }).outPath;
assert (legacyBundle { moduleIds = [ "alias" "missing" ]; deployment = true; }).outPath
  == deploymentBundle.outPath;
assert fails cycle.outPath;
pkgs.runCommand "module-shell-check"
{
  nativeBuildInputs = [ pkgs.jq ];
} ''
  test -f ${shellSmoke}
  test "$(readlink ${deploymentBundle}/alias)" = "${deployment}"
  jq -e --arg path "${deployment}" '.alias.path == $path' ${deploymentBundle}/etc/nixmodules/modules.json
  jq -e '.env.MODE == "development" and .languageServers != {}' ${development}
  jq -e '.env.MODE == "deployment" and .languageServers == {}' ${deployment}
  cmp ${development} ${development.shellPackage}/share/replit/modules/fixture.json
  grep -Fx ${runtime} ${closure}/store-paths
  grep -Fx ${ide} ${closure}/store-paths
  if grep -Fx ${pkgs.jq} ${closure}/store-paths; then
    echo "Module package includes a JSON encoder dependency" >&2
    exit 1
  fi
  (
    export REPL_HOME="/tmp/project with spaces"
    export PATH="/original/path"
    export PYTHONPATH="/inherited"
    unset REPLIT_MODULES
    source ${development.shellPackage}/nix-support/replit-env
    test "$A_DEPENDENT" = "$REPL_HOME/base/child"
    test "$BRACED" = "$REPL_HOME/base/braced"
    test "$LITERAL" = ${lib.escapeShellArg definition.replit.env.LITERAL}
    test "$PYTHONPATH" = "/inherited/suffix"
    test "$MISSING" = ""
    test "$EMPTY" = ""
    test "$MULTILINE" = ${lib.escapeShellArg definition.replit.env.MULTILINE}
    test "$MODE" = development
    test "$PATH" = "$REPL_HOME/base/bin:${runtime}/bin:/original/path"
    test "$REPLIT_MODULES" = "${development.shellPackage}/share/replit/modules"
  )
  (
    unset REPL_HOME PYTHONPATH
    source ${development.shellPackage}/nix-support/replit-env
    test "$REPL_HOME" = "$PWD"
    test "$PYTHONPATH" = "/suffix"
  )
  touch "$out"
''

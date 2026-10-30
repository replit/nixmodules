{ pkgs }:
let
  inherit (pkgs) lib;
  runtime = pkgs.runCommand "toolchain-test-runtime" { } ''
    mkdir -p "$out/bin" "$out/nix-support"
    printf '#!/bin/sh\nexit 0\n' > "$out/bin/runtime"
    chmod +x "$out/bin/runtime"
    cat > "$out/nix-support/setup-hook" <<'HOOK'
    : "$NIX_CC"
    echo "A runtime-only build hook was sourced" >&2
    return 1
    HOOK
  '';
  ide = pkgs.writeText "toolchain-test-ide" "IDE-only dependency";
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
  mkModule = deployment: configPath: pkgs.callPackage ../moduleit/entrypoint.nix {
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
  mkToolchain = import ./default.nix { inherit pkgs self; };
  legacyBundle = pkgs.callPackage ../bundle { inherit self; };
  mkBundle = import ../bundle/api.nix { inherit pkgs self; };
  deploymentBundle = mkBundle { moduleIds = [ "alias" ]; deployment = true; };
  toolchain = mkToolchain { moduleIds = [ "fixture" "alias" ]; };
  overridden = mkToolchain { moduleIds = [ "alias" "override" ]; };
  deploymentToolchain = mkToolchain { moduleIds = [ "fixture" ]; deployment = true; };
  closure = pkgs.closureInfo { rootPaths = [ toolchain ]; };
  deploymentClosure = pkgs.closureInfo { rootPaths = [ deploymentToolchain ]; };
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  lazyModule = mkModule false {
    id = "lazy";
    name = "Lazy";
    replit.packages = throw "moduleId must not evaluate packages or output paths";
  };
  cycle = pkgs.callPackage ../moduleit/shell-package.nix {
    name = "cycle";
    packages = [ ];
    env = { A = "$B"; B = "$A"; };
  };
  shellSmoke = pkgs.runCommand "toolchain-shell-check"
    {
      nativeBuildInputs = [ toolchain.shellPackage ];
      REPL_HOME = "/tmp/project with spaces";
    } ''
    test "$MODE" = development
    test "$A_DEPENDENT" = "$REPL_HOME/base/child"
    test "$(command -v runtime)" = "${runtime}/bin/runtime"
    touch "$out"
  '';
  environmentInput = {
    REPL_HOME = "/tmp/project with spaces";
    PATH = "/original/path";
    PYTHONPATH = "/inherited";
  };
  environmentArgs = lib.concatStringsSep " "
    (lib.mapAttrsToList (key: value: lib.escapeShellArg "${key}=${value}") environmentInput);
  decodeEnvironment = ''
    split("\u0000")
    | if last != "" then error("Missing trailing NUL") else .[:-1] end
    | map(index("=") as $separator | {key: .[:$separator], value: .[$separator + 1:]})
    | from_entries
  '';
  fixtures = {
    development = toolchain;
    deployment = deploymentToolchain;
    override = overridden;
  };
in
assert lazyModule.moduleId == "lazy";
assert toolchain.metadata.moduleIds == [ "fixture" "alias" ];
assert map (entry: entry.id) toolchain.metadata.resolvedModules == [ "fixture" "alias" ];
assert map (entry: entry.moduleId) toolchain.metadata.resolvedModules == [ "fixture" "fixture" ];
assert toolchain.moduleConfigs.alias == development.moduleConfig;
assert deploymentToolchain.moduleConfigs.fixture == deployment.moduleConfig;
assert deployment.moduleConfig.languageServers == { };
assert development.moduleConfig.env.MODE == "development";
assert deployment.moduleConfig.env.MODE == "deployment";
assert fails (mkToolchain { moduleIds = [ "missing" ]; }).outPath;
assert fails (mkToolchain { moduleIds = [ "fixture" "fixture" ]; }).outPath;
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
pkgs.runCommand "flake-toolchain-check"
{
  nativeBuildInputs = [ pkgs.jq ];
} ''
  test -f ${shellSmoke}
  test "$(readlink ${deploymentBundle}/alias)" = "${deployment}"
  jq -e --arg path "${deployment}" '.alias.path == $path' ${deploymentBundle}/etc/nixmodules/modules.json
  test -d ${toolchain}/shell/nix-support
  jq -e '.schemaVersion == 1 and .system == "x86_64-linux"
    and .moduleIds == ["fixture", "alias"] and .deployment == false
    and .resolvedModules[0].id == "fixture"
    and .resolvedModules[0].moduleId == "fixture"' ${toolchain}/metadata.json
  jq -e '.deployment == true and .moduleIds == ["fixture"]' ${deploymentToolchain}/metadata.json
  jq -S . ${development} > expected.json
  jq -S .alias ${toolchain}/modules.json > actual.json
  cmp expected.json actual.json
  jq -S . ${deployment} > expected.json
  jq -S .fixture ${deploymentToolchain}/modules.json > actual.json
  cmp expected.json actual.json
  grep -Fx ${runtime} ${closure}/store-paths
  grep -Fx ${ide} ${closure}/store-paths
  if grep -Fx ${pkgs.jq} ${closure}/store-paths; then
    echo "Toolchain includes a JSON encoder dependency"
    exit 1
  fi
  if grep -Fx ${ide} ${deploymentClosure}/store-paths; then
    echo "Deployment includes a development-only IDE dependency" >&2
    exit 1
  fi
  (
    export REPL_HOME="/tmp/project with spaces"
    export PATH="/original/path"
    source ${toolchain}/shell/nix-support/setup-hook
    test "$A_DEPENDENT" = "$REPL_HOME/base/child"
    test "$BRACED" = "$REPL_HOME/base/braced"
    test "$LITERAL" = ${lib.escapeShellArg definition.replit.env.LITERAL}
    test "$MODE" = development
    test "$PATH" = "$REPL_HOME/base/bin:${runtime}/bin:$REPL_HOME/base/bin:${runtime}/bin:/original/path"
  )
  (
    source ${deployment.shellPackage}/nix-support/setup-hook
    test "$MODE" = deployment
  )
  (
    source ${overridden}/shell/nix-support/setup-hook
    test "$MODE" = last
  )
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: fixture: ''
    mkdir -p "$out/${name}"
    cp ${fixture}/metadata.json "$out/${name}/metadata.json"
    cp ${fixture}/modules.json "$out/${name}/modules.json"
    cp ${pkgs.writeText "environment-input.json" (builtins.toJSON environmentInput)} "$out/${name}/environment-input.json"
    env -i ${environmentArgs} UNRELATED=not-exported \
      ${fixture}/bin/replit-toolchain-env > "$out/${name}/environment.env0"
    jq -RsS ${lib.escapeShellArg decodeEnvironment} "$out/${name}/environment.env0" \
      > "$out/${name}/environment.json"
    jq -e --arg literal ${lib.escapeShellArg definition.replit.env.LITERAL} '
      .REPL_HOME == "/tmp/project with spaces"
      and .A_DEPENDENT == "/tmp/project with spaces/base/child"
      and .BRACED == "/tmp/project with spaces/base/braced"
      and .PYTHONPATH == "/inherited/suffix"
      and .MISSING == ""
      and .EMPTY == ""
      and .MULTILINE == "first=line\nsecond=line"
      and .LITERAL == $literal
      and (has("UNRELATED") | not)
      and (has("HOME") | not)
    ' "$out/${name}/environment.json"
  '') fixtures)}
  jq -e --arg path "/tmp/project with spaces/base/bin:${runtime}/bin:/tmp/project with spaces/base/bin:${runtime}/bin:/original/path" \
    '.MODE == "development" and .PATH == $path' "$out/development/environment.json"
  jq -e --arg path "/tmp/project with spaces/base/bin:${runtime}/bin:/original/path" \
    '.MODE == "deployment" and .PATH == $path' "$out/deployment/environment.json"
  jq -e '.MODE == "last"' "$out/override/environment.json"
  env -i PATH="" ${toolchain}/bin/replit-toolchain-env \
    | jq -RsS ${lib.escapeShellArg decodeEnvironment} > fallback-environment.json
  jq -e --arg home "$PWD" '.REPL_HOME == $home and .PYTHONPATH == "/suffix"' fallback-environment.json
''

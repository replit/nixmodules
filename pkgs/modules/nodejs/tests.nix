{ pkgs, runtimes }:
pkgs.lib.listToAttrs (map
  (nodejs:
  let
    module = import ./. { inherit nodejs; } { inherit pkgs; inherit (pkgs) lib; };
    pnpm = pkgs.lib.findFirst (package: pkgs.lib.getName package == "pnpm")
      (throw "Node.js module must include pnpm")
      module.replit.packages;
    major = pkgs.lib.versions.major nodejs.version;
    name = "pnpm-nodejs-${major}";
  in
  pkgs.lib.nameValuePair name (pkgs.runCommand name { } ''
    export HOME="$TMPDIR/home"
    export PATH="${nodejs}/bin:$PATH"
    mkdir -p "$HOME" project
    cd project
    cat > package.json <<'EOF'
    {
      "name": "pnpm-runtime-check",
      "version": "1.0.0",
      "engines": { "node": ">=${nodejs.version} <${toString (pkgs.lib.toInt major + 1)}" }
    }
    EOF
    echo 'engine-strict=true' > .npmrc
    cat > "$TMPDIR/check-runtime.cjs" <<'EOF'
    const assert = require('node:assert/strict');
    const fs = require('node:fs');
    assert.equal(process.version, 'v${nodejs.version}');
    assert.equal(fs.realpathSync(process.execPath), fs.realpathSync('${nodejs}/bin/node'));
    fs.appendFileSync(process.env.RUNTIME_CHECK_LOG, process.version + '\n');
    EOF
    export RUNTIME_CHECK_LOG="$TMPDIR/runtime.log"
    export NODE_OPTIONS="--require=$TMPDIR/check-runtime.cjs"
    test "$(${pnpm}/bin/pnpm --version)" = "${pnpm.version}"
    ${pnpm}/bin/pnpm install --offline --ignore-scripts
    test "$(wc -l < "$RUNTIME_CHECK_LOG")" -ge 2
    cp "$RUNTIME_CHECK_LOG" "$out"
  ''))
  runtimes)

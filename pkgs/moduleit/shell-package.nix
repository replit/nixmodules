{ lib
, runCommand
, writeText
, name
, packages
, env
, passthru ? { }
}:
let
  variablePattern = "[a-zA-Z_][a-zA-Z0-9_]*";
  splitValue = value: builtins.split "[$]([{]${variablePattern}[}]|${variablePattern})" value;
  variableName = match: lib.removeSuffix "}" (lib.removePrefix "{" (builtins.head match));
  references = value: map variableName (builtins.filter builtins.isList (splitValue value));
  names = builtins.attrNames env;
  ordered = lib.toposort
    (a: b: a != b && builtins.elem a (references env.${b}))
    names;
  # Expand only environment references, never shell substitutions or operators.
  shellValue = value: lib.concatMapStrings
    (part:
      if builtins.isString part then lib.escapeShellArg part
      else "\"\${${variableName part}-}\"")
    (splitValue value);
  hook =
    assert lib.assertMsg
      (builtins.all (key: builtins.match variablePattern key != null) names)
      "Module environment keys must be shell variable names";
    assert lib.assertMsg (!(ordered ? cycle)) "Module environment contains a variable cycle";
    ''
      export REPL_HOME="''${REPL_HOME:-$PWD}"
    '' + lib.concatMapStringsSep "\n"
      (key: "export ${key}=${shellValue env.${key}}"
      + lib.optionalString (key == "PATH") "\${PATH:+:}\"$PATH\"")
      ordered.result + "\n";
in
runCommand name
{
  inherit passthru;
}
  ''
    mkdir -p "$out/nix-support"
    cp ${writeText "${name}-hook" hook} "$out/nix-support/setup-hook"
    # Keep runtime references without running their compiler build hooks.
    printf '%s\n' ${lib.escapeShellArg (lib.concatMapStringsSep "\n" toString packages)} \
      > "$out/nix-support/runtime-dependencies"
  ''

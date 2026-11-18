{ pkgs }:
{ modules ? [ ], packages ? [ ], shellHook ? "", name ? "replit-devshell" }:
let
  inherit (pkgs) lib;
  moduleHook = module:
    assert lib.assertMsg (lib.isDerivation module)
      "mkReplitShell: each modules element must be a module shell package derivation";
    ''
      source ${lib.escapeShellArg "${module}/nix-support/replit-env"}
    '';
  closure = map (entry: entry.pkg) (builtins.genericClosure {
    startSet = map (pkg: { key = toString pkg; inherit pkg; }) packages;
    operator = entry: map
      (pkg: { key = toString pkg; inherit pkg; })
      (entry.pkg.propagatedBuildInputs or [ ]);
  });
  dirs = output: suffix: lib.unique (map (pkg: "${output pkg}/${suffix}") closure);
  libDirs = dirs lib.getLib "lib";
  devDirs = dirs lib.getDev "include";
  pkgConfigDirs = lib.unique (dirs lib.getDev "lib/pkgconfig" ++ dirs lib.getLib "lib/pkgconfig");
  # Ordinary packages contribute directories only; their stdenv setup hooks never run.
  exportDirs = var: separator: prefix: paths: lib.optionalString (paths != [ ]) ''
    replit_shell_value=
    for replit_shell_dir in ${lib.escapeShellArgs paths}; do
      if [[ -d "$replit_shell_dir" ]]; then
        replit_shell_value+="''${replit_shell_value:+${separator}}${prefix}$replit_shell_dir"
      fi
    done
    if [[ -n "$replit_shell_value" ]]; then
      export ${var}="$replit_shell_value''${${var}:+${separator}}''${${var}-}"
    fi
    unset replit_shell_value replit_shell_dir
  '';
in
builtins.derivation {
  inherit name;
  outputs = [ "out" ];
  system = pkgs.stdenv.hostPlatform.system;
  builder = "${pkgs.bash}/bin/bash";
  args = [ "-c" ": > $out" ];
  SHELL = "${pkgs.bash}/bin/bash";
  # No PATH: the workspace runtime accepts a shell without one and ignores Nix's /path-not-set.
  shellHook = lib.concatMapStrings moduleHook (lib.reverseList modules)
    + exportDirs "PATH" ":" "" (dirs lib.getBin "bin")
    + exportDirs "REPLIT_LD_LIBRARY_PATH" ":" "" libDirs
    + exportDirs "LDFLAGS" " " "-L" libDirs
    + exportDirs "NIX_LDFLAGS" " " "-L" libDirs
    + exportDirs "PKG_CONFIG_PATH" ":" "" pkgConfigDirs
    + exportDirs "PKG_CONFIG_PATH_FOR_TARGET" ":" "" pkgConfigDirs
    + exportDirs "XDG_DATA_DIRS" ":" "" (dirs (lib.getOutput "out") "share")
    + exportDirs "CFLAGS" " " "-isystem " devDirs
    + exportDirs "NIX_CFLAGS_COMPILE" " " "-isystem " devDirs
    + exportDirs "GI_TYPELIB_PATH" ":" "" (dirs lib.getLib "lib/girepository-1.0")
    + shellHook;
}

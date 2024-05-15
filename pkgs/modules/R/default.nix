{ pkgs, lib, ... }:
let r-version = lib.versions.majorMinor pkgs.R.version;
in
{
  id = "r-${r-version}";
  name = "R Tools";
  displayVersion = r-version;
  description = ''
    R project for statistical computing.
  '';

  replit.runners.r = {
    name = "R";
    language = "r";

    start = "${pkgs.R}/bin/R -s -f $file";
    fileParam = true;
  };

  replit.dev.packagers.r = {
    name = "R";
    language = "r";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };

  replit.env = {
    R_LIBS_USER = "$REPL_HOME/.config/R";
  };
}

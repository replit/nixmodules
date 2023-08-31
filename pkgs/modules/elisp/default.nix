{ pkgs, replit-prompt, ... }:

let
  inherit (pkgs) emacs cask sqlite;
  prybar = pkgs.prybar.prybar-elisp;

  run-prybar-name = "run-prybar-elisp";
  run-prybar = pkgs.writeShellScriptBin run-prybar-name ''
    ${prybar}/bin/prybar-elisp -i \
      --ps1 "${replit-prompt}" \
      -c ";; Hint: To type M-x, use ESC x instead." \
      "$@"
  '';

  extensions = [ ".el" ];
in

{
  id = "elisp";
  name = "Emacs Lisp Tools";

  packages = [
    emacs
    cask
    sqlite
    prybar
    run-prybar
  ];

  replit.runners.prybar-elisp = {
    name = "Prybar for Emacs Lisp";
    inherit extensions;
    language = "elisp";
    optionalFileParam = true;
    interpreter = true;
    start = "${run-prybar}/bin/${run-prybar-name} $file";
  };

  replit.runners.elisp-script = {
    name = "Emacs Script";
    inherit extensions;
    language = "elisp";
    optionalFileParam = true;
    start = "emacs -nw -Q --script $file";
  };

  replit.packagers.upmElisp = {
    name = "UPM for Emacs Lisp";
    inherit extensions;
    language = "elisp";
    features = {
      packageSearch = true;
      guessImports = true;
    };
  };
}

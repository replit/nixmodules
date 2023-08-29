{ pkgs, ... }:

let 
  pypkgs = pkgs.python27Packages;
  python = pkgs.python27Full;

  inherit (import ./wrap.nix { inherit pkgs pypkgs python; }) wrapPython;

  python2-wrapped = wrapPython {
    name = "python2";
    bin = "${python}/bin/python2";
    aliases = [ "python" "python2.7" ];
  };
in

{
  id = "python2";
  name = "Python 2.7 (legacy)";

  packages = [
    python2-wrapped
  ];

  replit.runners.python = {
    name = "Python 2.7";
    fileParam = true;
    language = "python2";
    start = "${python2-wrapped}/bin/python2 $file";
  };
}

{ pkgs, ... }:

let
  inherit (pkgs.haskellPackages) unlambda;
in

{
  id = "unlambda";
  name = "Unlambda";

  packages = [
    unlambda
  ];

  replit.runners.unlambda = {
    name = "Unlambda interpreter";
    language = "unlambda";
    extensions = [ ".unl" ];
    fileParam = true;
    start = "cat $file | ${unlambda}/bin/unlambda";
  };
}

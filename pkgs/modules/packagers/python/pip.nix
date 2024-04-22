pkgs @ { pypkgs, ... }:

let
  pip = pypkgs.pip;

  config = pkgs.writeTextFile {
    name = "pip.conf";
    text = ''
      [global]
      user = yes
      disable-pip-version-check = yes
      break-system-packages = yes
    '';
  };
in
{
  inherit pip config;
}

{ php }:
{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor php.version;
in
{
  id = "php-${php-version}";
  name = "PHP Tools";

  imports = [
    (import ./base.nix {
      inherit php;
      inherit (pkgs) phpactor;
    })
  ];

  replit.runners.php = {
    name = "php run";
    language = "php";
    start = "${php}/bin/php $file";
    fileParam = true;
  };
}

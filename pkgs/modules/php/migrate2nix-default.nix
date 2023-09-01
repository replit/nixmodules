{ php }:
{ pkgs, lib, ... }:

let
  version = lib.versions.majorMinor php.version;
in

{
  id = "php-cli-${version}";
  name = "PHP ${version} CLI";

  imports = [
    (import ./base.nix {
      inherit php;
      inherit (pkgs) phpactor;
    })
  ];

  replit.runners.php = {
    name = "PHP";
    language = "php";
    fileParam = true;
    start = "${php}/bin/php -r \"$(cat $file)\"";
  };
}

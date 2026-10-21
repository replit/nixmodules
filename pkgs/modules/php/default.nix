{ php }:
{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor php.version;
  phpactor = pkgs.phpactor.override { inherit php; };
in
{
  id = "php-${php-version}";
  name = "PHP Tools";
  displayVersion = php-version;
  description = ''
    PHP development tools. Includes PHP: Hypertext Preprocessor, Phpactor language server, Composer package manager.
  '';

  replit.packages = [
    php
    php.packages.composer
  ];

  replit.runners.php = {
    name = "php run";
    language = "php";
    start = "${php}/bin/php $file";
    fileParam = true;
  };

  replit.dev.languageServers.phpactor = {
    name = "phpactor";
    language = "php";

    start = "${phpactor}/bin/phpactor language-server";
  };

  replit.dev.packagers.php = {
    name = "PHP Composer";
    language = "php";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

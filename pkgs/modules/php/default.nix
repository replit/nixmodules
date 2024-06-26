{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor pkgs.php.version;
in
{
  id = "php-${php-version}";
  name = "PHP Tools";
  displayVersion = php-version;
  description = ''
    PHP development tools. Includes PHP: Hypertext Preprocessor, Phpactor language server, Composer package manager.
  '';

  replit.packages = with pkgs; [
    php
    pkgs.phpPackages.composer
  ];

  replit.runners.php = {
    name = "php run";
    language = "php";
    start = "${pkgs.php}/bin/php $file";
    fileParam = true;
  };

  replit.dev.languageServers.phpactor = {
    name = "phpactor";
    language = "php";

    start = "${pkgs.phpactor}/bin/phpactor language-server";
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

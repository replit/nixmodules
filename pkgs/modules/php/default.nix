{ pkgs, lib, ... }:
let phpactor = pkgs.callPackage ../../phpactor { };
php-version = lib.versions.majorMinor pkgs.php.version;
in
{
  id = "php-${php-version}";
  name = "PHP Tools";

  packages = with pkgs; [
    php
    phpPackages.composer
  ];

  replit.runners.php = {
    name = "php run";
    language = "php";
    start = "${pkgs.php}/bin/php $file";
    fileParam = true;
  };

  replit.languageServers.phpactor = {
    name = "phpactor";
    language = "php";

    start = "${phpactor}/bin/phpactor language-server";
  };

  replit.packagers.php = {
    name = "PHP";
    language = "php";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

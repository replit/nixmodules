{ pkgs, pruneVersion, ... }:
let phpactor = pkgs.callPackage ../../phpactor { };
in
{
  id = "php";
  name = "PHP Tools";
  community-version = pruneVersion pkgs.php.version;
  version = "1.0";

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

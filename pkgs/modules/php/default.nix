{ php }:
{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor php.version;
  phpactor = pkgs.phpactor.override { inherit php; };
  composer = php.packages.composer.overrideAttrs (old: {
    src = pkgs.applyPatches {
      name = "composer-${old.version}-ca-bundle-1.6.0-source";
      src = old.src;
      patches = [ ../../composer/ca-bundle-1.6.0.patch ];
    };
    vendorHash = "sha256-OWut8wZ9nq/7EiZecdhc4RsDhFJ2xlx1iTCXuHk7x14=";
  });
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
    composer
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

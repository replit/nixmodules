{ php }:
{ pkgs, lib, ... }:
let
  php-version = lib.versions.majorMinor php.version;
  phpactor = pkgs.phpactor.override { inherit php; };
  composer-ca-bundle = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/composer/ca-bundle/1.6.0/res/cacert.pem";
    hash = "sha256-eW8Tib/qE8DtePZjt2W6r/VKUI5Ug3hr1uznPF4+PL4=";
  };
  composer = php.packages.composer.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      cp ${composer-ca-bundle} $out/share/php/composer/vendor/composer/ca-bundle/res/cacert.pem
    '';
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

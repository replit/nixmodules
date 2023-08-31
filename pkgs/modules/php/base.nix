{ php, phpactor }: {
  packages = [
    php
    phpactor
  ];

  replit.languageServers.phpactor = {
    name = "phpactor";
    language = "php";
    start = "${phpactor}/bin/phpactor language-server";
  };

  replit.packagers.php = {
    name = "PHP";
    language = "php";
    features.packageSearch = true;
  };
}

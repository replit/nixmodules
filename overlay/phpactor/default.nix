# can eventually be removed. See:
# https://github.com/NixOS/nixpkgs/pull/225054
{ lib, stdenvNoCC, fetchFromGitHub, php, channelName ? "nixpkgs-22.11" }:

let
  version = "2023.01.21";

  src = fetchFromGitHub {
    owner = "phpactor";
    repo = "phpactor";
    rev = version;
    hash = "sha256-jWZgBEaffjQ5wCStSEe+eIi7BJt6XAQFEjmq5wvW5V8=";
  };

  vendor = stdenvNoCC.mkDerivation rec {
    pname = "phpactor-vendor";
    inherit src version;


    # See https://github.com/NixOS/nix/issues/6660
    dontPatchShebangs = true;

    nativeBuildInputs = [
      php
    ];

    buildPhase = ''
      runHook preBuild

      substituteInPlace composer.json \
        --replace '"config": {' '"config": { "autoloader-suffix": "Phpactor",' \
        --replace '"name": "phpactor/phpactor",' '"name": "phpactor/phpactor", "version": "${version}",'
      ${php.packages.composer}/bin/composer install --no-interaction --optimize-autoloader --no-dev --no-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -ar ./vendor $out/

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # different channels have different versions of php/composer
    outputHash = {
      "nixpkgs-22.11" = "sha256-/MszCRJq1VUl2STGQZOrBlanKg7KHsdlVslWjTtsotA=";
      "nixpkgs-unstable" = "sha256-7R6nadWFv7A5Hv14D9egsTD/zcKK5uK9LQlHmwtbKdE=";
    }.${toString channelName} or "";
  };
in
stdenvNoCC.mkDerivation {
  pname = "phpactor";
  inherit src version;

  buildInputs = [
    php
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/php/phpactor $out/bin
    cp -r . $out/share/php/phpactor
    cp -r ${vendor}/vendor $out/share/php/phpactor
    ln -s $out/share/php/phpactor/bin/phpactor $out/bin/phpactor

    runHook postInstall
  '';

  meta = {
    description = "Mainly a PHP Language Server";
    homepage = "https://github.com/phpactor/phpactor";
    license = lib.licenses.mit;
    maintainers = lib.teams.php.members ++ [ lib.maintainers.ryantm ];
  };

}

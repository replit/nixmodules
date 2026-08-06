{ pkgs, lib, ... }:

let
  version = "0.64.0";

  # First release whose getCliConfig() supports Datadog. The wrapper resolves it
  # from $out/libexec/node_modules, so the module has to ship it.
  sdkVersion = "0.4.2";

  connectorsSdk = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@replit/connectors-sdk/-/connectors-sdk-${sdkVersion}.tgz";
    hash = "sha512-1FZsc7IWsvtogvTiWJod58cWmdebk5O7Qu5cbe3xp1CVSErmZxKmti5AIgMtKTcuCaFiGQ4JkKWDcPed69PRDg==";
  };

  # The wrapper and its tests share one store path so the test file can import
  # the module it exercises by relative path.
  wrapperSource = pkgs.runCommand "pup-wrapper-source" { } ''
    mkdir -p "$out"
    cp ${./pup-wrapper.mjs} "$out/pup-wrapper.mjs"
    cp ${./pup-wrapper.test.mjs} "$out/pup-wrapper.test.mjs"
  '';

  pup = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "pup";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/DataDog/pup/releases/download/v${finalAttrs.version}/pup_${finalAttrs.version}_Linux_x86_64.tar.gz";
      hash = "sha256-Qj03X+I6WaYzahcxw3128JwBbSfKhkndraehL5b3iok=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
      pkgs.nodejs_22
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 pup "$out/libexec/pup"
      install -Dm644 ${wrapperSource}/pup-wrapper.mjs "$out/libexec/pup-wrapper.mjs"

      sdkDir="$out/libexec/node_modules/@replit/connectors-sdk"
      mkdir -p "$sdkDir"
      tar \
        --extract \
        --gzip \
        --file ${connectorsSdk} \
        --strip-components=1 \
        --directory "$sdkDir"

      makeWrapper "${pkgs.nodejs_22}/bin/node" "$out/bin/pup" \
        --add-flags "$out/libexec/pup-wrapper.mjs" \
        --set PUP_REAL_BINARY "$out/libexec/pup"

      runHook postInstall
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck

      PUP_INSTALLED_WRAPPER="$out/libexec/pup-wrapper.mjs" \
        HOME="$TMPDIR" \
        node --test ${wrapperSource}/pup-wrapper.test.mjs
      HOME="$TMPDIR" "$out/bin/pup" --help >/dev/null

      runHook postInstallCheck
    '';

    meta = {
      description = "AI-agent-ready CLI for Datadog";
      homepage = "https://github.com/DataDog/pup";
      changelog = "https://github.com/DataDog/pup/releases/tag/v${finalAttrs.version}";
      license = lib.licenses.asl20;
      mainProgram = "pup";
      platforms = [ "x86_64-linux" ];
    };
  });
in
{
  id = "pup";
  name = "Pup CLI";
  displayVersion = version;
  description = "Pup provides an AI-agent-ready command-line interface to Datadog.";

  replit.packages = [ pup ];
}

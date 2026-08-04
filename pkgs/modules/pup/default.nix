{ pkgs, lib, ... }:

let
  version = "0.64.0";

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
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 pup "$out/libexec/pup"
      install -Dm644 ${./pup-wrapper.mjs} "$out/libexec/pup-wrapper.mjs"

      makeWrapper "${pkgs.nodejs_22}/bin/node" "$out/bin/pup" \
        --add-flags "$out/libexec/pup-wrapper.mjs" \
        --set PUP_REAL_BINARY "$out/libexec/pup"

      runHook postInstall
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck

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

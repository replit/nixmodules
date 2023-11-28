{ pkgs, lib, ... }:
let
  python = pkgs.python310Full;

  pypkgs = pkgs.python310Packages;

  pythonVersion = lib.versions.majorMinor python.version;

  pythonUtils = import ../../python-utils {
    inherit pkgs python pypkgs;
  };

  pythonWrapper = pythonUtils.pythonWrapper;

  prybar-python-version = lib.strings.concatStrings (lib.strings.splitString "." pythonVersion);

  stderred = pkgs.callPackage ../../stderred { };

  run-prybar-bin = pkgs.writeShellScriptBin "run-prybar" ''
    ${stderred}/bin/stderred -- ${pkgs.prybar."prybar-python${prybar-python-version}"}/bin/prybar-python${prybar-python-version} -q --ps1 "''$(printf '\u0001\u001b[33m\u0002\u0001\u001b[00m\u0002 ')" -i ''$1
  '';

  run-prybar = pythonWrapper { bin = "${run-prybar-bin}/bin/run-prybar"; name = "run-prybar"; };
in
{

  id = lib.mkForce "python-with-prybar-${pythonVersion}";

  name = lib.mkForce "Python ${pythonVersion} Tools (with Prybar)";

  imports = [
    (import ../python {
      inherit python pypkgs;
    })
  ];

  replit.packages = [
    run-prybar
  ];

  replit.runners = lib.mkForce {
    python-prybar = {
      name = "Prybar for Python ${pythonVersion}";
      optionalFileParam = true;
      language = "python3";
      start = "${run-prybar}/bin/run-prybar $file";
    };
  };
}

{ pkgs, python, pypkgs, debugpy ? pypkgs.debugpy }:

let
  pythonVersion = pkgs.lib.versions.majorMinor python.version;
in
pkgs.stdenv.mkDerivation {
  name = "dap-python";
  version = debugpy.version;
  propagatedBuildInputs = [
    (python.withPackages (_: [
      debugpy
    ]))
  ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ${./wrapper.py} $out/bin/dap-python
    chmod +x $out/bin/dap-python

    substituteInPlace $out/bin/dap-python \
        --replace "@python-bin@" "${python}/bin/python3" \
        --replace "@debugpy-path@" "${debugpy.out}/lib/python${pythonVersion}/site-packages"
  '';
}

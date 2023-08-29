{ pkgs, pypkgs, python }: 
rec {
  cppLibs = pkgs.stdenvNoCC.mkDerivation {
    name = "cpplibs";
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      cp ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++* $out/lib

      runHook postInstall
    '';
  };

  python-ld-library-path = pkgs.lib.makeLibraryPath ([
    # Needed for pandas / numpy
    cppLibs
    pkgs.zlib
    # Needed for matplotlib
    pkgs.xorg.libX11
    # Needed for pygame
    pkgs.glib
  ] ++ (with pkgs.xorg; [
    libXext
    libXinerama
    libXcursor
    libXrandr
    libXi
    libXxf86vm
  ]));

  wrapPython = { bin, name, aliases ? [] }:
    let
      ldLibraryPathConvertWrapper = pkgs.writeShellScriptBin name ''
        export LD_LIBRARY_PATH=''${PYTHON_LD_LIBRARY_PATH}
        exec "${bin}" "$@"
      '';

      linkBins = pkgs.lib.concatMapStringsSep "\n" (s: "ln -s $out/bin/${name} $out/bin/${s}");
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "${name}-wrapper";
      buildInputs = [ pkgs.makeWrapper ];

      buildCommand =
        ''
          mkdir -p $out/bin
          makeWrapper ${ldLibraryPathConvertWrapper}/bin/${name} $out/bin/${name} \
            --set-default PYTHON_LD_LIBRARY_PATH "${python-ld-library-path}" \
            --prefix PYTHONPATH : "${pypkgs.setuptools}/${python.sitePackages}"
          ${linkBins aliases}
        '';
  };
}

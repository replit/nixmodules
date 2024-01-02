{ pkgs, python, pypkgs }:
let
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
    pkgs.glib
    # Needed for matplotlib
    pkgs.xorg.libX11
    # Needed for pygame
  ] ++ (with pkgs.xorg; [ libXext libXinerama libXcursor libXrandr libXi libXxf86vm ]));

  pythonWrapper = { bin, name, aliases ? [ ] }:
    let
      # Always include the python-ld-library-path paths, but give them
      # the least precedence. Give the most precedence to
      # REPLIT_LD_LIBRARY_PATH.
      ldLibraryPathConvertWrapper = pkgs.writeShellApplication {
        inherit name;
        text = ''
          export LD_LIBRARY_PATH=${python-ld-library-path}
          if [ -n "''${PYTHON_LD_LIBRARY_PATH}" ]; then
            export LD_LIBRARY_PATH=''${PYTHON_LD_LIBRARY_PATH}:$LD_LIBRARY_PATH
          fi
          if [ -n "''${REPLIT_LD_LIBRARY_PATH}" ]; then
            export LD_LIBRARY_PATH=''${REPLIT_LD_LIBRARY_PATH}:$LD_LIBRARY_PATH
          fi
          exec "${bin}" "$@"
        '';
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "${name}-wrapper";
      buildInputs = [ pkgs.makeWrapper ];

      buildCommand = ''
        mkdir -p $out/bin
        makeWrapper ${ldLibraryPathConvertWrapper}/bin/${name} $out/bin/${name} \
          --prefix PYTHONPATH : "${pypkgs.setuptools}/${python.sitePackages}"
      '' + pkgs.lib.concatMapStringsSep "\n" (s: "ln -s $out/bin/${name} $out/bin/${s}") aliases;

    };
in
{
  inherit python-ld-library-path pythonWrapper;
}

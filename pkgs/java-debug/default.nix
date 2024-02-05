{ stdenv
, callPackage
, makeWrapper
, jdt-language-server
, python3
, jdk
}:
let
  debug-plugin = callPackage ./debug-plugin.nix {
    inherit jdk;
  };

in
stdenv.mkDerivation {
  name = "java-debug";
  version = debug-plugin.version;

  unpackPhase = "true";
  dontBuild = true;

  nativeBuildInputs = [ python3 ];
  buildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp ${./java-dap} $out/bin/java-dap
    patchShebangs $out/bin/java-dap

    makeWrapper $out/bin/java-dap $out/bin/java-debug \
      --add-flags --use-ephemeral-port \
      --add-flags --debug-plugin \
      --add-flags ${debug-plugin}/lib/java-debug.jar \
      --add-flags --language-server \
      --add-flags ${jdt-language-server}/bin/jdt-language-server
  '';
}

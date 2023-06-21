{ stdenv, runtimeShell }:
stdenv.mkDerivation {
  name = "moduleit";
  version = "2.0";
  src = ./.;

  installPhase = ''
    mkdir $out
    cp entrypoint.nix $out/
    cp module-definition.nix $out/
    cp moduleit.sh $out/
    mkdir $out/bin
    cat<<EOF > $out/bin/moduleit
    #!${runtimeShell}
    ${runtimeShell} $out/moduleit.sh "\$@"
    EOF
    chmod u+x $out/bin/moduleit
  '';

}

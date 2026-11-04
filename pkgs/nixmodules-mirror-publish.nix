{ writeShellApplication, mirrorInputs }:

writeShellApplication {
  name = "nixmodules-mirror-publish";
  derivationArgs.mirrorInputs = mirrorInputs;
  text = ''
    exec /run/current-system/sw/bin/nixmodules-mirror-publish "$@"
  '';
}

{ writeShellApplication }:

writeShellApplication {
  name = "nixmodules-mirror-publish";
  text = ''
    exec /run/current-system/sw/bin/nixmodules-mirror-publish "$@"
  '';
}

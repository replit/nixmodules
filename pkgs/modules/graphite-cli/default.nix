{ pkgs, lib, ... }:

let
  version = "1.7.4";
  graphite-cli = pkgs.stdenv.mkDerivation {
    pname = "graphite-cli";
    version = "1.7.4";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@withgraphite/graphite-cli/-/graphite-cli-1.7.4.tgz";
      hash = "sha256-srufROZk8DYzxDV0j6FhyD0afZ70rv7wUHS9TbGTopg=";
    };

    buildInputs = [ pkgs.nodejs ];

    installPhase = ''
      mkdir -p $out/lib/node_modules/@withgraphite/graphite-cli
      cp -r . $out/lib/node_modules/@withgraphite/graphite-cli
      chmod +x $out/lib/node_modules/@withgraphite/graphite-cli/graphite.js
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@withgraphite/graphite-cli/graphite.js $out/bin/gt
      ln -s $out/lib/node_modules/@withgraphite/graphite-cli/graphite.js $out/bin/graphite
    '';
  };
in
{
  id = "graphite-cli-${version}";
  name = "Graphite CLI";
  description = ''
    Graphite CLI is a command-line tool that helps developers manage stacked pull requests 
    (also called stacked diffs), making it easier to break large changes into smaller, 
    reviewable pieces that can be submitted and merged incrementally.
  '';
  displayVersion = version;

  imports = [
  ];

  replit.packages = [
    graphite-cli
  ];

}

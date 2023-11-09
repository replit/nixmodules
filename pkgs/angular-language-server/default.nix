{ lib, pkgs }:

let
  inherit (lib) mapAttrs;

  raw-node-packages = pkgs.callPackage ./create-node-packages.nix {};

  node-packages = mapAttrs
    (_: v: v.override { dontNpmInstall = true; })
    raw-node-packages;

in node-packages."@angular/language-server".override {
  nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/ngserver \
      --add-flags '--tsProbeLocations ${pkgs.typescript}/lib' \
      --add-flags '--ngProbeLocations ${node-packages."@angular/language-service"}/lib'
  '';

  meta = {
    mainProgram = "ngserver";
  };
}

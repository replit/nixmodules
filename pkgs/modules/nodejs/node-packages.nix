{ pkgs, nodejs }:
let
  typescript = pkgs.typescript.override {
    buildNpmPackage = pkgs.buildNpmPackage.override { inherit nodejs; };
  };
in
(pkgs.nodePackages.override { inherit nodejs; }) // {
  pnpm = pkgs.pnpm.override { inherit nodejs; };
  yarn = pkgs.yarn.override { inherit nodejs; };
  prettier = pkgs.prettier.override { inherit nodejs; };
  inherit typescript;
  typescript-language-server = pkgs.typescript-language-server.override {
    inherit nodejs typescript;
  };
}

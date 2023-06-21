{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=52e3e80afff4b16ccb7c52e9f0f5220552f03d04";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=87f9156865ab09e3bde39aadb4131ae364ae704e";
  inputs.prybar.url = "github:replit/prybar?rev=65f486534054665f1b333689417c39acd370d3a5";

  outputs = { self, nixpkgs, nixpkgs-unstable, prybar, ... }:
    let
      mkPkgs = pkgs: system: import pkgs {
        inherit system;
        overlays = [ self.overlays.default prybar.overlays.default ];
      };

      pkgs = mkPkgs nixpkgs "x86_64-linux";
      pkgs-unstable = mkPkgs nixpkgs-unstable "x86_64-linux";
    in
    {
      overlays.default = import ./overlay;

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;

      packages.x86_64-linux = import ./pkgs rec {
        inherit pkgs;

        all-modules = pkgs.lib.importJSON ./modules.json;
        revstring_long = self.rev or "dirty";
        revstring = builtins.substring 0 7 revstring_long;

        current-modules = import ./modules {
          inherit pkgs pkgs-unstable;
        };
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          python310
          pigz
          coreutils
          findutils
          lkl
          e2fsprogs
          gnutar
          gzip
        ];
      };
    };
}

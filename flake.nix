{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=52e3e80afff4b16ccb7c52e9f0f5220552f03d04";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=87f9156865ab09e3bde39aadb4131ae364ae704e";
  inputs.prybar.url = "github:replit/prybar?rev=65f486534054665f1b333689417c39acd370d3a5";

  outputs = { self, nixpkgs, nixpkgs-unstable, prybar, ... }:
    let
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default prybar.overlays.default ]; # ++ import ;
      };

      pkgs = mkPkgs "x86_64-linux";

      pkgs-unstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        overlays = [ self.overlays.default prybar.overlays.default ]; # ++ import ;
      };
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self;
      };
      hydraJobs = self.packages;
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
      modules = import ./pkgs/modules {
        inherit pkgs;
        inherit pkgs-unstable;
      };
    };
}

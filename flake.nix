{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.prybar.url = "github:replit/prybar?rev=65f486534054665f1b333689417c39acd370d3a5";

  outputs = { self, nixpkgs, nixpkgs-unstable, prybar, ... }:
    let
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [ self.overlays.default prybar.overlays.default ]; # ++ import ;
      };

      pkgs = mkPkgs nixpkgs "x86_64-linux";

      pkgs-unstable = mkPkgs nixpkgs-unstable "x86_64-linux";
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self;
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
      modules = import ./pkgs/modules {
        inherit pkgs;
        inherit pkgs-unstable;
      };
    };
}

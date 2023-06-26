{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.prybar.url = "github:replit/prybar";
  inputs.replbox.url = "github:replit/replbox";

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      mkPkgs = nixpkgs-spec: system: import nixpkgs-spec {
        inherit system;
        overlays = [
          self.overlays.default
          inputs.fenix.overlays.default
          inputs.prybar.overlays.default
          inputs.replbox.overlays.default
        ];
      };

      pkgs = mkPkgs nixpkgs "x86_64-linux";
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
      };
    };
}

{
  description = "Nix expressions for defining Replit development environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=52e3e80afff4b16ccb7c52e9f0f5220552f03d04";
  inputs.nixmodules-stable.url = "github:replit/nixmodules?rev=d77c07009d6d0e09eaf7aa011cad530a644eca01";
  inputs.prybar.url = "/home/toby/replit/prybar";

  outputs = { self, nixpkgs, nixmodules-stable, prybar, ... }:
    let
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default prybar.overlays.default ]; # ++ import ;
      };

      pkgs = mkPkgs "x86_64-linux";
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs {
        inherit pkgs self nixpkgs nixmodules-stable; 
      };
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = [
          pkgs.python310
        ];
      };
      modules = import ./pkgs/modules {
        inherit pkgs;
      };
    };
}

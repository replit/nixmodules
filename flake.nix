{
  description = "Replit's open-source nix expressions";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=52e3e80afff4b16ccb7c52e9f0f5220552f03d04";
  # inputs.nixpkgs-replit.url = "github:replit/nixpkgs-replit";
  # inputs.nixpkgs-replit.flake = false;

  outputs = { self, nixpkgs, ... }:
    let
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ]; # ++ import ;
      };
      pkgs = mkPkgs "x86_64-linux";
    in
    {
      overlays.default = final: prev: {
        moduleit = self.packages.${prev.system}.moduleit;
      };
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      packages.x86_64-linux = import ./pkgs { inherit pkgs self; };
      #checks.x86_64-linux.module-test = import ./test/module-test.nix { inherit pkgs; };
    };
}

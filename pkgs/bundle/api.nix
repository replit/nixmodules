{ pkgs, self }:
{ moduleIds ? null, deployment ? false }:
let
  modules = if deployment then self.deploymentModules else self.modules;
in
assert moduleIds == null || builtins.all
  (id: builtins.hasAttr id modules || throw "Unknown nixmodule: ${id}")
  moduleIds;
pkgs.callPackage ./default.nix { inherit self; } { inherit moduleIds deployment; }

{ pkgs, self }:
{ moduleIds
, deployment ? false
}:
let
  inherit (pkgs) lib;
  available = if deployment then self.deploymentModules else self.modules;
  selected = map
    (id: available.${id} or (throw "Unknown nixmodule: ${id}"))
    moduleIds;
  env = lib.foldl'
    (acc: module:
      let
        next = module.moduleConfig.env;
        paths = builtins.filter (path: path != "") [ (acc.PATH or "") (next.PATH or "") ];
      in
      acc // next // { PATH = lib.concatStringsSep ":" paths; })
    { }
    selected;
  shellPackage = pkgs.callPackage ../moduleit/shell-package.nix {
    name = "replit-toolchain-shell";
    inherit env;
    packages = lib.concatMap (module: module.runtimePackages) selected;
  };
  moduleConfigs = builtins.listToAttrs (lib.zipListsWith
    (id: module: { name = id; value = module.moduleConfig; })
    moduleIds
    selected);
  metadata = {
    schemaVersion = 1;
    system = pkgs.stdenv.hostPlatform.system;
    inherit moduleIds deployment;
    resolvedModules = lib.zipListsWith
      (id: module: {
        inherit id;
        moduleId = module.moduleId;
        modulePath = module.outPath;
        shellPath = module.shellPackage.outPath;
      })
      moduleIds
      selected;
  };
in
assert lib.assertMsg
  (builtins.isList moduleIds && builtins.all builtins.isString moduleIds)
  "moduleIds must be a list of strings";
assert lib.assertMsg
  (builtins.length moduleIds == builtins.length (lib.unique moduleIds))
  "Duplicate nixmodule IDs";
(pkgs.linkFarm "replit-toolchain" [
  { name = "modules.json"; path = pkgs.writeText "modules.json" (builtins.toJSON moduleConfigs); }
  { name = "metadata.json"; path = pkgs.writeText "metadata.json" (builtins.toJSON metadata); }
  { name = "shell"; path = shellPackage; }
]) // {
  inherit shellPackage moduleConfigs metadata;
}

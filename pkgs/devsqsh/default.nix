{ pkgs, self, revstring, module, module-name } :

with pkgs.lib;

let

  modules' = { "${module-name}" = module; };

  id = "${module-name}:v0-00000000-dirty";

  r = pkgs.writeText "registry" (builtins.toJSON {
    "${id}" = {
      commit = "dev";
      path = (builtins.unsafeDiscardStringContext module.outPath);
    };
  });

  am = import ../active-modules { inherit pkgs self; modules = modules'; registry = r; };

  bl = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { name = module-name; path = value; }) modules'
  );
in

pkgs.callPackage ../bundle-squashfs rec {
  revstring = "devsqh-${module-name}";
  registry = r;
  inherit (self.packages.${pkgs.system}) upgrade-maps;
  bundle-locked = bl;
  active-modules = am;
}

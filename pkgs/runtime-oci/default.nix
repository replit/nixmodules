{ pkgs, self, moduleIds, flakeOutput ? "node-python-runtime-oci" }:

let
  mkBundle = import ../bundle/api.nix { inherit pkgs self; };
  development = mkBundle { inherit moduleIds; };
  deployment = mkBundle { inherit moduleIds; deployment = true; };
  modules = map
    (id: {
      inherit id;
      developmentPath = self.modules.${id}.outPath;
      deploymentPath = self.deploymentModules.${id}.outPath;
    })
    moduleIds;
  roots = pkgs.lib.concatMap (module: [ module.developmentPath module.deploymentPath ]) modules;
  runtimeManifest = pkgs.runCommand "runtime-manifest.json"
    {
      nativeBuildInputs = [ pkgs.python3 ];
      __structuredAttrs = true;
      exportReferencesGraph.closure = roots;
      metadata = {
        schemaVersion = 1;
        kind = "nixmodules-runtime";
        system = pkgs.stdenv.hostPlatform.system;
        inherit flakeOutput moduleIds modules;
        source = {
          url = "https://github.com/replit/nixmodules";
          rev = self.rev or null;
          narHash = self.narHash or null;
          lockFileSha256 = builtins.hashFile "sha256" (self.outPath + "/flake.lock");
        };
      };
    }
    ''
      python3 ${./manifest.py} "$NIX_ATTRS_JSON_FILE" "$out"
    '';
  bundle = pkgs.linkFarm "node-python-runtime-bundle" [
    { name = "development"; path = development; }
    { name = "deployment"; path = deployment; }
    { name = "etc/nixmodules/modules.json"; path = "${development}/etc/nixmodules/modules.json"; }
    { name = "etc/nixmodules/deployment-modules.json"; path = "${deployment}/etc/nixmodules/modules.json"; }
    { name = "etc/nixmodules/runtime-manifest.json"; path = runtimeManifest; }
  ];
  image = pkgs.callPackage ../bundle-oci {
    inherit bundle flakeOutput;
    revision = self.rev or null;
    sourceTimestamp = self.lastModified or null;
  };
in
assert pkgs.lib.assertMsg
  (moduleIds != [ ] && builtins.length moduleIds == builtins.length (pkgs.lib.unique moduleIds))
  "Runtime OCI module IDs must be nonempty and unique";
image // { inherit runtimeManifest moduleIds; }

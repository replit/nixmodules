{ pkgs, self }:

let
  supportPolicy = builtins.fromJSON (builtins.readFile ./support-policy.json);
  inherit (supportPolicy) moduleIds;
  runtime = pkgs.writeText "runtime-oci-common" "runtime dependency";
  ide = pkgs.writeText "runtime-oci-ide" "development dependency";
  deploymentOnly = pkgs.writeText "runtime-oci-deployment" "deployment dependency";
  source = ../..;
  fixture = {
    outPath = source;
    rev = "0123456789abcdef0123456789abcdef01234567";
    narHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    lastModified = 1700000000;
    modules = builtins.listToAttrs (map
      (id: {
        name = id;
        value = (pkgs.writeText "replit-module-${id}" (builtins.toJSON {
          inherit id;
          runtime = "${runtime}";
          ide = "${ide}";
        })) // { moduleId = id; };
      })
      moduleIds);
    deploymentModules = builtins.listToAttrs (map
      (id: {
        name = id;
        value = (pkgs.writeText "replit-deployment-module-${id}" (builtins.toJSON {
          inherit id;
          runtime = "${runtime}";
          deploymentOnly = "${deploymentOnly}";
        })) // { moduleId = id; };
      })
      moduleIds);
  };
  mkAssembler = self: ids: pkgs.callPackage ./. {
    inherit self;
    supportPolicy = supportPolicy // { moduleIds = ids; };
  };
  assembler = mkAssembler fixture moduleIds;
  roots = map (id: fixture.modules.${id}) moduleIds
    ++ map (id: fixture.deploymentModules.${id}) moduleIds;
  closure = pkgs.closureInfo { rootPaths = roots; };
  cache = pkgs.mkBinaryCache { rootPaths = roots; compression = "xz"; };
  rejects = self: ids: !(builtins.tryEval (mkAssembler self ids).drvPath).success;
in
assert !(self.packages.x86_64-linux ? bundle-oci);
assert !(self.packages.x86_64-linux.node-python-runtime-oci ? copyTo);
assert self.packages.x86_64-linux.node-python-runtime-oci.moduleIds == moduleIds;
assert self.packages.x86_64-linux.node-python-runtime-oci.runtimeManifest.metadata.moduleIds == moduleIds;
assert assembler.moduleIds == assembler.runtimeManifest.metadata.supportPolicy.moduleIds;
assert (mkAssembler fixture [ "nodejs-22" ]).moduleIds == [ "nodejs-22" ];
assert rejects fixture [ "missing" ];
assert rejects fixture (moduleIds ++ [ "missing" ]);
assert rejects (fixture // { deploymentModules = builtins.removeAttrs fixture.deploymentModules [ "nodejs-24" ]; }) moduleIds;
assert rejects fixture [ ];
assert rejects fixture [ "nodejs-24" "nodejs-24" ];
assert rejects
  (fixture // {
    modules = fixture.modules // {
      nodejs-23 = fixture.modules.nodejs-24;
    };
    deploymentModules = fixture.deploymentModules // {
      nodejs-23 = fixture.deploymentModules.nodejs-24;
    };
  }) [ "nodejs-23" ];
pkgs.runCommand "runtime-oci-check"
{
  nativeBuildInputs = [ pkgs.python3 pkgs.skopeo ];
}
  ''
    ${assembler}/bin/assemble-node-python-runtime-oci --cache ${cache} --output "$PWD/image"
    python3 ${./check.py} "$PWD/image" ${assembler.runtimeManifest} ${cache} \
      ${closure}/store-paths ${runtime} ${ide} ${deploymentOnly} \
      ${assembler}/bin/assemble-node-python-runtime-oci ${source}/flake.lock
    skopeo --insecure-policy copy --preserve-digests \
      "oci:$PWD/image:bundle" "oci:$PWD/copied:bundle" \
      --authfile ${pkgs.writeText "runtime-empty-auth.json" ''{"auths":{}}''} \
      --digestfile "$PWD/copied.digest"
    python3 - "$PWD/image" "$PWD/copied" "$PWD/copied.digest" <<'PY'
    import json, pathlib, sys
    original, copied, digest_file = map(pathlib.Path, sys.argv[1:])
    descriptor = json.loads((original / "index.json").read_text())["manifests"][0]
    assert json.loads((copied / "index.json").read_text())["manifests"][0]["digest"] == descriptor["digest"]
    assert digest_file.read_text().strip() == descriptor["digest"]
    for blob in (original / "blobs/sha256").iterdir():
        assert blob.read_bytes() == (copied / "blobs/sha256" / blob.name).read_bytes()
    PY
    mkdir -p "$out"
    cp ${assembler.runtimeManifest} "$out/runtime-manifest.json"
  ''

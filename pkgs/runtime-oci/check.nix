{ pkgs }:

let
  moduleIds = [ "nodejs-24" "python-base-3.13" ];
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
        value = pkgs.writeText "replit-module-${id}" (builtins.toJSON {
          inherit id;
          runtime = "${runtime}";
          ide = "${ide}";
        });
      })
      moduleIds);
    deploymentModules = builtins.listToAttrs (map
      (id: {
        name = id;
        value = pkgs.writeText "replit-deployment-module-${id}" (builtins.toJSON {
          inherit id;
          runtime = "${runtime}";
          deploymentOnly = "${deploymentOnly}";
        });
      })
      moduleIds);
  };
  mkImage = self: ids: pkgs.callPackage ./. { inherit self; moduleIds = ids; };
  image = mkImage fixture moduleIds;
  roots = map (id: fixture.modules.${id}) moduleIds
    ++ map (id: fixture.deploymentModules.${id}) moduleIds;
  closure = pkgs.closureInfo { rootPaths = roots; };
  rejects = self: ids: !(builtins.tryEval (mkImage self ids).drvPath).success;
in
assert rejects fixture [ "missing" ];
assert rejects fixture (moduleIds ++ [ "missing" ]);
assert rejects (fixture // { deploymentModules = builtins.removeAttrs fixture.deploymentModules [ "nodejs-24" ]; }) moduleIds;
assert rejects fixture [ ];
assert rejects fixture [ "nodejs-24" "nodejs-24" ];
pkgs.runCommand "runtime-oci-check"
{
  nativeBuildInputs = [ pkgs.python3 pkgs.gnutar pkgs.gzip ];
}
  ''
    python3 ${./check.py} ${image} ${image.runtimeManifest} ${closure}/registration \
      ${runtime} ${ide} ${deploymentOnly} ${./manifest.py} ${source}/flake.lock
    ${image.copyTo}/bin/copy-nixmodules-bundle-oci "oci:$PWD/copied:bundle" \
      --authfile ${pkgs.writeText "runtime-empty-auth.json" ''{"auths":{}}''} \
      --digestfile "$PWD/copied.digest"
    python3 - ${image} "$PWD/copied" "$PWD/copied.digest" <<'PY'
    import json, pathlib, sys
    original, copied, digest_file = map(pathlib.Path, sys.argv[1:])
    descriptor = json.loads((original / "index.json").read_text())["manifests"][0]
    assert json.loads((copied / "index.json").read_text())["manifests"][0]["digest"] == descriptor["digest"]
    assert digest_file.read_text().strip() == descriptor["digest"]
    for blob in (original / "blobs/sha256").iterdir():
        assert blob.read_bytes() == (copied / "blobs/sha256" / blob.name).read_bytes()
    PY
    touch "$out"
  ''

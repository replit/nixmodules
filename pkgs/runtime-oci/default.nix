{ pkgs
, self
, supportPolicy ? builtins.fromJSON (builtins.readFile ./support-policy.json)
, flakeOutput ? "node-python-runtime-oci"
}:

let
  inherit (supportPolicy) moduleIds;
  modules = map
    (id: {
      inherit id;
      developmentPath = self.modules.${id}.outPath;
      deploymentPath = self.deploymentModules.${id}.outPath;
    })
    moduleIds;
  metadata = {
    schemaVersion = 2;
    kind = "nixmodules-runtime";
    system = pkgs.stdenv.hostPlatform.system;
    inherit flakeOutput moduleIds modules supportPolicy;
    payload = { format = "native-file-cache-v1"; cachePath = "/nix-cache"; };
    source = {
      url = "https://github.com/replit/nixmodules";
      rev = self.rev or null;
      narHash = self.narHash or null;
      lockFileSha256 = builtins.hashFile "sha256" (self.outPath + "/flake.lock");
    };
  };
  # These are audit paths, not inputs to the credential-free packaging tool.
  # The publisher realizes and verifies their closure before supplying cache bytes.
  runtimeManifest = (pkgs.writeText "runtime-manifest.json"
    (builtins.unsafeDiscardStringContext (builtins.toJSON metadata) + "\n")) // {
    inherit metadata;
  };
  layoutMetadata = builtins.toJSON {
    inherit flakeOutput;
    revision = self.rev or null;
    sourceTimestamp = self.lastModified or null;
    payloadFormat = metadata.payload.format;
  };
  assembler = pkgs.writeShellApplication {
    name = "assemble-node-python-runtime-oci";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./assemble.py} ${runtimeManifest} ${../bundle-oci/layout.py} \
        ${pkgs.lib.escapeShellArg (pkgs.lib.toLower pkgs.stdenv.hostPlatform.parsed.cpu.name)} \
        ${pkgs.lib.escapeShellArg layoutMetadata} "$@"
    '';
    meta.description = "Package a preverified signed Node/Python file cache as an OCI layout";
  };
in
assert pkgs.lib.assertMsg
  (moduleIds != [ ] && builtins.length moduleIds == builtins.length (pkgs.lib.unique moduleIds))
  "Runtime OCI module IDs must be nonempty and unique";
assert pkgs.lib.assertMsg
  (builtins.all
    (id:
    builtins.match "(nodejs-[0-9]+|python-base-[0-9]+\\.[0-9]+)" id != null
    && (self.modules.${id}.moduleId or "") == id
      && (self.deploymentModules.${id}.moduleId or "") == id)
    moduleIds)
  "Runtime OCI support policy must select canonical Node/Python-base modules";
assembler // { inherit runtimeManifest moduleIds supportPolicy; }

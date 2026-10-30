# Replit Nix Modules

This repository holds Replit's Nix modules.

* Each module is located as a folder under `pkgs/modules`
* `pkgs/modules/default.nix` registers every shipped implementation, some of which are parameterized with the version of the runtime or compiler
* Docker and Zig 0.11 remain compatibility-only implementations: included in the bundle but excluded from `activeModules` and `activeDeploymentModules`, as before

To list all active modules, you can do:

```
nix eval .#activeModules --json | jq
```
Output might look like:
```json
{
  "bun-0.5": "/nix/store/l08f5vl1af9rpzd7kvr0l5gx9v7y8p12-replit-module-bun-0.5",
  "c-clang14.0": "/nix/store/n4vzd9rkpjs72xj9yvlakxh3bardvdki-replit-module-c-clang14.0",
  "clojure-1.12": "/nix/store/69ai122m5grza3cm50l7ivb941av6ppb-replit-module-clojure-1.12",
  "cpp-clang14": "/nix/store/8iv4czda6j5nfhxs80ci625hj91ffpbn-replit-module-cpp-clang14",
  "dart-3.10": "/nix/store/3i16jlnmcwdhmwqg46p2hrkqfzm3zvg4-replit-module-dart-3.10",
  "dotnet-8.0": "/nix/store/dhrbdryqbkbyyi1wlnpvlwi28ni2hwcj-replit-module-dotnet-8.0",
  "go-1.25": "/nix/store/l76y8m5y19biid1wmqy03442lx9kairb-replit-module-go-1.25",
  ...
}
```

To list all modules (including compatibility implementations and retired-ID aliases):

```
nix eval .#modules --json | jq
```
### Supporting and retiring versions

Every shipped module implementation lives in this checkout. Module definitions
must not import outputs from an older nixmodules flake. Runtime packages can use
explicit, locked upstream inputs: Docker and Zig retain their previous toolchain
pins through `nixpkgs-docker`, `nixpkgs-zig`, and `zig-overlay`. Their definitions
use the current module schema; moving them here does not upgrade their runtimes.

When adding a version, prefer another registration of a parameterized module.
To keep an older version supported, retain its package pin and registration.
To retire an implementation, remove its registration and unused definition and
package inputs, then optionally add an upgrade alias for its old ID. An alias is
not a supported version of the old runtime. Removing the alias stops accepting
that ID in new bundles; neither operation changes previously published bundles.

Implementation IDs must be unique. Aliases must resolve to an implementation,
must not form cycles, and must not shadow an implementation. CI checks these
invariants and evaluates both development and deployment module maps.

Retired module IDs remain available through `pkgs/upgrade-map`: they resolve to
newer modules without keeping the retired implementations in the bundle.
For example, Haskell 9.0/9.2/9.4 resolve to 9.10, Python 3.8/3.9 to 3.10,
and Swift 5.6 to 5.8. The unversioned `swift` alias also resolves to 5.8.
The old Python and Node.js Prybar IDs now use the standard Python 3.10 and
Node.js 20 file runners, not Prybar. Projects using retired IDs get the newer
runtime and tools with this bundle and may need code or dependency changes.
The old `svelte-kit-node-20` ID resolves to `svelte-kit-node-24`, preserving
the Node.js 24 major that the SvelteKit module already used.

## Building

For each of the following examples, the build result will be found in a file or directory named `result`.

To build the full bundle, including compatibility modules (this will take a while, and a lot of disk space):

```
nix build .#bundle
```

To build only a few modules which you can control by editing the `dev-module-ids` list in `pkgs/default.nix`:

```
nix build .#custom-bundle
```

To build a specific module, for example `python-3.10`, you can do:

```
nix build .#'"python-3.10"'
```

To build a disk with only a few modules for development purposes:

```
nix build .#bundle-squashfs
```

or

```
nix build .#custom-bundle-squashfs
```

### Selected Node/Python runtime image

`node-python-runtime-oci` builds a credential-free packaging tool for an optional
native Nix file-cache image. The publisher supplies a preverified signed cache
containing the complete development and deployment closures of the selected
modules. It does not include a project workspace or install project packages.
The former full-image `bundle-oci` output and its `.copyTo` helper are removed.
The full non-OCI `bundle`, disk outputs and legacy per-module deployment OCI
builders remain available and unchanged.

The single source-owned selection is
[`support-policy.json`](pkgs/runtime-oci/support-policy.json). Reviewed on
2026-10-29, it selects the current packaged version of each available supported
line: `nodejs-22`, `nodejs-24`, `python-base-3.11`, `python-base-3.12` and
`python-base-3.13`. Each contributes development and deployment roots; native
Nix deduplicates shared paths. The full module packages are retained, including
their package managers, libraries and development dependencies.

Node 26 and Python 3.14/3.15 are supported upstream but are not implemented by
this module set. They are recorded as missing coverage, not silently substituted
or added as new runtime packages. Older project pins remain usable through signed
mirrors; this policy does not delete historical cache objects or change locks.

The policy uses the [Node release schedule](https://github.com/nodejs/Release/blob/main/schedule.json)
and Python release schedules [3.11](https://peps.python.org/pep-0664/),
[3.12](https://peps.python.org/pep-0693/) and [3.13](https://peps.python.org/pep-0719/).
Node 22 reaches EOL on 2027-04-30; the selected Python EOL dates are later and
specified only to month precision. Publication must reject a UTC date before
`reviewedOn` or on/after `publishBefore: "2027-04-30"`, and require exact agreement
between policy, module IDs and evaluated roots. Check before opening credentials,
before assembly and immediately before publication. Expiry requires a reviewed
source-policy update, not a mutable network lookup inside a derivation or an
automatic scheduler. Unreleased and EOL lines must not be added during that review.

Build the tool, then package an already verified signed cache:

```sh
nix build .#node-python-runtime-oci
./result/bin/assemble-node-python-runtime-oci \
  --cache ./verified-signed-cache --output ./runtime-image
```

The output directory must not exist. The assembler streams existing cache bytes
directly into one deterministic `application/vnd.oci.image.layer.v1.tar+gzip`
layer without another full cache copy, conversion of store paths to NARs, Nix
execution, signature generation or credential access. It rejects symlinks,
special files and unexpected paths. Structural packaging is **not signature
verification**; even an unsigned test cache can pass its structural checks.

The resulting OCI layout has reference `bundle`, Linux/amd64 and an empty image
config. It contains:

- `/nix-cache/nix-cache-info`, signed `*.narinfo` and `nar/*` bytes unchanged.
- Empty `nar`, `realisations`, `debuginfo` and `log` directories where needed so
  native Nix can open the mounted cache read-only.
- A regular `/etc/nixmodules/runtime-manifest.json` audit file, with no store symlink.

There is no raw `/nix/store`, registration database or duplicated module index.
Cache file modes are 0444, directories 0755, and UID/GID 11000. Tar timestamps
and gzip headers are fixed. OCI `created` metadata uses the source timestamp,
not assembly time. The OCI annotation
`dev.replit.nixmodules.payload-format` is `native-file-cache-v1`.
The manifest digest describes the compressed blob and the config diffID describes
the uncompressed tar stream.

The tool provides `.moduleIds`, `.supportPolicy` and `.runtimeManifest`.
Selection and policy can be evaluated without building runtimes. Building the
tool/manifest does not realize the audited roots: the publisher must independently
realize and verify the selected complete closure. `.runtimeManifest` is the exact
file copied into the image. The old runtime `.copyTo` is removed because the final
image is assembled outside a derivation from verified signed bytes. The publisher
uses its existing OCI copy tooling with `--preserve-digests` and TLS verification.

The runtime manifest has these fields:

- `schemaVersion: 2`, `kind: "nixmodules-runtime"`, `system: "x86_64-linux"` and
  `flakeOutput: "node-python-runtime-oci"`.
- `payload: { format: "native-file-cache-v1", cachePath: "/nix-cache" }`.
- `source`: `url`, clean Git `rev`, source `narHash` in SHA256 SRI format and
  `lockFileSha256` (lowercase hex). The lock hash is of this repository's
  `flake.lock`, not a consuming project's lockfile.
- `moduleIds` and `modules` in the policy's order; each module has `id`,
  `developmentPath` and `deploymentPath`.
- `supportPolicy`: `reviewedOn`, `publishBefore`, the same `moduleIds`, and
  `missingModuleIds` for known upstream-supported lines without packaged modules.

Native signed narinfos replace the old bespoke closure array/hash. The publisher
must use the existing approved mirror signing authority/exporter outside
derivations and verify the cache with native Nix before assembly. It must reject
missing source identity and bind the final OCI digest and exact runtime-manifest
hash in an approved external receipt. No newly synchronized GCS release is required.
This module adds neither a signing authority nor a publication workflow.

Readers use this only as an optional path-level `file://` cache, with native
signature checks enabled and no `trusted=true` or database-loading shortcut.
It is never a `/nix/store` lower or an authority for a project's runtime versions.
Missing paths fall through to signed mirrors/official caches; source revision,
module coverage and lifecycle metadata must not gate a project's existing pins.
Native import still consumes destination-store disk space. This format change
does not establish a runtime image size, preparation-time or peak-disk guarantee.

`nix build .#runtime-oci-check` uses a small unsigned native-cache fixture to test
byte preservation, variable roots, policy metadata, invalid filesystem entries,
deterministic assembly and digest-preserving local copying; it does not claim
signature acceptance. `nix build .#bundle-oci-check` retains shared-builder checks.

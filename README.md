# Replit Nix Modules

This repository holds Replit's Nix modules.

* Each module is located as a folder under `pkgs/modules`
* `pkgs/modules/default.nix` specifies a list of the active modules, some of which are parameterized with the version of the runtime or compiler

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

To list all modules (including historical modules):

```
nix eval .#modules --json | jq
```
This will take a while.

Retired module IDs remain available through `pkgs/upgrade-map`: they resolve to
newer modules without keeping the retired implementations in the bundle.
For example, Haskell 9.0/9.2/9.4 resolve to 9.10, Python 3.8/3.9 to 3.10,
and Swift 5.6 to 5.8. The unversioned `swift` alias also resolves to 5.8.
The old Python and Node.js Prybar IDs now use the standard Python 3.10 and
Node.js 20 file runners, not Prybar. Projects using retired IDs get the newer
runtime and tools with this bundle and may need code or dependency changes.

## Building

For each of the following examples, the build result will be found in a file or directory named `result`.

To build all active modules (this will take a while, and a lot of disk space):

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

To build the full bundle as an OCI image:

```
nix build .#bundle-oci
```

The result is an OCI image layout directory with the reference `bundle`. Copy
it with the helper, which keeps the image in its Nix closure and preserves its
manifest digest:

```
nix run .#bundle-oci.copyTo -- docker://REGISTRY/REPOSITORY:TAG --authfile ./auth.json --digestfile ./digest
```

The destination can use any Skopeo-supported transport. Additional arguments
are passed to `skopeo copy`. The helper trusts the locally built source
(`--insecure-policy`); registry TLS verification remains enabled. For a clean
Git source, the manifest records the full flake revision, source URL
`https://github.com/replit/nixmodules`, and output name `bundle-oci` in OCI
annotations. Creation metadata uses the flake's last-modified timestamp in UTC.
Local sources without revision or timestamp metadata omit those annotations.

The image contains one `application/vnd.oci.image.layer.v1.erofs+zstd` layer.
The layer descriptor's digest and size cover the zstd-compressed data; its
`dev.replit.erofs.uncompressed-size` annotation records the raw EROFS image
size. The config diffID is the SHA-256 digest of that raw image. The EROFS
filesystem has internal compression and inline data disabled, with the complete
bundle closure and `/etc/nixmodules` metadata.

This changes the existing `bundle-oci` format and is not backward-compatible
with consumers expecting a tar+gzip layer. Consumers must support this OCI
layer media type and EROFS; deploy that support before publishing images.

A small fixture exercises the producer without building the full bundle:

```
nix build .#bundle-oci-check
```

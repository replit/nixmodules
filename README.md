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

To build the full bundle as a gzip-compressed tar OCI image:

```
nix build .#bundle-oci
```

The result is an OCI image layout directory with the reference `bundle`, suitable
for copying with an OCI-layout-aware tool such as
`skopeo copy oci:./result:bundle docker://REGISTRY/REPOSITORY:TAG`.
The output also provides a copy helper that keeps the exact image in its Nix
closure and preserves the manifest digest:

```
nix run .#bundle-oci.copyTo -- docker://REGISTRY/REPOSITORY:TAG --authfile ./auth.json --digestfile ./digest
```

The destination can use any Skopeo-supported transport, including `oci:`.
Additional arguments are passed to `skopeo copy`. The helper trusts the locally
built source (`--insecure-policy`); registry TLS verification remains enabled.
For a clean Git source, the manifest records the full flake revision, source URL
`https://github.com/replit/nixmodules`, and output name `bundle-oci` in OCI
annotations. The manifest creation annotation and config `created` field use
the flake's last-modified timestamp in UTC, never the build's wall clock.
Local sources without a clean revision omit the revision annotation; sources
without a last-modified timestamp omit creation metadata. Publish from a
revision-pinned Git flake when complete provenance is required.

It contains one `application/vnd.oci.image.layer.v1.tar+gzip` layer. Gzip is
transport compression: the consumer decompresses it when unpacking the image.
The manifest describes the compressed blob's digest and size; the config's
diffID is the digest of the uncompressed tar stream. Tar entry order,
timestamps, ownership, extended headers and gzip headers are deterministic.

The filesystem is generated directly from the same pinned full bundle used by
`disk-script`: its complete store closure and `/etc/nixmodules` metadata, with
unchanged store paths, file contents, modes and symlink targets. All guest
UIDs/GIDs are 11000, matching the legacy disk builders. Existing disk and
per-module OCI builders are unchanged. There is no disk conversion or dependency
update. The tar archive preserves hardlinks and extended attributes. A consumer
that converts the tar to EROFS must leave filesystem compression disabled for
files to remain DAX-eligible. This uses more unpacked disk space than compressed
EROFS; it does not automatically share all guest memory.

A small fixture exercises the producer without building the full bundle:

```
nix build .#bundle-oci-check
```

## Optional EROFS OCI image

An opt-in image is available as `bundle-oci-erofs-zstd`; the existing
`bundle-oci` output remains the default and is unchanged. Build and copy it with:

```
nix build .#bundle-oci-erofs-zstd
nix run .#bundle-oci-erofs-zstd.copyTo -- docker://REGISTRY/REPOSITORY:TAG
```

This image has one `application/vnd.oci.image.layer.v1.erofs+zstd` layer.
Consumers must explicitly support this OCI layer media type and the EROFS
filesystem before using this output; generic OCI consumers may reject it. The
descriptor digest and size cover the zstd-compressed layer, while the config
diffID covers the raw EROFS image. The layer descriptor's
`dev.replit.erofs.uncompressed-size` annotation reports the raw image size in
bytes.
The filesystem is built without EROFS internal compression and with inline
data disabled.

The small fixture checks the image format and copy helper without building the
full bundle:

```
nix build .#bundle-oci-erofs-zstd-check
```

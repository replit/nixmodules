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
  "clojure-1.11": "/nix/store/giqq76fl3yphzsm6rkl1qxqh4mszknpl-replit-module-clojure-1.11",
  "cpp-clang14": "/nix/store/8iv4czda6j5nfhxs80ci625hj91ffpbn-replit-module-cpp-clang14",
  "dart-2.18": "/nix/store/mhl58f8y3z6jv0javkmx28y5h9aacw39-replit-module-dart-2.18",
  "dotnet-7.0": "/nix/store/06mjna44a7w9bby6r121a7i9a5027qqn-replit-module-dotnet-7.0",
  "go-1.19": "/nix/store/y1gb1k8bkyd9jqxi4r1g9qibcqn3c6dm-replit-module-go-1.19",
  ...
}
```

To list all modules (including historical modules):

```
nix eval .#modules --json | jq
```
This will take a while.


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

To build the full bundle (including historical modules) as a native EROFS OCI image:

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

It contains one uncompressed `application/vnd.oci.image.layer.v1.erofs` layer,
not a tar layer. The consumer must support native EROFS layers; ordinary
tar-only image unpackers cannot use it. Its diffID equals the layer blob digest.

The filesystem is generated directly from the same pinned full bundle used by
`disk-script`: its complete store closure and `/etc/nixmodules` metadata, with
unchanged store paths, file contents, modes and symlink targets. All guest
UIDs/GIDs are 11000, matching the legacy disk builders. Existing disk and
per-module OCI outputs are unchanged. There is no disk conversion or dependency
update. Uncompressed EROFS does not by itself guarantee DAX sharing; that also
depends on the consumer's backing storage and mount configuration.

A small fixture exercises the producer without building the full bundle:

```
nix build .#bundle-oci-check
```

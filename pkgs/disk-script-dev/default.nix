{ writeShellApplication
, bundle
, squashfsTools
, coreutils
, findutils
, storeRegistration
,
}:

writeShellApplication {
  name = "disk-script";
  runtimeInputs = [
    coreutils
    findutils
    squashfsTools
  ];
  text = ''
    set -x
    TMP_DIR=$(mktemp -d)

    cd "$TMP_DIR"

    root="$TMP_DIR/root"
    diskImage="$TMP_DIR/disk.sqsh"

    (
        mkdir -p "$root/nix/store" "$root/etc/nixmodules" "$root/nix-lower-registration/v1"

        cp --archive --reflink=auto "${bundle}/etc/nixmodules/"* "$root/etc/nixmodules"
        cp --archive --reflink=auto "${storeRegistration}/." "$root/nix-lower-registration/v1/"

        SECONDS=0
        xargs -P "$(nproc)" cp -a --reflink=auto -t "$root/nix/store/" < "${storeRegistration}/store-paths"
        echo "xargs copy took $SECONDS seconds" >&2

        echo "making squashfs..."
        SECONDS=0
        mksquashfs "$root" "$diskImage" -force-uid 11000 -force-gid 11000 -comp lz4 -b 1M
        echo "mksquashfs took $SECONDS seconds" >&2

    ) 1>&2

    echo "$diskImage"
  '';
}

. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"
bundleImage="$PWD/disk"
"${env[imageBuilder]}" "$bundleImage"

echo "making tarball..."
mkdir -p "$out"
tar --use-compress-program=pigz -Scf "$out/disk.raw.tar.gz" -C "$bundleImage" disk.raw

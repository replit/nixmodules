. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"
bundleImage="${env[bundle-image]}"

echo "making tarball..."
mkdir -p "$out"
tar --use-compress-program=pigz -Scf $out/disk.raw.tar.gz -C ${bundleImage} disk.raw

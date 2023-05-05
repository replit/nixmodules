out=build
root=$out/root
blockSize=$(( 4 * 1024 ))
label=nixmodules
registry=modules.json
linkfarm=$out/linkfarm
diskImage=$out/disk.raw

gibibyte=$(( 1024 * 1024 * 1024))
# Approximative percentage of reserved space in an ext4 fs over 512MiB.
# 0.05208587646484375
#  × 1000, integer part: 52
compute_fudge() {
  echo $(( $1 * 52 / 1000 ))
}

# Given lines of numbers, adds them together
sum_lines() {
  local acc=0
  while read -r number; do
    acc=$((acc+number))
  done
  echo "$acc"
}

chmod u+w -R $root
rm -fr $root
mkdir -p $root/nix/store $root/etc/nixmodules

nix-store -q --requisites $linkfarm/* | xargs -I % cp -a --reflink=auto % $root/nix/store/

cp -a --reflink=auto "${registry}" $root/etc/nixmodules/beta-registry.json

# Compute required space in filesystem blocks
diskUsage=$(find . ! -type d -print0 | du --files0-from=- --apparent-size --block-size "${blockSize}" | cut -f1 | sum_lines)
# Each inode takes space!
numInodes=$(find . | wc -l)
# Convert to bytes, inodes take two blocks each!
diskUsage=$(( (diskUsage + 2 * numInodes) * ${blockSize} ))
# Then increase the required space to account for the reserved blocks.
fudge=$(compute_fudge $diskUsage)
requiredFilesystemSpace=$(( diskUsage + fudge ))

diskSize=$(( requiredFilesystemSpace ))

# Round up to the nearest gibibyte.
if (( diskSize % gibibyte )); then
diskSize=$(( ( diskSize / gibibyte + 1) * gibibyte ))
fi

truncate -s "$diskSize" $diskImage

printf "Automatic disk size...\n"
printf "  Closure space use: %d bytes\n" $diskUsage
printf "  fudge: %d bytes\n" $fudge
printf "  Filesystem size needed: %d bytes\n" $requiredFilesystemSpace
printf "  Disk image size: %d bytes\n" $diskSize

echo "making filesystem..."

mkfs.ext4 -b ${blockSize} -F -L ${label} $diskImage

echo "copying to image..."
cptofs -p \
        -t ext4 \
        -i $diskImage \
        $root/* / ||
  (echo >&2 "ERROR: cptofs failed. diskSize might be too small for closure."; exit 1)

echo "making tarball..."
tar --use-compress-program=pigz -Scf $out/disk.raw.tar.gz $diskImage
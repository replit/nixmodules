{runCommand, lib, bundle, bundle-stable, registry, registry-stable, revstring, lkl, coreutils, findutils, e2fsprogs, gnutar, gzip, closureInfo } :

let
  blockSize = toString (4 * 1024); # ext4fs block size (not block device sector size)

  binPath = lib.makeBinPath [
    coreutils
    findutils
    lkl
    e2fsprogs
    gnutar
    gzip
  ];

  label = "nixmodules-${revstring}";

  diskClosureInfo = closureInfo { rootPaths = [bundle bundle-stable]; };

in

runCommand label {} ''
  export PATH=${binPath}

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

  mkdir $out

  root="$PWD/root"
  mkdir -p $root/nix/store $root/etc/nixmodules

  xargs -I % cp -a --reflink=auto % $root/nix/store/ < ${diskClosureInfo}/store-paths

  cp -a --reflink=auto ${registry} $root/etc/nixmodules/beta-registry.json
  cp -a --reflink=auto ${registry-stable} $root/etc/nixmodules/stable-registry.json

  diskImage=disk.raw

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

  echo "moving image to out..."
  mv $diskImage $out/disk.raw
''

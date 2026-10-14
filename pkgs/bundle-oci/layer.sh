set -euo pipefail

export LC_ALL=C
tar --create --format=pax --sort=name --mtime=@1 \
  --owner=11000 --group=11000 --numeric-owner \
  --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
  --xattrs --xattrs-include='*' \
  --directory="$1" . | gzip --no-name -9 > "$2"

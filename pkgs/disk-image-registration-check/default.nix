{ coreutils
, diffutils
, findutils
, gawk
, nix
, runCommand
, squashfsTools
, productionImage
, productionBundle
, developmentImage
, developmentBundle
}:

runCommand "nixmodules-disk-image-registration-check" {
  nativeBuildInputs = [
    coreutils
    diffutils
    findutils
    gawk
    nix
    squashfsTools
  ];
} ''
  validate_metadata() {
    local root="$1"
    local artifact="$2"
    local name="$3"
    local expected="$TMPDIR/expected-$name"
    local registration_index="$TMPDIR/registration-index-$name"
    local image_paths="$TMPDIR/image-paths-$name"
    local registered_paths="$TMPDIR/registered-paths-$name"

    test -f "$artifact/format-version" || return 1
    test "$(cat "$artifact/format-version")" = 1 || return 1
    test -f "$artifact/registration" || return 1
    test -f "$artifact/store-paths" || return 1
    test -f "$artifact/SHA256SUMS" || return 1
    (cd "$artifact" && sha256sum -c SHA256SUMS) || return 1

    LC_ALL=C sort -u "$artifact/store-paths" > "$expected"
    find "$root/nix/store" -mindepth 1 -maxdepth 1 -printf '/nix/store/%f\n' | LC_ALL=C sort > "$image_paths"
    cmp "$expected" "$image_paths" || return 1
    while IFS= read -r path; do
      test -e "$root$path" || return 1
    done < "$expected"

    gawk '
      state == 0 { entry = $0; print entry; state = 1; next }
      state == 1 { state = 2; next }
      state == 2 { state = 3; next }
      state == 3 { state = 4; next }
      state == 4 {
        if ($0 !~ /^[0-9]+$/) exit 1
        remaining = $0 + 0
        state = remaining == 0 ? 0 : 5
        next
      }
      state == 5 {
        print entry "\t" $0
        remaining--
        if (remaining == 0) state = 0
      }
      END { if (state != 0) exit 1 }
    ' "$artifact/registration" > "$registration_index" || return 1
    awk -F '\t' 'NR == FNR { paths[$0] = 1; next } NF == 1 { if (!($0 in paths)) exit 1; next } !($1 in paths) || !($2 in paths) { exit 1 }' \
      "$expected" "$registration_index" || return 1
    awk -F '\t' 'NF == 1 { print }' "$registration_index" | LC_ALL=C sort > "$registered_paths"
    cmp "$expected" "$registered_paths" || return 1
  }

  check_image() {
    local image="$1"
    local bundle="$2"
    local name="$3"
    local root="$TMPDIR/root-$name"
    local scratch="$TMPDIR/store-$name"
    local store="local?root=$scratch"
    local artifact="$root/nix-lower-registration/v1"
    local testdir="$TMPDIR/metadata-tests-$name"

    unsquashfs -no-progress -d "$root" "$image" >/dev/null
    validate_metadata "$root" "$artifact" "$name"
    mkdir -p "$testdir"

    cp -a "$artifact" "$testdir/artifact-missing-version"
    chmod -R u+w "$testdir/artifact-missing-version"
    rm "$testdir/artifact-missing-version/format-version"
    if validate_metadata "$root" "$testdir/artifact-missing-version" "$name-missing-version" >/dev/null 2>&1; then
      echo "missing format version was not rejected" >&2
      exit 1
    fi
    if test -f "$scratch/nix/var/nix/db"; then
      echo "invalid metadata created a scratch database" >&2
      exit 1
    fi

    cp -a "$artifact" "$testdir/artifact-unknown-version"
    chmod -R u+w "$testdir/artifact-unknown-version"
    printf '999\n' > "$testdir/artifact-unknown-version/format-version"
    (cd "$testdir/artifact-unknown-version" && sha256sum format-version registration store-paths > SHA256SUMS)
    if validate_metadata "$root" "$testdir/artifact-unknown-version" "$name-unknown-version" >/dev/null 2>&1; then
      echo "unknown format version was not rejected" >&2
      exit 1
    fi

    cp -a "$artifact" "$testdir/artifact-digest-mismatch"
    chmod -R u+w "$testdir/artifact-digest-mismatch"
    printf '\n' >> "$testdir/artifact-digest-mismatch/registration"
    if validate_metadata "$root" "$testdir/artifact-digest-mismatch" "$name-digest-mismatch" >/dev/null 2>&1; then
      echo "registration tampering passed the integrity check" >&2
      exit 1
    fi

    cp -a "$artifact" "$testdir/artifact-nonclosed"
    chmod -R u+w "$testdir/artifact-nonclosed"
    gawk '
      state == 0 { state = 1; next }
      state == 1 { state = 2; next }
      state == 2 { state = 3; next }
      state == 3 { state = 4; next }
      state == 4 { remaining = $0 + 0; state = remaining == 0 ? 0 : 5; next }
      state == 5 {
        if (!changed) {
          print "/nix/store/not-in-registration"
          changed = 1
        } else print
        remaining--
        if (remaining == 0) state = 0
      }
      END { if (!changed || state != 0) exit 1 }
    ' "$artifact/registration" > "$testdir/artifact-nonclosed/registration"
    (cd "$testdir/artifact-nonclosed" && sha256sum format-version registration store-paths > SHA256SUMS)
    if validate_metadata "$root" "$testdir/artifact-nonclosed" "$name-nonclosed" >/dev/null 2>&1; then
      echo "non-closed registration reference was not rejected" >&2
      exit 1
    fi

    cp -R "$root" "$testdir/root-missing-path"
    chmod -R u+w "$testdir/root-missing-path/nix/store"
    rm -rf "$testdir/root-missing-path/nix/store/$(basename "$bundle")"
    if validate_metadata "$testdir/root-missing-path" "$testdir/root-missing-path/nix-lower-registration/v1" "$name-missing-path" >/dev/null 2>&1; then
      echo "missing image path was not rejected" >&2
      exit 1
    fi

    mkdir -p "$scratch/nix/store"
    cp -R "$root/nix/store/." "$scratch/nix/store/"
    if nix-store --store "$store" --query --references "$bundle" > "$TMPDIR/valid-before-$name" 2>&1; then
      echo "scratch store was not empty before registration import" >&2
      exit 1
    fi
    nix-store --store "$store" --load-db < "$artifact/registration"
    while IFS= read -r path; do
      nix-store --store "$store" --query --references "$path" >/dev/null
    done < "$TMPDIR/expected-$name"
    nix-store --store "$store" --verify-path "$bundle"
    nix-store --store "$store" --query --references "$bundle" > "$TMPDIR/references-$name"
    test -s "$TMPDIR/references-$name"
    while IFS= read -r path; do
      grep -Fxq "$path" "$TMPDIR/expected-$name"
      nix-store --store "$store" --verify-path "$path"
    done < "$TMPDIR/references-$name"

    file="$(find "$scratch$bundle" -type f -print -quit)"
    chmod u+w "$file"
    printf tampered >> "$file"
    if nix-store --store "$store" --verify-path "$bundle" >/dev/null 2>&1; then
      echo "store content tampering passed Nix path verification" >&2
      exit 1
    fi
  }

  check_image ${productionImage}/disk.raw ${productionBundle} production
  check_image ${developmentImage}/disk.sqsh ${developmentBundle} development
  touch "$out"
''

. .attrs.sh
export PATH="${env[PATH]}"
out="${outputs[out]}"
mkdir -p root/nix/store root/etc/nixmodules "$out/blobs/sha256"
cp -a --reflink=auto "${env[bundle]}/etc/nixmodules/." root/etc/nixmodules/
while IFS= read -r path; do
  cp -a --reflink=auto "$path" root/nix/store/
done < "${env[bundleClosure]}/store-paths"
chmod 755 root root/nix root/nix/store root/etc root/etc/nixmodules
bash "${env[layerScript]}" root layer.tar.gz
python3 "${env[layoutScript]}" layer.tar.gz "$out" "${env[architecture]}" "${env[metadata]}"

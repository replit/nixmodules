set -eou pipefail
. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"
mkdir $out

mkdir image
echo '{"imageLayoutVersion": "1.0.0"}' > ${out}/oci-layout

tar -Pcpf ${out}/layer.tar --hard-dereference --sort=name --mtime="1970-01-01T00:00:01Z" \
  --owner=0 --group=0 --verbatim-files-from --files-from "${env[diskClosureInfo]}"/store-paths

DIFFID=$(sha256sum ${out}/layer.tar | cut -f -1 -d ' ')
pigz ${out}/layer.tar
LAYER_DIGEST=$(sha256sum ${out}/layer.tar.gz | cut -f -1 -d ' ')
cat ${out}/layer.tar.gz | ztoc > ${out}/ztoc
ZTOC_DIGEST=$(sha256sum ${out}/ztoc | cut -f -1 -d ' ')

LAYER_SIZE=$(stat --printf='%s' ${out}/layer.tar.gz)
ZTOC_SIZE=$(stat --printf='%s' ${out}/ztoc)

mkdir -p ${out}/blobs/sha256/
mv ${out}/layer.tar.gz "${out}/blobs/sha256/${LAYER_DIGEST}"
mv ${out}/ztoc "${out}/blobs/sha256/${ZTOC_DIGEST}"

## Phony Image

echo '{}' > ${out}/config.json
CONFIG_DIGEST=$(sha256sum ${out}/config.json | cut -f -1 -d ' ')
CONFIG_SIZE=$(stat --printf='%s' ${out}/config.json)
mv "${out}/config.json" "${out}/blobs/sha256/${CONFIG_DIGEST}"

cat <<EOF > ${out}/manifest.json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.example+type",
  "config": {
    "mediaType": "application/vnd.oci.empty.v1+json",
    "digest": "sha256:${CONFIG_DIGEST}",
    "size": ${CONFIG_SIZE}
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:${LAYER_DIGEST}",
      "size": ${LAYER_SIZE},
      "annotations": {
        "com.replit.diffid": "${DIFFID}"
      }
    },
    {
      "mediaType": "application/octet-stream",
      "digest": "sha256:${ZTOC_DIGEST}",
      "size": ${ZTOC_SIZE}
    }
  ]
}
EOF
MANIFEST_DIGEST=$(sha256sum ${out}/manifest.json | cut -f -1 -d ' ')
MANIFEST_SIZE=$(stat --printf='%s' ${out}/manifest.json)
mv "${out}/manifest.json" "${out}/blobs/sha256/${MANIFEST_DIGEST}"

cat <<EOF > ${out}/index.json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "artifactType": "application/vnd.example+type",
      "digest": "sha256:${MANIFEST_DIGEST}",
      "size": ${MANIFEST_SIZE},
      "annotations": {
        "org.opencontainers.image.ref.name": "${env[MODULE_ID]}"
      }
    }
  ]
}
EOF

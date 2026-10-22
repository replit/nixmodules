{ pip, fetchurl }:
let
  ca-bundle = fetchurl {
    url = "https://raw.githubusercontent.com/certifi/python-certifi/2026.10.19/certifi/cacert.pem";
    hash = "sha256-UPefmNrBkrINv3PzXFbwsMVXqyZ/9RmdERfMEYC3B4U=";
  };
in
pip.overridePythonAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    cp ${ca-bundle} src/pip/_vendor/certifi/cacert.pem
  '';
})

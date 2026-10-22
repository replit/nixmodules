{
  systems = [ "x86_64-linux" ];
  onlyBuild = [
    "checks.x86_64-linux.format"
    "checks.x86_64-linux.evaluation"
    "checks.x86_64-linux.bundle-oci"
    "devShells.x86_64-linux.default"
  ];
}

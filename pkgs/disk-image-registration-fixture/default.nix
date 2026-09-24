{ pkgs }:

let
  referencedPath = pkgs.writeText "nixmodules-registration-fixture-reference" "fixture reference\n";
  bundle = pkgs.runCommand "nixmodules-registration-fixture-bundle"
    {
      inherit referencedPath;
    } ''
    mkdir -p "$out/etc/nixmodules"
    printf '%s\n' "$referencedPath" > "$out/etc/nixmodules/reference"
  '';
  storeRegistration = (pkgs.callPackage ../store-registration { }) {
    rootPaths = [ bundle ];
  };
  image = diskName: pkgs.callPackage ../bundle-image {
    inherit bundle storeRegistration diskName;
    revstring = "registration-fixture";
  };
in
pkgs.callPackage ../disk-image-registration-check {
  productionImage = image "disk.raw";
  productionBundle = bundle;
  developmentImage = image "disk.sqsh";
  developmentBundle = bundle;
}

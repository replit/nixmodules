{ pkgs, ... }:
{
  id = "gcloud";
  name = "Google Cloud Tools";
  packages = [
    pkgs.google-cloud-sdk
  ];
}

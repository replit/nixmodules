{ pkgs, ... }:
{
  id = "gcloud";
  name = "Google Cloud Tools";
  replit.packages = [
    pkgs.google-cloud-sdk
  ];
}

{ pkgs, ... }:
{
  id = "gcloud";
  name = "Google Cloud Tools";
  displayVersion = pkgs.lib.versions.majorMinor pkgs.google-cloud-sdk.version;
  description = ''
    Google Cloud developer tools:
    All of the tools developers and development teams need to be productive
    when writing, deploying, and debugging applications hosted in Google Cloud.
  '';
  replit.packages = [
    pkgs.google-cloud-sdk
  ];
}

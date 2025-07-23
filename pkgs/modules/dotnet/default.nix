{ dotnet }:
{ pkgs, lib, ... }:

let
  dotnetVersion = lib.versions.major dotnet.version;

  extensions = [ ".cs" ".csproj" ".fs" ".fsproj" ];

  dotnet-version = lib.versions.majorMinor dotnet.version;
in

{
  id = "dotnet-${dotnet-version}";
  name = ".NET ${dotnet-version} Tools";
  displayVersion = dotnet-version;
  description = ''
    .NET ${dotnetVersion} development tools. Includes .NET and OmniSharp.
  '';

  replit.packages = [
    dotnet
  ];

  replit.runners.dotnet = {
    inherit extensions;
    name = ".NET";
    language = "dotnet";

    start = "${dotnet}/bin/dotnet run";
  };

  replit.dev.languageServers.omni-sharp = {
    inherit extensions;
    name = "OmniSharp";
    language = "dotnet";

    start = "${pkgs.omnisharp-roslyn}/bin/OmniSharp --languageserver";
  };

  replit.dev.packagers.dotnet = {
    name = ".NET packager";
    language = "dotnet";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

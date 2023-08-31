{ dotnet }:
{ pkgs, lib, ... }:

let
  extensions = [ ".cs" ".csproj" ".fs" ".fsproj" ];

  dotnet-version = lib.versions.majorMinor dotnet.version;
in

{
  id = "dotnet-${dotnet-version}";
  name = ".NET 7 Tools";

  packages = [
    dotnet
  ];

  replit.runners.dotnet = {
    inherit extensions;
    name = ".NET";
    language = "dotnet";

    start = "${dotnet}/bin/dotnet run";
  };

  replit.languageServers.omni-sharp = {
    inherit extensions;
    name = "OmniSharp";
    language = "dotnet";

    start = "${pkgs.omnisharp-roslyn}/bin/OmniSharp --languageserver";
  };

  replit.packagers.dotnet = {
    name = ".NET";
    language = "dotnet";
    features = {
      packageSearch = true;
      guessImports = false;
      enabledForHosting = false;
    };
  };
}

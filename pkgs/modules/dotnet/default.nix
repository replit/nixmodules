{ pkgs, lib, ... }:

let
  dotnet = pkgs.dotnet-sdk_8;

  extensions = [ ".cs" ".csproj" ".fs" ".fsproj" ];

  dotnet-version = lib.versions.majorMinor dotnet.version;
in

{
  id = "dotnet-${dotnet-version}";
  name = ".NET 8 Tools";
  displayVersion = dotnet-version;
  description = ''
    .NET 8 development tools. Includes .NET and OmniSharp.
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

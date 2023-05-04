{ pkgs, pruneVersion, ... }:

let
  dotnet = pkgs.dotnet-sdk_7;

  extensions = [ ".cs" ".csproj" ".fs" ".fsproj" ];
in

{
  id = "dotnet";
  name = ".NET 7 Tools";
  community-version = pruneVersion dotnet.version;
  version = "1.0";

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

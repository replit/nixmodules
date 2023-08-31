{ pkgs, lib, ... }:

let
  inherit (pkgs) julia;

  version = lib.versions.major julia.version;

  extensions = [ ".jl" ];
in

{
  id = "julia-${version}";
  name = "Julia Tools";

  packages = [
    julia
  ];

  replit.runners.julia = {
    name = "Julia REPL";
    language = "julia";
    inherit extensions;
    optionalFileParam = true;
    start = "${julia}/bin/julia -i --banner=no";
    prompt = "julia>";
  };
}

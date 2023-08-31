{ pkgs, lib, ... }:

let
  inherit (pkgs) scala;

  version = lib.versions.majorMinor scala.version;
  extensions = [ ".scala" ];
in

{
  id = "scala-${version}";
  name = "Scala ${version} Tools";

  packages = [
    scala
  ];

  replit.languageServers.metals = {
    name = "Metals";
    language = "scala";
    inherit extensions;
    start = "${pkgs.metals}/bin/metals";
  };

  replit.runners.scala = {
    name = "Compiled Scala";
    language = "scala";
    inherit extensions;
    compile = "${scala}/bin/scalac -classpath . -d . main.scala";
    start = "${scala}/bin/scala -classpath . Main";
  };
}

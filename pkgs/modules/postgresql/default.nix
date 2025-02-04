{ postgresql }:
{ pkgs, lib, ... }:
let
  postgresql-version = lib.versions.major postgresql.version;
in
{
  id = "postgresql-${postgresql-version}";
  name = "Postgresql Tools";
  displayVersion = postgresql-version;
  description = ''
    Tools for working with Postgresql databases.
  '';

  replit.packages = [
    postgresql
  ];
}

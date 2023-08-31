{ pkgs, lib, ... }:

let
  inherit (pkgs) ocaml opam;
  inherit (pkgs.ocamlPackages) ocaml-lsp utop;

  version = lib.versions.major ocaml.version;

  extensions = [ ".ml" ".mli" ];
in

{
  id = "ocaml-${version}";
  name = "OCaml Tools";

  packages = [
    ocaml
    opam
    utop
  ];

  env = rec {
    OPAMROOT = "$REPL_HOME/.opam";
    OPAM_SWITCH_PREFIX = "${OPAMROOT}/default";
    CAML_LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${OPAM_SWITCH_PREFIX}/ocaml/stublibs"
      "${ocaml}/lib/ocaml/stublibs"
      "${ocaml}/lib/ocaml"
    ];
    OCAML_TOPLEVEL_PATH = "${OPAM_SWITCH_PREFIX}/lib/toplevel";
    MANPATH = "${OPAM_SWITCH_PREFIX}/man:$MANPATH";
    PATH = "${OPAM_SWITCH_PREFIX}/bin:$PATH";
  };

  replit.languageServers.ocaml-lsp = {
    name = "OCaml LSP";
    language = "ocaml";
    inherit extensions;
    start = "${ocaml-lsp}/bin/ocamllsp";
  };

  replit.runners.ocaml-script = {
    name = "OCaml Script";
    language = "ocaml";
    inherit extensions;
    fileParam = true;
    start = "${ocaml}/bin/ocaml $file";
  };
}

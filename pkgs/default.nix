{ pkgs, self }:

with pkgs.lib;

let
  modules = self.modules;
  revstring_long = self.rev or "dirty";
  revstring = builtins.substring 0 7 revstring_long;
  all-modules = builtins.fromJSON (builtins.readFile ../modules.json);

  bundle-locked-fn = { modulesLocks }: pkgs.callPackage ./bundle-locked {
    inherit modulesLocks;
    inherit revstring;
  };

  mkPhonyOCI = pkgs.callPackage ./mk-phony-oci { ztoc-rs = self.inputs.ztoc-rs.packages.x86_64-linux.default; };

  mkPhonyOCIs = { moduleIds ? null }: pkgs.callPackage ./mk-phony-ocis {
    inherit mkPhonyOCI;
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs;
      inherit moduleIds;
    };
    inherit revstring;
  };

  bundle-squashfs-fn = { moduleIds ? null, upgrade-maps }:
    let
      modulesLocks = import ./filter-modules-locks {
        inherit pkgs;
        inherit moduleIds;
      };
    in
    pkgs.callPackage ./bundle-squashfs {
      bundle-locked = bundle-locked-fn {
        inherit modulesLocks;
      };
      active-modules = import ./active-modules {
        inherit pkgs;
        inherit self;
        all-modules = modulesLocks;
      };
      registry = modulesLocks;
      inherit upgrade-maps revstring;
    };

in
rec {
  default = moduleit;
  moduleit = pkgs.callPackage ./moduleit { };

  bundle = pkgs.linkFarm "nixmodules-bundle-${revstring}" (
    mapAttrsToList (name: value: { inherit name; path = value; }) modules
  );

  rev = pkgs.writeText "rev" revstring;

  rev_long = pkgs.writeText "rev_long" revstring_long;

  active-modules = import ./active-modules {
    inherit pkgs;
    inherit self;
    inherit all-modules;
  };

  upgrade-maps = import ./upgrade-maps {
    inherit pkgs;
  };


  bundle-image = pkgs.callPackage ./bundle-image {
    inherit bundle-locked revstring;
    inherit active-modules upgrade-maps;
  };

  bundle-image-tarball = pkgs.callPackage ./bundle-image-tarball { inherit bundle-image revstring; };

  bundle-locked = bundle-locked-fn {
    modulesLocks = import ./filter-modules-locks {
      inherit pkgs;
    };
  };

  bundle-squashfs = bundle-squashfs-fn {
    moduleIds = [ "python-3.10" "nodejs-18" ];
    inherit upgrade-maps;
  };

  custom-bundle-squashfs = bundle-squashfs-fn {
    # customize these IDs for dev. They can be like "python-3.10:v10-20230711-6807d41" or "python-3.10"
    # publish your feature branch first and make sure modules.json is current, then
    # in goval dir (next to nixmodules), run `make custom-nixmodules-disk` to use this disk in conman
    moduleIds = [
      "c-clang14:v3-20230901-5e435f9"
      "clojure-1.11:v3-20230901-5e435f9"
      "cpp-clang14:v3-20230901-5e435f9"
      "go-1.20:v2-20230901-5e435f9"
      "java-graalvm22.3:v5-20230901-5e435f9"
      "php-8.1:v3-20230901-5e435f9"
      "python-3.10:v21-20230901-5e435f9"
      "qbasic:v3-20230901-5e435f9"
      "swift-5.8:v2-20230901-5e435f9"
      "python-3.11:v2-20230901-5e435f9"
      "apl-1.8:v1-20230901-5e435f9"
      "bash:v1-20230901-5e435f9"
      "basic:v1-20230901-5e435f9"
      "brainfuck:v1-20230901-5e435f9"
      "c-clang12:v1-20230901-5e435f9"
      "clojure-1.10:v1-20230901-5e435f9"
      "cpp-clang12:v1-20230901-5e435f9"
      "crystal-1.2:v1-20230901-5e435f9"
      "deno-1.16:v1-20230901-5e435f9"
      "dotnet-6.0:v1-20230901-5e435f9"
      "elisp:v1-20230901-5e435f9"
      "elixir-1.12:v1-20230901-5e435f9"
      "emoticon:v1-20230901-5e435f9"
      "erlang-24:v1-20230901-5e435f9"
      "forth-0:v1-20230901-5e435f9"
      "go-1.17:v1-20230901-5e435f9"
      "julia-1:v1-20230901-5e435f9"
      "kotlin-1:v1-20230901-5e435f9"
      "lolcode-0:v1-20230901-5e435f9"
      "love2d-0:v1-20230901-5e435f9"
      "nim-1:v1-20230901-5e435f9"
      "ocaml-4:v1-20230901-5e435f9"
      "php-7.4:v1-20230901-5e435f9"
      "php-cli-7.4:v1-20230901-5e435f9"
      "python-3.8:v1-20230901-5e435f9"
      "python2:v1-20230901-5e435f9"
      "raku-2021.10:v1-20230901-5e435f9"
      "roy:v1-20230901-5e435f9"
      "scala-2.13:v1-20230901-5e435f9"
      "scheme:v1-20230901-5e435f9"
      "sqlite-3.36:v1-20230901-5e435f9"
      "swift-5.4:v1-20230901-5e435f9"
      "tcl-8.6:v1-20230901-5e435f9"
      "unlambda:v1-20230901-5e435f9"
      "wasmer-2.0:v1-20230901-5e435f9"
    ];
    inherit upgrade-maps;
  };

  custom-bundle-phony-ocis = mkPhonyOCIs { moduleIds = [ "nodejs-18" ]; };

  bundle-phony-ocis = mkPhonyOCIs { };

} // modules

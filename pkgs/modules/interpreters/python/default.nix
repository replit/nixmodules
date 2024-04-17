{ pkgs, config, lib, ... }:
with pkgs.lib;
let
  cfg = config.interpreters.python;
  pythonVersion = cfg.version;
  python = pkgs.python-versions.${pythonVersion}.python;
  pypkgs = pkgs.python-versions.${pythonVersion}.pythonPackages;
  pythonUtils = import ../../../python-utils {
    inherit pkgs python pypkgs;
  };
  pylibs-dir = ".pythonlibs";
  userbase = "$REPL_HOME/${pylibs-dir}";
  pythonWrapper = pythonUtils.pythonWrapper;
  python3-wrapper = pythonWrapper { bin = "${python}/bin/python3"; name = "python3"; aliases = [ "python" "python${pythonVersion}" ]; };
  sitecustomize = pkgs.callPackage ./sitecustomize { };
in
{
  options = {
    interpreters.python = {
      enable = mkModuleEnableOption {
        name = "Python runtime";
        description = "Python is a programming language that lets you work quickly and integrate systems more effectively.";
      };

      version = mkOption {
        type = types.enum (attrNames pkgs.python-versions);
        description = "Python version";
      };

      useSiteCustomize = mkOption {
        type = types.bool;
        description = "Whether to use Replit's sitecustomize.py";
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    replit.packages = [
      python3-wrapper
    ];

    replit.runners.python = {
      name = "Python ${pythonVersion}";
      displayVersion = python.version;
      fileParam = true;
      language = "python3";
      start = "${python3-wrapper}/bin/python3 $file";
    };

    replit.env = {
      PYTHONPATH = mkIf cfg.useSiteCustomize sitecustomize;
      REPLIT_PYTHONPATH = mkIf cfg.useSiteCustomize "${userbase}/${python.sitePackages}:${pypkgs.setuptools}/${python.sitePackages}";
      PATH = "${userbase}/bin";
    };
  };
}

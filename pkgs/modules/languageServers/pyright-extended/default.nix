{ pkgs, lib, config, ... }:
let
  cfg = config.languageServers.pyright-extended;
  pythonVersion = config.interpreters.python.version;
  pypkgs = pkgs.python-versions.${pythonVersion}.pythonPackages;
  pyright-extended = pkgs.callPackage ../../../pyright-extended {
    yapf = pypkgs.yapf;
  };
in
with pkgs.lib; {
  options = {
    languageServers.pyright-extended = {
      enable = mkModuleEnableOption {
        name = "Pyright Extended";
        description = "Pyright with yapf and ruff";
      };
    };
  };

  config = mkIf cfg.enable {
    replit.dev.languageServers.pyright-extended = {
      name = "pyright-extended";
      displayVersion = pyright-extended.version;
      language = "python3";
      start = "${pyright-extended}/bin/langserver.index.js --stdio";
    };
  };
}

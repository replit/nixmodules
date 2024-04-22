{ pkgs, ... }: {
  "3.8" = {
    python = pkgs.python38Full;
    pythonPackages = pkgs.python38Packages;
  };

  "3.9" = {
    python = pkgs.python39Full;
    pythonPackages = pkgs.python39Packages;
  };

  "3.10" = {
    python = pkgs.python310Full;
    pythonPackages = pkgs.python310Packages;
  };

  "3.11" = {
    python = pkgs.python311Full;
    pythonPackages = pkgs.python311Packages;
  };

  "3.12" = {
    python = pkgs.python312Full;
    pythonPackages = pkgs.python312Packages;
  };
}

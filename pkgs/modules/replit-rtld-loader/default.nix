{ lib, pkgs, ... }:
{
  id = "replit-rtld-loader";
  name = "Replit RTLD Loader";
  description = ''
    The Replit RTLD Loader allows dynamically loaded shared libraries (.so) to work seamlessly in Repls.
  '';

  replit.env = {
    LD_AUDIT = "${pkgs.replit-rtld-loader}/rtld_loader.so";
  };
}


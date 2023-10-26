{ pkgs, pkgs-unstable, ... }:

let

  replit-runc = pkgs-unstable.buildGo121Module {
    pname = "replit-runc";
    version = "1.1.9+replit";

    src = pkgs.fetchFromGitHub {
      owner = "opencontainers";
      repo = "runc";
      rev = "b17c6f237dfd6d2dab9bd9c9b36cb9e429ee1fd1";
      sha256 = "sha256-KyEIXwQiu/ZpqiuLzJv6nxLmD6qzr6+hpiDVE1q9MAY=";
    };

    # We have a few patches in place to be able to run runc without privileges
    # and ask ruse to create the privileged part of the container.
    patches = [ ./replit-runc.patch ];

    subPackages = [ "./" ];

    vendorSha256 = null;

    doCheck = false;

    postInstall = ''
      mv $out/bin/runc $out/bin/replit-runc
    '';
  };

  replit-shim-runc = pkgs-unstable.buildGo121Module {
    pname = "replit-shim-runc";
    version = "1.7.5+replit";

    src = pkgs.fetchFromGitHub {
      owner = "containerd";
      repo = "containerd";
      rev = "v1.7.5";
      sha256 = "sha256-g+1JfXO1k0ijPpVTo+WxmXro4p4MbRCIZdgtgy58M60=";
    };

    # We have a few patches in place to be able to invoke the replit-runc.
    patches = [ ./replit-shim-runc.patch ];

    subPackages = [ "./cmd/containerd-shim-runc-v2" ];

    vendorSha256 = null;

    doCheck = false;

    postInstall = ''
      mv $out/bin/containerd-shim-runc-v2 $out/bin/replit-shim-runc
    '';
  };

  containerdAdditions = pkgs.copyPathToStore ./etc;
  containerd = pkgs.containerd.overrideAttrs (old: {
    postInstall = ''
      mkdir $out/etc
      cp ${containerdAdditions}/containerd.toml $out/etc/
    '';
  });

in

{
  id = "docker";
  name = "Support for Docker containers";

  replit.packages = [ ];

  replit.dev.packages = [
    pkgs.docker-client
    containerd
    replit-shim-runc
    replit-runc
  ];
}

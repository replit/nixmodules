{ pkgs, pkgs-unstable, ... }:

let

  configFiles = pkgs.copyPathToStore ./etc;

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

  replit-buildkit-config = pkgs.substituteAll {
    src = ./etc/buildkitd.toml;

    replitShimRunc = replit-shim-runc;
  };

  replit-buildkit = pkgs-unstable.buildGo121Module {
    pname = "replit-buildkit";
    version = "v0.13.0-beta1+replit";

    src = pkgs.fetchFromGitHub {
      owner = "moby";
      repo = "buildkit";
      rev = "v0.13.0-beta1";
      sha256 = "sha256-9ndCbjwqXiftRs9qbXUZhSEHIpbDyeT+kUPWcOgm/6k=";
    };

    # We have a few patches in place to be able to invoke the replit-runc.
    patches = [ ./replit-buildkit.patch ];

    subPackages = [ "./cmd/buildkitd" "./cmd/buildctl" ];

    vendorSha256 = null;

    doCheck = false;

    postInstall = ''
      mkdir $out/etc
      cp ${replit-buildkit-config} $out/etc/buildkitd.toml
      mv $out/bin/buildkitd $out/bin/replit-buildkitd
      mv $out/bin/buildctl $out/bin/replit-buildctl
    '';
  };

  containerd = pkgs.containerd.overrideAttrs (old: {
    postInstall = ''
      mkdir $out/etc
      cp ${configFiles}/containerd.toml $out/etc/
    '';
  });

in

{
  id = "docker";
  name = "Support for Docker containers";

  replit.packages = [ ];

  replit.dev.packages = [
    pkgs.docker-client
    pkgs.docker-compose
    containerd
    replit-shim-runc
    replit-runc
    replit-buildkit
  ];
}

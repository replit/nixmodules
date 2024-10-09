{ pkgs, ... }:

let

  configFiles = pkgs.copyPathToStore ./etc;

  replit-runc = pkgs.buildGo123Module {
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

    vendorHash = null;

    doCheck = false;

    postInstall = ''
      mv $out/bin/runc $out/bin/replit-runc
    '';
  };

  replit-containerd = pkgs.buildGo123Module {
    pname = "replit-containerd";
    version = "1.7.5+replit";

    src = pkgs.fetchFromGitHub {
      owner = "containerd";
      repo = "containerd";
      rev = "v1.7.5";
      sha256 = "sha256-g+1JfXO1k0ijPpVTo+WxmXro4p4MbRCIZdgtgy58M60=";
    };

    # We have a few patches in place to be able to start containerd with an
    # activation socket and to be able to invoke the replit version of runc.
    patches = [ ./replit-containerd.patch ./replit-shim-runc.patch ];

    subPackages = [ "./cmd/containerd" "./cmd/ctr" "./cmd/containerd-shim-runc-v2" ];

    vendorHash = null;

    doCheck = false;

    postInstall = ''
      mkdir $out/etc
      mv $out/bin/containerd $out/bin/replit-containerd
      mv $out/bin/containerd-shim-runc-v2 $out/bin/replit-shim-runc
      cp ${configFiles}/containerd.toml $out/etc/
    '';
  };

  replit-buildkit-config = pkgs.substituteAll {
    src = ./etc/buildkitd.toml;

    replitShimRunc = replit-containerd;
  };

  replit-buildkit = pkgs.buildGo123Module {
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

    vendorHash = null;

    doCheck = false;

    postInstall = ''
      mv $out/bin/buildkitd $out/bin/replit-buildkitd

      mkdir $out/etc
      cp ${replit-buildkit-config} $out/etc/buildkitd.toml
    '';
  };

  replit-dockerd-config = pkgs.substituteAll {
    src = ./etc/dockerd.json;

    replitShimRunc = replit-containerd;
  };

  mobyVersion = "24.0.7+replit";

  replit-moby = pkgs.buildGoModule {
    pname = "replit-moby";
    version = mobyVersion;

    src = pkgs.fetchFromGitHub {
      owner = "moby";
      repo = "moby";
      rev = "v24.0.7";
      sha256 = "sha256-VUgsclXkoHHNT+GgYL7qiCV/4V3P9RZrT9BegMVYaRU=";
    };

    vendorHash = null;

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.pkg-config pkgs.go pkgs.libtool ];

    buildInputs = [ pkgs.sqlite ];

    extraPath = [ pkgs.xz pkgs.procps pkgs.util-linux pkgs.git ];

    # We have a few patches in place to avoid using namespaces directly.
    patches = [ ./replit-moby.patch ];

    doCheck = false;

    postPatch = ''
      patchShebangs hack/make.sh hack/with-go-mod.sh hack/make/
    '';

    buildPhase = ''
      export GOCACHE="$TMPDIR/go-cache"
      # build engine
      cd ./go/src
      export AUTO_GOPATH=1
      export DOCKER_GITCOMMIT="v${mobyVersion}"
      export VERSION="${mobyVersion}"
      ./hack/make.sh dynbinary
      cd -
    '';

    postInstall = ''
      cd ./go/src
      install -Dm755 ./bundles/dynbinary-daemon/dockerd $out/libexec/docker/replit-dockerd

      makeWrapper $out/libexec/docker/replit-dockerd $out/bin/replit-dockerd \
        --prefix PATH : "$out/libexec/docker:$extraPath"

      mkdir $out/etc
      cp ${replit-dockerd-config} $out/etc/dockerd.json
    '';

    DOCKER_BUILDTAGS = [
      "exclude_graphdriver_btrfs"
      "exclude_graphdriver_devicemapper"
      "exclude_graphdriver_fuseoverlayfs"
      "exclude_graphdriver_overlay2"
      "replit"
    ];
  };
in

{
  id = "docker";
  name = "Support for Docker containers";
  internal = true;
  description = ''
    Docker support for Replit. Includes: Docker, Docker Compose, Moby, Containerd, runc, Buildkid.
  '';

  replit.packages = [ ];

  replit.dev.packages = [
    pkgs.docker-client
    pkgs.docker-compose
    replit-moby
    replit-containerd
    replit-runc
    replit-buildkit
  ];
}

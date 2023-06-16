{ pkgs, stdenv, fetchurl, bash, coreutils, unzip }:

stdenv.mkDerivation rec {
  pname = "vscode-cpptools-dap";
  version = "1.3.1";

  passthru = {
    messages = import ./messages.nix;
  };

  phases = "installPhase fixupPhase";

  src = fetchurl {
    url = "https://github.com/microsoft/vscode-cpptools/releases/download/${version}/cpptools-linux.vsix";
    sha256 = "e88008c3d1a19e2b65152b39b94a792b451fad99e51da59f0500e6efd2ccc168";
  };

  # TODO: this has an implicit dependency on gdb.

  buildInputs = [ bash coreutils unzip ];

  installPhase = ''
    mkdir -p $out/share/dap/cpp $out/bin
    ${unzip}/bin/unzip -q ${src} -d $out/share/dap/cpp
    chmod +x $out/share/dap/cpp/extension/debugAdapters/OpenDebugAD7 $out/share/dap/cpp/extension/debugAdapters/mono.linux-x86_64

    # OpenDebugAD7 doesn't quite like being called through a symlink, since it
    # does some path manipulation based on $0. Create a tiny wrapper shell script
    # for it.
    cat<<EOF > $out/bin/dap-cpp
    #!${stdenv.shell}
    export PATH="${pkgs.lib.makeBinPath [pkgs.gdb pkgs.coreutils]}"
    exec $out/share/dap/cpp/extension/debugAdapters/OpenDebugAD7 "\$@"
    EOF
    chmod +x $out/bin/dap-cpp
  '';
}

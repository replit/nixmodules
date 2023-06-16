{ pkgs, python, pypkgs }:

pypkgs.buildPythonPackage rec {
  pname = "replit-python-dap-wrapper";
  version = "1.0.0";

  src = ./.;

  propagatedBuildInputs = with pypkgs; [
    debugpy
  ];

  postInstall = ''
    mkdir -p $out/bin
    
    cat<<EOF > $out/bin/dap-python
    #!${python}/bin/python3
    """A small wrapper around debugpy's cli.

    This wrapper is roughly equivalent to:

        python3 -m debugpy --listen localhost:0 --wait-for-client "$@"

    with the added twist that it reports the port used back through fd 3.
    """

    import os
    import os.path
    import sys
    import runpy

    import debugpy
    import debugpy.server


    def _main() -> None:
        if len(sys.argv) < 2:
            print(f'Usage: {sys.argv[0]} <script> [args...]', file=sys.stderr)
            sys.exit(1)
        # This process' stdout/stderr are already used to deliver
        # the debuggee's stdout/stderr. We need to deliver this
        # information out of band, through fd 3.
        with os.fdopen(3, 'w') as port_fd:
            port_fd.write(str(debugpy.listen(('localhost', 0))[1]))
        debugpy.wait_for_client()
        # The first argument to this script is this script itself, so we need to
        # remove it. Otherwise `runpy.run_path` below will change `sys.argv[0]` to
        # the script being run, which would result in the script name being
        # duplicate.
        sys.argv.pop(0)
        target_as_str = sys.argv[0]
        dir = os.path.dirname(os.path.abspath(target_as_str))
        sys.path.insert(0, os.getcwd())
        runpy.run_path(target_as_str, run_name="__main__")


    if __name__ == '__main__':
        _main()
    EOF
    chmod +x $out/bin/dap-python
  '';
}

package main

import (
	"os"
	"strings"
	"syscall"
	"fmt"
)

var PythonExePath string
var ReplitPythonLdLibraryPath string

// Set up environment for legacy nixpkgs
func legacy() {
	// Previous wrapper script semantics:
	// export LD_LIBRARY_PATH=${python-ld-library-path}
	// if [ -n "''${PYTHON_LD_LIBRARY_PATH-}" ]; then
	// 	export LD_LIBRARY_PATH=''${PYTHON_LD_LIBRARY_PATH}:$LD_LIBRARY_PATH
	// fi
	// if [ -n "''${REPLIT_LD_LIBRARY_PATH-}" ]; then
	// 	export LD_LIBRARY_PATH=''${REPLIT_LD_LIBRARY_PATH}:$LD_LIBRARY_PATH
	// fi

	// REPLIT_LD_LIBRARY_PATH:PYTHON_LD_LIBRARY_PATH:${python-ld-library-path}

	ldLibraryPath := []string{}
	for _, key := range []string{
		"REPLIT_LD_LIBRARY_PATH",
		"LD_LIBRARY_PATH",
	} {
		if val, ok := os.LookupEnv(key); ok {
			ldLibraryPath = append(ldLibraryPath, val)
		}
	}

	ldLibraryPath = append(ldLibraryPath, ReplitPythonLdLibraryPath)

	if len(ldLibraryPath) > 0 {
		os.Setenv("LD_LIBRARY_PATH", strings.Join(ldLibraryPath, ":"))
	}
}

// Unsets the PIP_CONFIG_FILE config if we are running in virtualenv mode,
// because that config file - see pip.nix - works only for `--user` mode pip installs
// but pip cannot do `--user` inside virtualenv.
func unsetPipConfigFileForVirtualEnvPython() {
    exePath, err := os.Executable()
    if err == nil {
        repl_home := os.Getenv("REPL_HOME")
        if repl_home != "" {
            dot_python_dir := fmt.Sprintf("%s/%s", repl_home, ".pythonlibs/bin/")
            if strings.HasPrefix(exePath, dot_python_dir) {
                os.Unsetenv("PIP_CONFIG_FILE")
            }
        }
    }
}

// Set up environment for non-legacy nixpkgs
func modern() {
	if ldAudit := os.Getenv("REPLIT_LD_AUDIT"); ldAudit != "" {
		os.Setenv("LD_AUDIT", ldAudit)
	}

	// Previous wrapper script semantics:
	// export REPLIT_LD_LIBRARY_PATH=${python-ld-library-path}:''${REPLIT_LD_LIBRARY_PATH:-}

	// ${python-ld-library-path}:REPLIT_LD_LIBRARY_PATH

	replitLdLibraryPath := []string{ReplitPythonLdLibraryPath}

	if val, ok := os.LookupEnv("REPLIT_LD_LIBRARY_PATH"); ok {
		replitLdLibraryPath = append(replitLdLibraryPath, val)
	}

	os.Setenv("REPLIT_LD_LIBRARY_PATH", strings.Join(replitLdLibraryPath, ":"))
}

// returns whether a Nix channel works with RTLD loader
func channelWorksWithRtldLoader(channel string) bool {
	return channel != "" && channel != "legacy" && channel != "stable-21_11"
}

func main() {
	unsetPipConfigFileForVirtualEnvPython()
	os.Unsetenv("PYTHONNOUSERSITE")

	if val, ok := os.LookupEnv("REPLIT_NIX_CHANNEL"); ok && channelWorksWithRtldLoader(val) {
		modern()
	} else {
		legacy()
	}

	if err := syscall.Exec(PythonExePath, os.Args, os.Environ()); err != nil {
		panic(err)
	}
}

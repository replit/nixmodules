package main

import (
	"os"
	"strings"
	"syscall"
)

var PythonExePath string
var ReplitPythonLdLibraryPath string

// Set up environment for legacy nixpkgs
func legacy() {
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

// Set up environment for non-legacy nixpkgs
func modern() {
	if ldAudit := os.Getenv("REPLIT_LD_AUDIT"); ldAudit != "" {
		os.Setenv("LD_AUDIT", ldAudit)
	}
	if val, ok := os.LookupEnv("REPLIT_LD_LIBRARY_PATH"); ok && val != "" {
		os.Setenv("REPLIT_LD_LIBRARY_PATH", strings.Join([]string{ReplitPythonLdLibraryPath, val}, ":"))
	}
}

func main() {
	os.Unsetenv("PYTHONNOUSERSITE")

	if val, ok := os.LookupEnv("REPLIT_NIX_CHANNEL"); !ok || val == "legacy" || val == "" {
		legacy()
	} else {
		modern()
	}

	if err := syscall.Exec(PythonExePath, os.Args, os.Environ()); err != nil {
		panic(err)
	}
}

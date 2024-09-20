package main

import (
	"os"
	"strings"
	"syscall"
)

var PythonExePath string

func main() {
	if ldAudit := os.Getenv("REPLIT_LD_AUDIT"); ldAudit != "" {
		os.Setenv("LD_AUDIT", ldAudit)
	}
	os.Unsetenv("PYTHONNOUSERSITE")

	ldLibraryPath := []string{}
	for _, key := range []string{
		"REPLIT_LD_LIBRARY_PATH",
		"LD_LIBRARY_PATH",
		"REPLIT_PYTHON_LD_LIBRARY_PATH",
	} {
		if val, ok := os.LookupEnv(key); ok {
			ldLibraryPath = append(ldLibraryPath, val)
		}
	}

	if len(ldLibraryPath) > 0 {
		os.Setenv("LD_LIBRARY_PATH", strings.Join(ldLibraryPath, ":"))
	}


	if err := syscall.Exec(PythonExePath, os.Args, os.Environ()); err != nil {
		panic(err)
	}
}

# ModuleIt

A CLI tool for (Nix) module authors to compile modules. Preinstalled in repls.

## Usage

Say you have a module such as `example.nix` in this same folder. Run

`moduleit example.nix`

to compile the module. It will symlink the output path to `result` in the current directory.
If you want the output to be a different place, provide the path in the second argument:

`moduleit example.nix /path/to/where/i/want/the/symlink`

In this case, it will materialize the contents in the output path as a regular file.


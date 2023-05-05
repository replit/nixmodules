# Repl.it Nix Modules

This repository holds Repl.it's Nix modules.

* Each module is located as a folder under `pkgs/modules`
* `pkgs/modules/default.nix` specifies a list of the active modules, some of which are parameterized with the version of the runtime or compiler

To list all active modules, you can do:

```
nix eval .#modules --json | jq
```
Output might look like:
```json
{
  "bun-0.5-m1.0": "/nix/store/nqwdhvs2n6fv82nkn77rg5wb3g1giwjs-replit-module-bun-0.5-m1.0",
  "c-14.0-m1.0": "/nix/store/c8v74sbwivlj0mridwsdng883frwccy5-replit-module-c-14.0-m1.0",
  "clojure-1.11-m1.0": "/nix/store/dsx4w6inr69f6c799qija5nf08q1ds39-replit-module-clojure-1.11-m1.0",
  "cpp-14.0-m1.0": "/nix/store/065sbbghckzyirbxq239s4y3bcsr2wq2-replit-module-cpp-14.0-m1.0",
  "dart-2.18-m1.0": "/nix/store/ampynbffmbjckc4xqzndlhbxncdljqfv-replit-module-dart-2.18-m1.0",
  "dotnet-7.0-m1.0": "/nix/store/nkq2y69kfbbjxrr9dvc385nskqs0cd67-replit-module-dotnet-7.0-m1.0",
  "go-1.19-m1.0": "/nix/store/g1vrclpr65ynpldn7a6yvjsniaj3fb3r-replit-module-go-1.19-m1.0",
  "haskell-9.0-m1.0": "/nix/store/7l7mafijx1lrxs85k6vzr3q5xzxi02fb-replit-module-haskell-9.0-m1.0",
  "java-22.3-m1.0": "/nix/store/v09kxcfkm66bks2lxv5hknxh8i4ijzq9-replit-module-java-22.3-m1.0",
  "lua-5.2-m1.0": "/nix/store/3g185mb4bzn2g9w0b7shw39x6ybby0g6-replit-module-lua-5.2-m1.0",
  "nodejs-14.21-m1.1": "/nix/store/1igqvvk7agkxvz0ibi7vlsdkxnx5hnrj-replit-module-nodejs-14.21-m1.1",
  "nodejs-16.18-m1.1": "/nix/store/751zzdn9cl7g4qx04k5szxm3jynfqa03-replit-module-nodejs-16.18-m1.1",
  "nodejs-18.12-m1.1": "/nix/store/a1i4r09lc1qrnzcwv5bkfscc8nxk8b44-replit-module-nodejs-18.12-m1.1",
  "nodejs-19.1-m1.1": "/nix/store/azs3v09dm03v27zrvhvhs7j1h5zm0y2s-replit-module-nodejs-19.1-m1.1",
  "php-8.1-m1.0": "/nix/store/z9x4avlw2s0cmaqglbzb3ymb7cgv7hm4-replit-module-php-8.1-m1.0",
  "python-3.10-m1.0": "/nix/store/ihcaap76i6xp3hzfayg6a0krx1pb5w52-replit-module-python-3.10-m1.0",
  "qbasic-0.0-m1.1": "/nix/store/rpb9dg8c8cwiszfxa1xhw7z06yh59vn3-replit-module-qbasic-0.0-m1.1",
  "r-4.2-m1.0": "/nix/store/c7wcs687dkxvfak0dr2gnb5ll69bv6yf-replit-module-r-4.2-m1.0",
  "ruby-3.1-m1.0": "/nix/store/rxmyz9gv677v06jz64pqs7a9g2ppw0mj-replit-module-ruby-3.1-m1.0",
  "rust-1.64-m1.0": "/nix/store/v2wq17m6chbxgv4vk2r4p4bqjp5r80vn-replit-module-rust-1.64-m1.0",
  "swift-5.6-m1.0": "/nix/store/qp9bvj042a855xd4i0hrqbwz0p81zp4k-replit-module-swift-5.6-m1.0",
  "web-3.0-m1.0": "/nix/store/37kafc7qxhji91175lgccmn2yx1dzw9m-replit-module-web-3.0-m1.0"
}
```

To build modules, you can do:

```
nix build .#bundle
```

which will create a `result` directory containing a symlink for each active module.

To build a specific module, for example `bun-0.5-m1.0`, you can do:

```
nix build .#modules.'"bun-0.5-m1.0"'
```

## Lock Modules

`lock_modules.py` is a script that generates a module registry file `modules.json`.
It should be run each time when before publishing a PR (but after committing your changes):

```
$ nix develop
$ python lock_modules.py
```

`modules.json` is similar to a lock file in used in common packagers in that it fixes
the exact version of each module. This file looks something like:

```json
{
  "modules": {
    "nodejs-18.12-m1.1": {
      "commit": "4ec006c0eb247320e77c0abbf46b6f9e33370f81",
      "created": "2023-05-04T16:52:42-04:00",
      "path": "/nix/store/a1i4r09lc1qrnzcwv5bkfscc8nxk8b44-replit-module-nodejs-18.12-m1.1"
    },
    "nodejs-19.1-m1.1": {
      "commit": "4ec006c0eb247320e77c0abbf46b6f9e33370f81",
      "created": "2023-05-04T16:52:42-04:00",
      "path": "/nix/store/azs3v09dm03v27zrvhvhs7j1h5zm0y2s-replit-module-nodejs-19.1-m1.1"
    },
    "go-1.19-m1.0": {
      "commit": "4ec006c0eb247320e77c0abbf46b6f9e33370f81",
      "created": "2023-05-04T16:52:42-04:00",
      "path": "/nix/store/g1vrclpr65ynpldn7a6yvjsniaj3fb3r-replit-module-go-1.19-m1.0"
    }
  },
  "aliases": {
    "nodejs": "nodejs-19.1-m1.1",
    "nodejs-18.12": "nodejs-18.12-m1.1",
    "nodejs-18.12-m1": "nodejs-18.12-m1.1",
    "nodejs-19.1": "nodejs-19.1-m1.1",
    "nodejs-19.1-m1": "nodejs-19.1-m1.1",
    "go": "go-1.19-m1.0",
    "go-1.19": "go-1.19-m1.0",
    "go-1.19-m1": "go-1.19-m1.0"
  }
}
```

The modules section is an append-only section. This means the contents of the value under a key, say `nodejs-19.1-m1.1`
cannot be changed. Each module contains:

* commit - the git commit of the repo when `lock_modules.py` was ran. The script requires a clean working directory,
unless the `-d` flag is supplied
* created - the timestamp of the commit
* path - the output path of the module as returned by the `nix eval .#modules --json` command

The aliases section points to the latest version of each module for a given shortened version specifier.

If you made a modification in a module or a dependency of a module, re-running `lock_modules.py` will fail
an error like:
```
Exception: go-1.19-m1.0 changed from /nix/store/g1vrclpr65ynpldn7a6yvjsniaj3fb3r-replit-module-go-1.19-m1.0 to /nix/store/pbrqcayg3ahawdld7j5kay97xli8zi0a-replit-module-go-1.19-m1.0
```

To move forward, you'll have to increment the version of the associated module.

See more about the versioning scheme at: https://replit.com/@util/Design-docs#goval/nixmodules_versions.md
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
  "bun-0.5": "/nix/store/l08f5vl1af9rpzd7kvr0l5gx9v7y8p12-replit-module-bun-0.5",
  "c-clang14.0": "/nix/store/n4vzd9rkpjs72xj9yvlakxh3bardvdki-replit-module-c-clang14.0",
  "clojure-1.11": "/nix/store/giqq76fl3yphzsm6rkl1qxqh4mszknpl-replit-module-clojure-1.11",
  "cpp-clang14": "/nix/store/8iv4czda6j5nfhxs80ci625hj91ffpbn-replit-module-cpp-clang14",
  "dart-2.18": "/nix/store/mhl58f8y3z6jv0javkmx28y5h9aacw39-replit-module-dart-2.18",
  "dotnet-7.0": "/nix/store/06mjna44a7w9bby6r121a7i9a5027qqn-replit-module-dotnet-7.0",
  "go-1.19": "/nix/store/y1gb1k8bkyd9jqxi4r1g9qibcqn3c6dm-replit-module-go-1.19",
  ...
}
```


## Building

For each of the following examples, the build result will found be in a file or directory named `result`.

To build all active modules:

```
nix build .#bundle
```

To build a specific module, for example `bun-0.5`, you can do:

```
nix build .#'"bun-0.5"'
```

To build all historical versions of all modules:

```
nix build .#bundle-locked
```

To build a disk containing all historical versions of all modules:

```
nix build .#bundle-image
```

To build a compressed squashfs disk containing all historical versions of all modules:

```
nix build .#bundle-squashfs
```

## Lock Modules

`scripts/lock_modules.py` generates/updates the module lock file `modules.json`.
modules.json is similar to a lock file used in common packagers in that it fixes
the exact version of each module. It looks like:

```json
{
  "bun-0.5:v1-20230522-ec43fbd": {
    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
    "path": "/nix/store/l08f5vl1af9rpzd7kvr0l5gx9v7y8p12-replit-module-bun-0.5"
  },
  "c-clang14.0:v1-20230522-ec43fbd": {
    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
    "path": "/nix/store/n4vzd9rkpjs72xj9yvlakxh3bardvdki-replit-module-c-clang14.0"
  },
  "clojure-1.11:v1-20230522-ec43fbd": {
    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
    "path": "/nix/store/giqq76fl3yphzsm6rkl1qxqh4mszknpl-replit-module-clojure-1.11"
  },
  "cpp-clang14:v1-20230522-ec43fbd": {
    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
    "path": "/nix/store/8iv4czda6j5nfhxs80ci625hj91ffpbn-replit-module-cpp-clang14"
  },
  ...
}
```

This file is append-only. This means the contents of the value under a key, say `bun-0.5:v1-20230522-ec43fbd`
cannot be changed.

Keys into the mapping are module registry IDs consisting of `<module ID>:<tag>`.

A tag consists of `v<version>-<date>-<short commit>`, which contains:
* version - an auto-incremented numeric ID which starts at 1
* date - an 8-digit sequence in the form `YYYYMMDD`
* short commit - the first 7 digits of the git commit sha

The values of the mapping are:
* `commit` - the full commit sha of the repo when `lock_modules.py` was ran. The script requires a clean working directory,
unless the `-d` flag is supplied
* `path` - the output path of the nix derivation when the module ID is build via `nix build .#<module ID>` at the
         corresponding commit

## Upgrade Maps

*Upgrade maps* is our system for configuring automatic or recommended upgrades to modules. These are configured in
`pkgs/upgrade-maps`. They look like:

```
"bun-0.5:v1-20230522-49470df" = { to = "bun-0.5:v2-20230522-0f45db1"; auto = true; changelog = "A better lsp!"; };
"bun-0.5:v2-20230522-0f45db1" = { to = "bun-0.5:v3-20230522-9e0a3f9"; auto = true; changelog = "bug fix"; };
"nodejs-16:v1-20230522-49470df" = { to = "nodejs-16:v2-20230522-4c01fa0"; auto = true; changelog = "improved your experience"; };
"nodejs-14:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 14 is deprecated. Upgrade to 18!"; };
"nodejs-16:v3-20230522-36692ed" = { to = "nodejs-18:v3-20230522-36692ed"; changelog = "Node.js 16 is deprecated. Upgrade to 18!"; };
```

This mapping will be split into 2 files: `auto-upgrade.json` and `recommend-upgrade.json`. Both will be placed in
`/etc/nixmodules` in each Repl. The module resolver in pid1 will use `auto-upgrade.json` to automatically upgrade modules for users.
`recommend-upgrade.json` will be used by the repl-it-web frontend to prompt users to upgrade.

You can build these 2 files by:

```
nix build .#upgrade-maps
```

Or see them without building:

```
nix eval .#upgrade-maps.auto --json
nix eval .#upgrade-maps.recommend --json
```

## Active Modules

*Active modules* is a hydrated version of the currently active modules to be used in the module registry UI.
It will build named `active-modules.json` and will build placed in `/etc/nixmodules` in each Repl.
It contains for each module:
* name - human name for the module
* description - description for the module
* tag - the version tag consisting of `v<version>-<date>-<short commit>`
* version - numeric version
* commit - full git commit
* path - Nix output path
* tags - all historical tags

To build it:

```
nix build .#active-modules
```

or see it without building:

```
nix eval .#active-modules.info --json | jq
```

## Handling Conflicts in `modules.json`

The `lock_modules.py` scripts uses auto-increment counters to give numeric versions to each module. This means
if there are 2 simultaneous PRs modifying the same module(s), the first one to merge wins and gets the next number.
This is a race condition! For this reason, hand-merging `modules.json` is a bad idea.

We have CI checks in place to ensure:

1. you cannot merge a PR if it's not in sync with `main`
2. the commits referenced in `modules.json` all exist in the linear history of your branch
3. `modules.json` is up to date wrt the contents of your branch

When you have a conflict in `modules.json` you should:

1. take the version from upstream in its entirety
2. commit
3. re-run `python scripts/lock_modules.py`
4. make another commit

To do the above you can either rebase or merge.

With the rebase approach (pros: do without a merge commit):
```
git fetch
git rebase origin/main
git checkout --ours modules.json
git add modules.json
# resolve other conflicts if needed
git rebase --continue
python scripts/lock_modules.py
git commit -am "updated X in modules.json"
git push --force
```

With the merge approach (pros: don't have to force push):
```
git fetch
git merge origin/main
git checkout --theirs modules.json
git add modules.json
# resolve other conflicts if needed
git commit
python scripts/lock_modules.py
git commit -am "updated X in modules.json"
git push
```
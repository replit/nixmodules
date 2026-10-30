import argparse
import gzip
import importlib.util
import json
import pathlib
import re
import shutil
import stat
import sys
import tarfile
import tempfile


def cache_files(cache):
    if cache.is_symlink() or not cache.is_dir():
        raise ValueError("cache must be a real directory")
    files = {}
    directories = {"nar", "realisations", "debuginfo", "log", "build-trace-v2"}
    for path in cache.rglob("*"):
        name = path.relative_to(cache).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISDIR(mode) and name in directories:
            continue
        if not stat.S_ISREG(mode):
            raise ValueError(f"cache entry is not a regular file or cache directory: {name}")
        if not (
            name == "nix-cache-info"
            or re.fullmatch(r"[0-9abcdfghijklmnpqrsvwxyz]{32}\.narinfo", name)
            or re.fullmatch(r"nar/[0-9a-zA-Z._-]+", name)
        ):
            raise ValueError(f"unexpected cache file: {name}")
        files[name] = path
    if (
        "nix-cache-info" not in files
        or not any(name.endswith(".narinfo") for name in files)
        or not any(name.startswith("nar/") for name in files)
    ):
        raise ValueError("cache must contain nix-cache-info, narinfo and NAR files")
    return files


def write_layer(cache, manifest, layer):
    files = {"nix-cache/" + name: path for name, path in cache_files(cache).items()}
    files["etc/nixmodules/runtime-manifest.json"] = manifest
    directories = {
        ".", "etc", "etc/nixmodules", "nix-cache", "nix-cache/nar",
        "nix-cache/realisations", "nix-cache/debuginfo", "nix-cache/log",
        "nix-cache/build-trace-v2",
    }
    # Stream the supplied NAR bytes into the layer, without another full cache copy.
    with layer.open("wb") as output:
        with gzip.GzipFile(filename="", fileobj=output, mode="wb", mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w|", format=tarfile.PAX_FORMAT) as archive:
                for name in sorted(directories | files.keys()):
                    entry = tarfile.TarInfo("." if name == "." else "./" + name)
                    entry.uid = entry.gid = 11000
                    entry.mtime = 1
                    if name in directories:
                        entry.type = tarfile.DIRTYPE
                        entry.mode = 0o755
                        archive.addfile(entry)
                    else:
                        entry.mode = 0o444
                        entry.size = files[name].stat().st_size
                        with files[name].open("rb") as source:
                            archive.addfile(entry, source)


def assemble(cache, output, manifest, architecture, metadata, layout):
    cache = cache.absolute()
    output = output.absolute()
    if output.resolve().is_relative_to(cache.resolve()):
        raise ValueError("output must not be inside the input cache")
    cache_files(cache)
    output.mkdir()
    try:
        (output / "blobs/sha256").mkdir(parents=True)
        with tempfile.TemporaryDirectory(prefix="runtime-oci-", dir=output.parent) as temporary:
            layer = pathlib.Path(temporary) / "layer.tar.gz"
            write_layer(cache, manifest, layer)
            layout.write_layout(layer, output, architecture, metadata)
    except BaseException:
        shutil.rmtree(output)
        raise


if __name__ == "__main__":
    manifest, layout_script, architecture, metadata = sys.argv[1:5]
    parser = argparse.ArgumentParser(description="Package a preverified signed native file cache")
    parser.add_argument("--cache", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args(sys.argv[5:])
    specification = importlib.util.spec_from_file_location("layout", layout_script)
    layout = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(layout)
    try:
        assemble(args.cache, args.output, pathlib.Path(manifest), architecture, json.loads(metadata), layout)
    except (ValueError, OSError) as error:
        raise SystemExit(str(error)) from None

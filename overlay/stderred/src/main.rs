//! A wrapper to preload stderred without resorting to LD_PRELOAD.
//!
//! Make sure the `STDERRED_PATH` environment variable is set to the
//! (full) path of the stderred library. Also, since this program
//! uses [`clap`], add a `--` just before the program:
//!
//! ```shell
//! stderred -- prybar-python3 -q --ps1 $'🐍 \001\033[33m\002\001\033[00m\002 ' -i
//! ```

use std::env;
use std::ffi;
use std::fs;
use std::path;

use anyhow::{anyhow, bail, Context, Result};
use clap::Parser;
use itertools::Itertools;
use memmap;
use nix::unistd;
use xmas_elf;

/// A wrapper to preload stderred without using the LD_PRELOAD
/// environment variable.
#[derive(Parser, Debug)]
struct Args {
    /// Name of the executable.
    name: String,

    /// Arguments for the executable.
    args: Vec<String>,
}

/// Similar to bash's `which`, finds an executable in $PATH if the path
/// is not absolute.
fn which<P>(executable_name: P) -> Option<path::PathBuf>
where
    P: AsRef<path::Path>,
{
    if executable_name.as_ref().is_absolute() {
        return Some(path::PathBuf::from(executable_name.as_ref()));
    }
    env::var_os("PATH").and_then(|paths| {
        env::split_paths(&paths).find_map(|dir| {
            let executable_path = dir.join(&executable_name);
            if executable_path.is_file() {
                Some(executable_path)
            } else {
                None
            }
        })
    })
}

/// Gets the interpreter for the ELF file. It's going to be
/// ld-linux-x86-64.so.2, but the path may change if it's sourced
/// from nix.
fn get_interpreter(elf: &xmas_elf::ElfFile) -> Result<path::PathBuf> {
    // Unfortunately, xmas_elf does not return errors in a format
    // that is compatible with anyhow's context wrappers, since they
    // are only raw static strings.
    let interpreter_path = elf
        .program_iter()
        .find_map(|program_header| match program_header {
            xmas_elf::program::ProgramHeader::Ph32(ph) => match ph.get_type() {
                Err(err) => Some(Err(anyhow!("get elf type for header {:?}: {:#}", ph, err))),
                Ok(xmas_elf::program::Type::Interp) => {
                    match ffi::CStr::from_bytes_with_nul(ph.raw_data(elf)) {
                        Err(err) => Some(Err(anyhow!("get data for header {:?}: {:#}", ph, err))),
                        Ok(segment_data) => Some(Ok(segment_data)),
                    }
                }
                Ok(_) => None,
            },
            xmas_elf::program::ProgramHeader::Ph64(ph) => match ph.get_type() {
                Err(err) => Some(Err(anyhow!("get elf type for header {:?}: {:#}", ph, err))),
                Ok(xmas_elf::program::Type::Interp) => {
                    match ffi::CStr::from_bytes_with_nul(ph.raw_data(elf)) {
                        Err(err) => Some(Err(anyhow!("get data for header {:?}: {:#}", ph, err))),
                        Ok(segment_data) => Some(Ok(segment_data)),
                    }
                }
                Ok(_) => None,
            },
        })
        .transpose()?
        .ok_or_else(|| anyhow!("could not find interpreter"))?;
    Ok(path::PathBuf::from(interpreter_path.to_str()?))
}

fn main() -> Result<()> {
    let args = Args::parse();
    let executable_path = match which(&args.name) {
        None => bail!("{} not found in $PATH", &args.name),
        Some(executable_path) => executable_path,
    };

    let executable = fs::File::open(&executable_path)
        .with_context(|| anyhow!("open({:?})", &executable_path))?;
    let executable_mmap = unsafe { memmap::Mmap::map(&executable) }
        .with_context(|| anyhow!("mmap({:?})", &executable_path))?;
    let elf = match xmas_elf::ElfFile::new(&executable_mmap[..]) {
        Ok(elf) => elf,
        Err(err) => bail!("parse elf {:?}: {:#}", &executable_path, err),
    };

    let interpreter_path = get_interpreter(&elf)
        .with_context(|| anyhow!("get interpreter for {:?}", &executable_path))?;

    // Finally, build the execve(2) arguments.
    let args: Vec<ffi::CString> = [
        &vec![
            String::from(
                interpreter_path
                    .to_str()
                    .ok_or_else(|| anyhow!("{:?} is not valid unicode", &interpreter_path))?,
            ),
            String::from("--argv0"),
            args.name.clone(),
            String::from("--preload"),
            env::var("STDERRED_PATH").with_context(|| anyhow!("getenv(STDERRED_PATH)"))?,
            executable_path
                .to_str()
                .ok_or_else(|| anyhow!("{:?} is not valid unicode", &executable_path))?
                .to_string(),
        ][..],
        &args.args[..],
    ]
    .concat()
    .iter()
    .map(|s| ffi::CString::new(s.clone()))
    .try_collect()?;
    let env: Vec<ffi::CString> = env::vars()
        .map(|(key, value)| ffi::CString::new(format!("{}={}", key, value)))
        .try_collect()?;

    unistd::execve(args[0].as_ref(), args.as_ref(), env.as_ref())
        .with_context(|| anyhow!("execve({:?}, {:?})", &args, &env))?;

    Ok(())
}

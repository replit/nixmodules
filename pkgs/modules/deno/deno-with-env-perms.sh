arg0="$0"
scriptName=$(basename "$arg0")

function print_help() {
	echo "Usage: $scriptName [--help] [options...] [files...]"
	echo ""
	echo "Runs a deno program, pulling permissions from the environment."
	echo ""
	echo "Deno permissions are controlled by flags. This script translates environment"
	echo "variables into command-line arguments for the deno cli. If none of these"
	echo "environment variables are set, defaults to --allow-all."
	echo "See https://deno.land/manual@v1.36.3/basics/permissions for more info."
	echo ""
	echo "The optional file parameter is passed to deno. If not provided, will look for"
	echo "a task called 'start' in deno.json. If that's not provided, will look for a"
	echo "file called 'main.ts' or 'index.ts' and run that file."
	echo ""
	echo "Options provided will be passed to deno."
	echo ""
	echo "Environment variables:"
	echo "  DENO_ALLOW: equivalent to --allow-all"
	echo "    '1': will allow the Deno program to access all permissions"
	echo "      note: this is the default if no other environment variables are set"
	echo "    '0': don't allow any permissions by default"
	echo "      note: this is the default if any other environment variables are set"
	echo "    comma-separated list of permissions: will allow the Deno program to "
	echo "      access only the specified permissions without further granularity."
	echo "      See below for a list of permissions and how to make permissions more"
	echo "      granular."
	echo ""
	echo "  DENO_ALLOW_ENV: equivalent to --allow-env"
	echo "    '1': will allow the Deno program to access all environment variables"
	echo "    comma-separated list of environment variable names: will allow the Deno"
	echo "      program to access only the specified environment variables."
	echo ""
	echo "  DENO_ALLOW_SYS: equivalent to --allow-sys"
	echo "    '1': will allow the Deno program to access all system resource APIs"
	echo "    comma-separated list of system resource names: will allow the Deno"
	echo "      program to access only the specified system resource APIs."
	echo ""
	echo "  DENO_ALLOW_HRTIME: equivalent to --allow-hrtime"
	echo "    '1': will allow the Deno program to access high resolution time"
	echo "      measurement"
	echo ""
	echo "  DENO_ALLOW_NET: equivalent to --allow-net"
	echo "    '1': will allow the Deno program to access all network addresses"
	echo "    comma-separated list of network addresses: will allow the Deno program"
	echo "      to access only the specified network addresses. May be IP addresses"
	echo "      or hostnames."
	echo ""
	echo "  DENO_ALLOW_FFI: equivalent to --allow-ffi"
	echo "    '1': will allow the Deno program to access all foreign function"
	echo "      interfaces."
	echo "    comma-separated list of paths: will allow the Deno program to access"
	echo "      only foreign function interfaces available in specified paths."
	echo ""
	echo "  DENO_ALLOW_READ: equivalent to --allow-read"
	echo "    '1': will allow the Deno program to read all files"
	echo "    comma-separated list of paths: will allow the Deno program to read"
	echo "      only specific paths"
	echo ""
	echo "  DENO_ALLOW_RUN: equivalent to --allow-run"
	echo "    '1': will allow the Deno program to run all subprocesses"
	echo "    comma-separated list of names: will allow the Deno program to run"
	echo "      only subprocesses with specific names."
	echo ""
	echo "  DENO_ALLOW_WRITE: equivalent to --allow-write"
	echo "    '1': will allow the Deno program to write all files"
	echo "    comma-separated list of paths: will allow the Deno program to write"
	echo "      only to specified paths."
}

args=()
while [[ "${#@}" -gt 0 ]]; do
	case "$1" in
		-h|--help)
			print_help
			exit 127
			;;
		--)
			shift
			args+=("$@")
			break
			;;
		*)
			args+=("$1")
			shift
			;;
	esac
done

# read permissions to use
perms=()

if [ "${DENO_ALLOW-}" == "1" ]; then
	perms+=("--allow-all")
elif [ "${DENO_ALLOW-}" != "0" ] && [ -n "${DENO_ALLOW-}" ]; then
	IFS=,
	for perm in $DENO_ALLOW; do
		perms+=("--allow-$perm")
	done
fi

function check_perm() {
	local env_var="$1"; shift
	local flag="$1"; shift

	case "${!env_var-}" in
		"1")
			perms+=("$flag")
			;;
		"0" | "")
			;;
		*)
			perms+=("$flag=${!env_var}")
			;;
	esac
}

check_perm DENO_ALLOW_ENV --allow-env
check_perm DENO_ALLOW_SYS --allow-sys
check_perm DENO_ALLOW_HRTIME --allow-hrtime
check_perm DENO_ALLOW_NET --allow-net
check_perm DENO_ALLOW_FFI --allow-ffi
check_perm DENO_ALLOW_READ --allow-read
check_perm DENO_ALLOW_RUN --allow-run
check_perm DENO_ALLOW_WRITE --allow-write

deno run "${perms[@]}" "${args[@]}"

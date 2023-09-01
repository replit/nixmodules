if [[ "$1" == "--help" ]]; then
	echo "Usage: deno-env-permissions [--help] [file] -- [options]"
	echo ""
	echo "Runs a deno program, pulling permissions from the environment."
	echo ""
	echo "Deno permissions are controlled by flags. This script translates environment"
	echo "variables into command-line arguments for the deno cli. If none of these"
	echo "environment variables are set, defaults to --allow-all."
	echo "See https://deno.land/manual@v1.36.3/basics/permissions for more info."
	echo ""
	echo "The optional file parameter is passed to deno. If not provided, will look for a"
	echo "task called 'start' in deno.json. If that's not provided, will look for a file"
	echo "called 'main.ts' or 'index.ts' and run that file."
	echo ""
	echo "Options provided will be passed to deno."
	echo ""
	echo "Environment variables:"
	echo "  DENO_ALLOW: equivalent to --allow-all"
	echo "    '1': will allow the Deno program to access all permissions"
	echo "      note: this is the default if no other environment variables are set"
	echo "    '0': don't allow any permissions by default"
	echo "      note: this is the default if any other environment variables are set"
	echo "    comma-separated list of permissions: will allow the Deno program to access"
	echo "      only the specified permissions without further granularity. See below for a"
	echo "      list of permissions and how to make permissions more granular."
	echo ""
	echo "  DENO_ALLOW_ENV: equivalent to --allow-env"
	echo "    '1': will allow the Deno program to access all environment variables"
	echo "    comma-separated list of environment variable names: will allow the Deno"
	echo "      program to access only the specified environment variables."
	echo ""
	echo "  DENO_ALLOW_SYS: equivalent to --allow-sys"
	echo "    '1': will allow the Deno program to access all system resource APIs"
	echo "    comma-separated list of system resource names: will allow the Deno program"
	echo "      to access only the specified system resource APIs."
	echo ""
	echo "  DENO_ALLOW_HRTIME: equivalent to --allow-hrtime"
	echo "    '1': will allow the Deno program to access high resolution time measurement"
	echo ""
	echo "  DENO_ALLOW_NET: equivalent to --allow-net"
	echo "    '1': will allow the Deno program to access all network addresses"
	echo "    comma-separated list of network addresses: will allow the Deno program to"
	echo "      access only the specified network addresses. May be IP addresses or"
	echo "      hostnames."
	echo ""
	echo "  DENO_ALLOW_FFI: equivalent to --allow-ffi"
	echo "    '1': will allow the Deno program to access all foreign function interfaces"
	echo "    comma-separated list of paths: will allow the Deno program to access only"
	echo "      foreign function interfaces available in specified paths."
	echo ""
	echo "  DENO_ALLOW_READ: equivalent to --allow-read"
	echo "    '1': will allow the Deno program to read all files"
	echo "    comma-separated list of paths: will allow the Deno program to read only"
	echo "      specific paths"
	echo ""
	echo "  DENO_ALLOW_RUN: equivalent to --allow-run"
	echo "    '1': will allow the Deno program to run all subprocesses"
	echo "    comma-separated list of names: will allow the Deno program to run only"
	echo "      subprocesses with specific names."
	echo ""
	echo "  DENO_ALLOW_WRITE: equivalent to --allow-write"
	echo "    '1': will allow the Deno program to write all files"
	echo "    comma-separated list of paths: will allow the Deno program to write only to"
	echo "      specified paths."
	echo ""

	# TODO: support --deny flags

	exit 0
fi

perms=()

if [ -v DENO_ALLOW ]; then
	case "$DENO_ALLOW" in
		"1")
			perms+=("--allow-all")
			;;
		"0")
			;;
		*)
			for perm in $(echo "$DENO_ALLOW" | tr "," "\n"); do
				perms+=("--allow-$perm")
			done
			;;
	esac
else
	perms+=("--allow-all")
fi

if [ -v DENO_ALLOW_ENV ]; then
	case "$DENO_ALLOW_ENV" in
		"1")
			perms+=("--allow-env")
			;;
		*)
			perms+=("--allow-env=$DENO_ALLOW_ENV")
			;;
	esac
fi

if [ -v DENO_ALLOW_SYS ]; then
	case "$DENO_ALLOW_SYS" in
		"1")
			perms+=("--allow-sys")
			;;
		*)
			perms+=("--allow-sys=$DENO_ALLOW_SYS")
			;;
	esac
fi

if [ -v DENO_ALLOW_HRTIME ]; then
	case "$DENO_ALLOW_HRTIME" in
		"1")
			perms+=("--allow-hrtime")
			;;
	esac
fi

if [ -v DENO_ALLOW_NET ]; then
	case "$DENO_ALLOW_NET" in
		"1")
			perms+=("--allow-net")
			;;
		*)
			perms+=("--allow-net=$DENO_ALLOW_NET")
			;;
	esac
fi

if [ -v DENO_ALLOW_FFI ]; then
	case "$DENO_ALLOW_FFI" in
		"1")
			perms+=("--allow-ffi")
			;;
		*)
			perms+=("--allow-ffi=$DENO_ALLOW_FFI")
			;;
	esac
fi

if [ -v DENO_ALLOW_READ ]; then
	case "$DENO_ALLOW_READ" in
		"1")
			perms+=("--allow-read")
			;;
		*)
			perms+=("--allow-read=$DENO_ALLOW_READ")
			;;
	esac
fi

if [ -v DENO_ALLOW_RUN ]; then
	case "$DENO_ALLOW_RUN" in
		"1")
			perms+=("--allow-run")
			;;
		*)
			perms+=("--allow-run=$DENO_ALLOW_RUN")
			;;
	esac
fi

if [ -v DENO_ALLOW_WRITE ]; then
	case "$DENO_ALLOW_WRITE" in
		"1")
			perms+=("--allow-write")
			;;
		*)
			perms+=("--allow-write=$DENO_ALLOW_WRITE")
			;;
	esac
fi

file="$1"
shift
case "$file" in
	"--")
		unset file
		shift
		;;
	"")
		;;
	*)
		shift
		;;
esac

eval deno run "${perms[@]}" "$@" "$file"

set -e

if [ $# -eq 0 ]; then
    echo "Please provide a module file argument"
    exit 1
fi

MODULE_FILE="$1"
OUTPUT_FILE="$2"

MODULE_FILE_ABSOLUTE_PATH="$(realpath $MODULE_FILE)"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENTRYPOINT_PATH="$SCRIPT_DIR/entrypoint.nix"

args=("$ENTRYPOINT_PATH" --argstr configPath "$MODULE_FILE_ABSOLUTE_PATH")

if [ ! -z "${OUTPUT_FILE}" ]; then
  args+=(--out-link "${OUTPUT_FILE}")

  if [[ -f "${OUTPUT_FILE}" ]]; then
    rm -f "${OUTPUT_FILE}"
  fi
fi

echo "nix-build ${args[@]}"
nix-build "${args[@]}"

if [ $? -ne 0 ]
then
  exit 1
fi

if [ -L "${OUTPUT_FILE}" ]; then
  # If output link was provided,
  # materialize the output as an actual file containing the JSON config
  # instead of a symlink
  cp --remove-destination "$(realpath "${OUTPUT_FILE}")" "${OUTPUT_FILE}"
fi

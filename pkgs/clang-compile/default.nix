{ pkgs, clang }:
pkgs.writeShellScriptBin "clang-compile" ''
  FILE="$1"     # a .c or .cpp file
  LANG="$2"     # lang can be:
                #   c - C
                #   cpp - C++
  MODE="$3"     # mode can be:
                #   single - compile just one .c file, or
                #   all - compile all .c files
  DEBUG="$4"    # debug can be:
                #   debug - compile with no optimization
                #   (empty) - compile regularly

  if [[ ! -f "$FILE" ]]; then
    echo "$FILE not found"
    exit 1
  fi

  if [[ "$MODE" == "all" ]]; then
    if [[ "$LANG" == "c" ]]; then
      SRCS=$(find . -name '.ccls-cache' -type d -prune -o -type f -name '*.c' -print)
    elif [[ "$LANG" == "cpp" ]]; then
      SRCS=$(find . -name '.ccls-cache' -type d -prune -o -type f -name '*.cpp' -print)
    else
      echo "Invalid LANG parameter: $LANG"
      exit 1
    fi
  else
    SRCS="$FILE"
  fi

  CFLAGS="$CFLAGS -g -Wno-everything -pthread -lm"
  if [[ "$DEBUG" == "debug" ]]; then
    CFLAGS="$CFLAGS -O0"
  fi

  if [[ "$LANG" == "c" ]]; then
    COMPILER="${clang}/bin/clang"
    COMPILER_NAME="clang"
  elif [[ "$LANG" == "cpp" ]]; then
    COMPILER="${clang}/bin/clang++"
    COMPILER_NAME="clang++"
  else
    echo "Invalid LANG parameter: $LANG"
    exit 1
  fi

  rm -f ''$FILE.bin
  echo $COMPILER_NAME $CFLAGS $SRCS -o "''$FILE.bin"
  $COMPILER $CFLAGS $SRCS -o "''$FILE.bin"
''

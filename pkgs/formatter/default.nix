{ pkgs }:

pkgs.writeShellApplication {
  name = "parse-formatter-options";
  runtimeInputs = [ pkgs.bash ];
  text = ''
    #!/bin/bash

    # Initialize variables
    apply="false"
    file=""
    insertFinalNewline="false"
    insertSpaces="false"
    rangeStart=""
    rangeEnd=""
    stdinMode="false"
    tabSize=""
    trimFinalNewlines="false"
    trimTrailingWhitespace="false"

    # Function to print usage
    print_usage() {
      echo "Usage: $0 [-a|--apply] -f|--file <filename> [--stdin] [--range-start <offset>] [--range-end <offset>] [--tab-size <number>] [--insert-spaces] [--trim-trailing-whitespace] [--insert-final-newline] [--trim-final-newlines]"
      echo
      echo "Options:"
      echo "  -h, --help                     Show this help message and exit"
      echo "  -a, --apply                    Apply edits directly to the file (optional)"
      echo "  -f, --file <filename>          Specify the file to be formatted (required)"
      echo "      --stdin                    Read file input from stdin (optional)"
      echo "      --insert-final-newline     Insert a newline at the end of the file if one does not exist (optional)"
      echo "      --insert-spaces            Prefer spaces over tabs (optional)"
      echo "      --range-start <offset>     Specify the character offset for formatting (optional, requires --range-end)"
      echo "      --range-end <offset>       Specify the character offset for formatting (optional, requires --range-start)"
      echo "      --tab-size <number>        Size of a tab in spaces (optional)"
      echo "      --trim-final-newlines      Trim all newlines after the final newline at the end of the file (optional)"
      echo "      --trim-trailing-whitespace Trim trailing whitespace on a line (optional)"

    }

    # Function to check if a value is a number
    is_number() {
      [[ "$1" =~ ^[0-9]+$ ]]
    }

    # Parse command-line arguments
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        -a|--apply)
          apply="true"
          shift
          ;;
        -f|--file)
          file="$2"
          shift 2
          ;;
        -h|--help)
          print_usage
          exit 0
          ;;
        --stdin)
          stdinMode="true"
          shift
          ;;
        --range-start)
          if is_number "$2"; then
            rangeStart="$2"
          else
            echo "Error: --range-start must be a number."
            print_usage
            exit 1
          fi
          shift 2
          ;;
        --range-end)
          if is_number "$2"; then
            rangeEnd="$2"
          else
            echo "Error: --range-end must be a number."
            print_usage
            exit 1
          fi
          shift 2
          ;;
        --tab-size)
          if is_number "$2"; then
            tabSize="$2"
          else
            echo "Error: --tab-size must be a number."
            print_usage
            exit 1
          fi
          shift 2
          ;;
        --insert-spaces)
          insertSpaces="true"
          shift
          ;;
        --trim-trailing-whitespace)
          trimTrailingWhitespace="true"
          shift
          ;;
        --insert-final-newline)
          insertFinalNewline="true"
          shift
          ;;
        --trim-final-newlines)
          trimFinalNewlines="true"
          shift
          ;;

        # TODO: Legacy from frontend, clean up
        --tab-width)
          if is_number "$2"; then
            tabSize="$2"
          fi
          shift 2
          ;;
        --use-tabs)
          if "$2"; then
            insertSpaces="false"
          else
            insertSpaces="true"
          fi
          shift 2
          ;; 
        --stdin-filepath)
          stdinMode="true"
          shift
          ;;
        
        # Ignore all other arguments
        *)
          shift
          ;;
      esac
    done

    # Validate required arguments
    if [[ -z "$file" ]]; then
      echo "Error: File argument is required."
      print_usage
      exit 1
    fi

    # Further validate that both rangeStart and rangeEnd are provided together, if at all
    if [[ -n "$rangeStart" && -z "$rangeEnd" ]] || [[ -z "$rangeStart" && -n "$rangeEnd" ]]; then
      echo "Error: Both --range-start and --range-end must be provided together."
      print_usage
      exit 1
    fi


    # Export for use in sub-scripts
    export apply
    export file
    export insertFinalNewline
    export insertSpaces
    export rangeStart
    export rangeEnd
    export stdinMode
    export tabSize
    export trimFinalNewlines
    export trimTrailingWhitespace
  '';
}

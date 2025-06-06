{ pkgs, ... }:
{

  home.packages = [
    (pkgs.writeShellScriptBin "gclb" ''

      # Adapted from https://github.com/nicknisi/dotfiles/blob/78ff314518cfd8ee46683ae91a21f9a218ccd5dc/bin/git-bare-clone

      set -Eeuo pipefail
      trap cleanup SIGINT SIGTERM ERR EXIT

      usage() {
        cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
      Usage: ''$(
          basename "''${BASH_SOURCE[0]}") [-h] [-v] [-l] repository

      Clone a bare git repo and set up environment for working comfortably and exclusively from worktrees.

      Available options:

      -h, --help      Print this help and exit
      -v, --verbose   Print script debug info
      -l, --location  Location of the bare repo contents (default: .bare)
      EOF
        exit
      }

      cleanup() {
        trap - SIGINT SIGTERM ERR EXIT
      }

      setup_colors() {
        if [[ -t 2 ]] && [[ -z "''${NO_COLOR-}" ]] && [[ "''${TERM-}" != "dumb" ]]; then
          NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
        else
          NOFORMAT="" RED="" GREEN="" ORANGE="" BLUE="" PURPLE="" CYAN="" YELLOW=""
        fi
      }

      msg() {
        echo >&2 -e "''${1-}"
      }

      die() {
        local msg=''$1
        local code=''${2-1} # default exit status 1
        msg "''$msg"
        exit "''$code"
      }

      parse_params() {
        location='.bare'

        while :; do
          case "''${1-}" in
          -h | --help) usage ;;
          -v | --verbose) set -x ;;
          --no-color) NO_COLOR=1 ;;
          -l | --location)
            location="''${2-}"
            shift
            ;;
          -?*) die "Unknown option: ''$1" ;;
          *) break ;;
          esac
          shift
        done

        args=("''$@")

        # check required params and arguments
        # [[ -z "''${param-}" ]] && die "Missing required parameter: param"
        [[ ''${#args[@]} -eq 0 ]] && die "Missing script arguments"

        return 0
      }

      parse_params "''$@"
      setup_colors

      msg "''${YELLOW}Cloning bare repository to ''$location...''${NOFORMAT}"
      git clone --bare "''${args[@]}" "''$location"
      pushd "''$location" >/dev/null
      msg "''${YELLOW}Adjusting origin fetch locations...''${NOFORMAT}"
      git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
      popd >/dev/null
      msg "''${YELLOW}Setting .git file contents...''${NOFORMAT}"
      echo "gitdir: ./''$location" >.git
      msg "''${GREEN}Success.''${NOFORMAT}"
    '')
  ];
}

#!/usr/bin/env zsh

ghu-rm() {
  -ghu-rm-usage() {
    cat <<'EOT'
Usage: ghu rm [-f] [-h]

  -h     Print this help
  -f     Force remove repo(s)
EOT
  }

  # Sanitize args
  shift

  local esc="$(printf "\033")"
  local fg_blue=34
  local fg_red=31
  local _m="m"
  local default="[${_DEFAULT}${_m}"
  local force=false

  local OPTARG OPTIND args
  while getopts ':fh' args; do
    case "$args" in
      f)
        force=true
        ;;
      h)
        -ghu-rm-usage
        return 0
        ;;
      *)
        -ghu-rm-usage 1>&2
        return 1
        ;;
    esac
  done

  -ghu-rm-ask-yes-no() {
    local msg="$1"
    local yes_no

    # FIXME: read -p not work?
    printf "$msg"
    read yes_no
    case "$yes_no" in
      yes)
        return 0
        ;;
      no)
        return 1
        ;;
      *)
        return 1
        ;;
    esac
  }

  -ghu-rm-test-is-repo-changed() {
    local msg
    # list changed file(s)
    msg=$(git -c status.color=always status --short 2>&1)

    if [[ $? -eq 0 && -z "$msg" ]]; then
      return 0
    else
      printf "${esc}[${fg_red}${_m}The repository is dirty:${esc}${default}\n"
      echo
      sed 's/^/  /' <<< "$msg"
      echo
      return 1
    fi
  }

  -ghu-rm-test-is-unpushed-commit-found() {
    # BUG? looks like initializing variable must be necessary
    local msg
    # list unpushed commit(s)
    msg=$(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline --color=always 2>&1)

    if [[ $? -eq 0 && -z "$msg" ]]; then
      return 0
    else
      printf "${esc}[${fg_red}${_m}There are unpushed commits:${esc}${default}\n"
      echo
      sed 's/^/  /' <<< "$msg"
      echo
      return 1
    fi
  }

  -ghu-rm-each-repo() {
    local fd="$1"
    local repo_path

    while read -u "$fd" -r repo_path; do
      printf "\n> ${esc}[${fg_blue}${_m}${repo_path}${esc}${default}\n"
      (
        cd "$repo_path"

        -ghu-rm-test-is-repo-changed
        -ghu-rm-test-is-unpushed-commit-found

        if [[ "$force" == true ]]; then
          rm -rf "$repo_path"
        else
          -ghu-rm-ask-yes-no "Are you sure you want to remove it? [yes/no] " \
          && rm -rf "$repo_path"
        fi
      )
    done
  }

  -ghu-rm-each-repo 3 3< <( ghq list --full-path | peco )
}

ghu-mk() {
  -ghu-mk-usage() {
    cat <<'EOT'
Usage: ghu mk -u <user> -g <git server> <repository> [-h]

  -h                  Print this help
  -u <user>           Specify your git user name (default local user name)
  -g <git server>     Specify git server name (default github.com)
EOT
  }

  # Sanitize args
  shift

  local user_name="$(whoami)"
  local git_server="github.com"

  local OPTARG OPTIND args
  while getopts ':u:g:h' args; do
    case "$args" in
      u)
        user_name="$OPTARG"
        ;;
      g)
        git_server="$OPTARG"
        ;;
      h)
        -ghu-mk-usage
        return 0
        ;;
      *)
        -ghu-mk-usage
        return 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  local repository="$1"
  if [[ -z "$repository" ]]; then
    -ghu-mk-usage
    return 1
  fi

  local ghq_path="$(ghq root)/${git_server}/${user_name}/${repository}"

  if [[ -d "$ghq_path" ]]; then
    echo "${ghq_path}: already exists." 1>&2
    return 1
  else
    mkdir -p "$ghq_path" \
    && cd "$ghq_path"    \
    && git init
  fi
}

ghu-for() {
  -ghu-for-usage() {
    cat <<'EOT'
Usage: ghu for {-g <git command>|-c <shell command>} [-h]

  -h                     Print this help
  -g <git command>       Execute git command
  -c <shell command>     Execute shell command
EOT
  }

  # Sanitize args
  shift

  local esc="$(printf "\033")"
  local fg_blue="34"
  local _m="m"
  local default="[${_DEFAULT}${_m}"
  local git_cmd
  local shell_cmd

  local OPTARG OPTIND args
  while getopts ":g:c:h" args; do
    case "$args" in
      g)
        git_cmd="$OPTARG"
        ;;
      c)
        shell_cmd="$OPTARG"
        ;;
      h)
        -ghu-for-usage
        return 0
        ;;
      *)
        -ghu-for-usage 1>&2
        return 1
        ;;
    esac
  done

  [[ -z "$git_cmd" && -z "$shell_cmd" ]] && { -ghu-for-usage 1>&2; return 1; }
  [[ -n "$git_cmd" && -n "$shell_cmd" ]] && { -ghu-for-usage 1>&2; return 1; }

  local repo
  ghq list --full-path | while read -r repo; do
    (
      cd "$repo"
      printf "${esc}[${fg_blue}${_m}$(pwd)${esc}${default}\n"
      if [[ -n "$git_cmd" ]]; then
        git "$git_cmd"
      else
        $shell_cmd
      fi
    )
  done
}

ghu() {
  -ghu-usage() {
    cat <<'EOT'
Usage: ghu [-h] COMMAND [<args>]

ghq utility

Commands:

  rm    Remove ghq repo(s) with peco style selecting
  mk    Create ghq repo
  for   Execute commands in ghq repo(s)

Run 'ghu COMMAND -h' for more information on a command.
EOT
  }

  local required_cmd
  for required_cmd in "ghq" "peco"; do
    if ! type "$required_cmd" &>/dev/null; then
      echo "$required_cmd command not found in your $PATH." 1>&2
      return 1
    fi
  done

  local cmd="$1"
  if functions "ghu-${cmd}" &>/dev/null; then
    "ghu-${cmd}" "$@"
  else
    if [[ "$@" =~ "-h" ]]; then
      -ghu-usage
      return 0
    else
      -ghu-usage 1>&2
      return 1
    fi
  fi
}

_ghu() {
  local -a _1st_arguments
  _1st_arguments=(
    'rm:Remove ghq repo(s) with peco style selecting'
    'mk:Create ghq repo and git init'
    'for:Execute commands in ghq repo(s)'
  )

  __rm() {
    _arguments \
      '-f[Force remove repo(s)]'
  }

  __mk() {
    _arguments \
      '-u=[(local user) Git user name]' \
      '-g=[(github.com) Git server hostname]'
  }

  __for() {
    _arguments \
      '-g=[Git commands]' \
      '-c=[Shell commands]'
  }

  _arguments '*:: :->command'

  if (( CURRENT == 1 )); then
    _describe -t commands "ghu command" _1st_arguments
    return
  fi

  local -a _command_args
  case "$words[1]" in
    rm)
      __rm
      ;;
    mk)
      __mk
      ;;
    for)
      __for
      ;;
  esac
}

compdef _ghu ghu

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et

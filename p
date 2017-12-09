#!/bin/bash

# Print a string in the specified color
__p_color () {
  declare -A colors
  colors[red]=$(tput setaf 1)
  colors[green]=$(tput setaf 2)
  colors[reset]=$(tput sgr0)

  local c=$1
  shift
  printf '%s' "${colors[$c]}"
  printf '%s\n' "$@"
  printf '%s' "${colors[reset]}"
}

# Print an error
__p_err () {
  __p_color red "error: $1" >&2
}

# Output an error and exit with nonzero status
__p_failwith () {
  __p_err "${2:-$1}"
  [ "$1" = "-u" ] && __p_usage
}

# Output an "in development" message
__p_indev () {
  __p_color green "$1 is still in development!"
  __p_usage
}

# Perform shell expansion on a given path
__p_exp () {
  exp=$(sh -c "cd $1; pwd" 2>&1)
  if [ ! $? ]; then
    echo $(cut -d' ' -f-1 <<< "$exp")
  else
    echo "$exp"
  fi
}

## usage
## ==========
## Prints the top-level usage instructions

__p_usage () {
  if [ "$1" = "--long" ]; then
    echo "Long usage coming soon!"
    __p_usage
  else
    echo "usage: $exe [<project>] [help|h] [<command> [<args>]]"
    echo ""
    echo "  Create and manage personal projects."
    echo "    $exe in a project directory will output project details."
    echo "    $exe <project> will switch to the directory for <project>."
    echo ""
    echo "Available commands (and shorthands):"
    echo "  archive, ar     Archive an active project"
    echo "  copy, cp        Copy an existing project"
    echo "  dump, d         Dump active project configuration to stdout"
    echo "  go, g           Go to a project directory by its name"
    echo "  list, ls        List your projects"
    echo "  restore, r      Restore a project configuration from a dump file"
    echo "  start, s        Start a new project"
    echo "  todo, t         Add and modify project TODOs"
    echo ""
    echo "  help, h         Show all commands, or get more help on one"
    echo ""
  fi
}


## commands_*_usage
## ================
## Functions for printing each command's usage

# usage output for p archive/ar
__p_commands_archive_usage () {
  echo "usage: $exe archive <project>"
}

# usage output for p copy/cp
__p_commands_copy_usage () {
  echo "usage: $exe copy <nameToCopy> [<newName>] [<args>]"
  echo "  Create a new project using an existing project's configuration."
  echo ""
  echo "Arguments:"
  echo "  <newname>            The name for the new project"
}

# usage output for p dump/d
__p_commands_dump_usage () {
  echo "usage: $exe dump [<args>]"
}

# usage output for p go/g
__p_commands_go_usage () {
  echo "usage: $exe go <project>"
}

# usage output for p list/ls
__p_commands_list_usage () {
  echo "usage: $exe list [<category>] [<args>]"
}

# usage output for p restore/r
__p_commands_restore_usage () {
  echo "usage: $exe restore [<dumpfile>]"
}

# usage output for p start/s
__p_commands_start_usage () {
  echo "usage: $exe start <name> [<args>]"
  echo "  Start a new project."
  echo ""
  echo "Arguments:"
  echo "  --with t1[,t2...]    Run the specified initializers after creating the project"
  echo "   -w t1[,t2...]         Available by default: git, gh, npm"
  echo "  --at <dir>           Path to the directory where the project will live"
  echo "   -a <dir>              Default: ~/projects/<name>"
  echo "  --bare, -b           Initialize the project with just a name (p won't ask for any"
  echo "                         other details)"
  echo "  --cd                 cd into the project directory after creation"
  echo "  --then <file>        Path to a custom script that will automatically be executed in"
  echo "                         the project directory after creation"
}

# usage output for p todo/t
__p_commands_todo_usage () {
  echo "usage: $exe todo [-x TASK_NUMBER] [TASK]"
}


## p
## =========
## The actual function to execute

p () {
  exe="p"
  P_DIR=$(__p_exp ~/.p)
  DEFAULT_PROJECT_DIR="~/projects"

  ## HELPERS
  ## ==========

  declare -A shortToLong
  shortToLong[ar]="archive"
  shortToLong[cp]="copy"
  shortToLong[d]="dump"
  shortToLong[g]="go"
  shortToLong[ls]="list"
  shortToLong[r]="restore"
  shortToLong[s]="start"
  shortToLong[t]="todo"

  declare -A longToShort
  longToShort[archive]="ar"
  longToShort[copy]="cp"
  longToShort[dump]="d"
  longToShort[go]="g"
  longToShort[list]="ls"
  longToShort[restore]="r"
  longToShort[start]="s"
  longToShort[todo]="t"

  ## EXECUTION
  ## ==========

  # save the entire command
  cmd="$@"

  # help command. show detailed instructions for specific commands,
  #   or long usage if no command is specified
  if [ "$1" = "help" ] || [ "$1" = "h" ]; then
    [ $# -ne 2 ] && __p_usage --long && return

    case $2 in
      "archive" | "ar" )
        __p_commands_archive_usage
        ;;
      "copy" | "cp" )
        __p_commands_copy_usage
        ;;
      "dump" | "d" )
        __p_commands_dump_usage
        ;;
      "go" | "g" )
        __p_commands_go_usage
        ;;
      "list" | "ls" )
        __p_commands_list_usage
        ;;
      "restore" | "r" )
        __p_commands_restore_usage
        ;;
      "start" | "s" )
        __p_commands_start_usage
        ;;
      "todo" | "t" )
        __p_commands_todo_usage
        ;;
      *)
        __p_failwith -u "unknown command: $2"
    esac

    return
  fi

  # Parse ~/.prc
  cur=1
  while read line; do
    [[ "$line" =~ ^# ]] && cur=$((cur + 1)) && continue
    lhs=$(cut -d'=' -f1 <<< "$line" | xargs)
    rhs=$(cut -d'=' -f2 <<< "$line" | xargs)
    case $lhs in
      "default_project_dir")
        DEFAULT_PROJECT_DIR=$(__p_exp "$rhs")
        ;;
      *)
        __p_failwith "Unknown command at line $cur in ~/.prc: $line" && return
    esac
    cur=$((cur + 1))
  done < ~/.prc

  # Read project configurations
  [ ! -f "$P_DIR/projects" ] && touch "$P_DIR/projects"
  PROJECTS=$(grep "^[A-Za-z_]" "$P_DIR/projects")

  # Print short usage if no arguments were provided
  if [ $# -lt 1 ]; then
    for p in $PROJECTS; do
      name=$(cut -d':' -f1 <<< "$p")
      dir=$(cut -d':' -f2 <<< "$p")
      if [[ "$(pwd)" =~ "$(__p_exp $dir)"* ]]; then
        echo "\"$name\" at $dir:"
        echo "  "
        return
      fi
    done
    __p_usage
    return
  fi

  # save the entire command
  cmd="$@"

  # Actually parse the command...
  case $1 in
    "archive" | "ar" )
      __p_indev $1
      ;;

    "copy" | "cp" )
      __p_indev $1
      ;;

    "dump" | "d" )
      __p_indev $1
      ;;

    "go" | "g" )
      [ $# -lt 2 ] && err "missing required project name" && __p_commands_go_usage && return
      [ $# -gt 2 ] && err "extra arguments not supported" && __p_commands_go_usage && return
      for p in $PROJECTS; do
        name=$(cut -d':' -f1 <<< "$p")
        dir=$(cut -d':' -f2 <<< "$p")
        if [ "$name" = "$2" ]; then
          cd $(__p_exp $dir)
          return
        fi
      done
      __p_failwith "no project named \"$2\"" && return
      ;;

    "list" | "ls" )
      if [ "$PROJECTS" = "" ]; then
        echo "You don't have any projects...yet!"
        echo
        echo "Start a new project with: $exe start"
      else
        for p in $PROJECTS; do
          name=$(cut -d':' -f1 <<< "$p")
          dir=$(cut -d':' -f2 <<< "$p")
          echo "\"$name\" at $dir:"
          echo "  "
        done
      fi
      ;;

    "restore" | "r" )
      __p_indev $1
      ;;

    # Start command. Start a new project.
    "start" | "s" )
      [ $# -lt 2 ] && __p_err "missing required project name" && __p_commands_start_usage && return
      name="$2"
      
      for p in $PROJECTS; do
        othername=$(cut -d':' -f1 <<< "$p")
        otherdir=$(cut -d':' -f2 <<< "$p")
        if [ "$name" = "$othername" ]; then
          err "project already exists: \"$othername\" at $otherdir" && return
          return
        fi
      done

      safename=${name//_/} # underscores
      safename=${safename// /_} # ' ' => _
      safename=${safename//[^a-zA-Z0-9_]/} # non alphanumeric
      safename=${safename,,} # lowercase
      dir="$DEFAULT_PROJECT_DIR/$safename"
      postcd=false

      # start looking for more args after the project name
      i=3
      while [ $i -le $# ]; do
        arg=$(cut -d' ' -f$i <<< "$@")
        i=$((i + 1))
        case $arg in
          "--with" | "-w" )
            __p_indev $arg && return
            i=$((i + 1))
            ;;
          "--at" | "-a" )
            [ $i -gt $# ] && err "missing path for --at/-a" && __p_commands_start_usage && return
            dir=$(cut -d' ' -f$i <<< "$@")
            i=$((i + 1))
            ;;
          "--cd" )
            postcd=true
            ;;
          "--then" )
            __p_indev $arg && return
            i=$((i + 1))
            ;;
          * )
            err "invalid argument: $arg" && __p_commands_start_usage && return
        esac
      done

      mkdir -p $(__p_exp "$dir")
      [ ! "$PROJECTS" = "" ] && echo >> "$P_DIR/projects"
      echo "$name:$dir" >> "$P_DIR/projects"
      echo "  cmd: $cmd" >> "$P_DIR/projects"
      [ $postcd ] && cd $(__p_exp "$dir")
      ;;

    "todo" | "t" )
      __p_indev $1
      ;;

    *)
      # TODO: if $1 is a project name, switch to its directory
      __p_failwith -u "unknown command: $1" && return
      ;;
  esac
}

#!/bin/bash

declare exe
if [[ $(which p) = *"/.p/p" ]]; then
  exe="p"
else
  exe=$0
fi

P_DIR=$(dirname $0)


## HELPERS
## ==========

declare -A colors
colors[red]=$(tput setaf 1)
colors[green]=$(tput setaf 2)
colors[reset]=$(tput sgr0)

# Print a string in the specified color
color () {
  local c=$1
  shift
  printf '%s' "${colors[$c]}"
  printf '%s\n' "$@"
  printf '%s' "${colors[reset]}"
}

# Print an error
err () {
  color red "error: $1" >&2
}

# Output an error and exit with nonzero status
failwith () {
  err "$@"
  usage
  exit 1
}

# Output an "in development" message
indev () {
  color green "$1 is still in development!"
  usage
  exit 0
}


## usage
## ==========
## Prints the top-level usage instructions

usage () {
  if [ "$1" = "--long" ]; then
    echo "Long usage coming soon!"
    usage
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
commands_archive_usage () {
  true
}

# usage output for p copy/cp
commands_copy_usage () {
  echo "usage: $exe copy <nameToCopy> [<newName>] [<args>]"
  echo "  Create a new project using an existing project's configuration."
  echo ""
  echo "Arguments:"
  echo "  <newname>            The name for the new project"
}

# usage output for p dump/d
commands_dump_usage () {
  true
}

# usage output for p go/g
commands_go_usage () {
  true
}

# usage output for p list/ls
commands_list_usage () {
  true
}

# usage output for p start/s
commands_start_usage () {
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
commands_todo_usage () {
  true
}


## EXECUTION
## =========
## Actually run the program

# Parse ~/.prc
parse_config () {
  true
}
parse_config

# Read project configurations
read_projects () {
  true
}
read_projects

# Print short usage if no arguments were provided
if [ $# -lt 1 ]; then
  # TODO: if CWD is a project directory, print info
  usage
  exit 0
fi

# Actually parse the command...
case $1 in

  # Help command. Show detailed instructions for specific commands,
  #   or long usage if no command is specified
  "help" | "h" )
    [ $# -lt 2 ] && usage --long && exit 0

    case $2 in
      "archive" | "ar" )
        commands_archive_usage
        ;;
      "copy" | "cp" )
        commands_copy_usage
        ;;
      "dump" | "d" )
        commands_dump_usage
        ;;
      "go" | "g" )
        commands_go_usage
        ;;
      "list" | "ls" )
        commands_list_usage
        ;;
      "start" | "s" )
        commands_start_usage
        ;;
      "todo" | "t" )
        commands_todo_usage
        ;;
      *)
        failwith "unknown command: $2"
    esac
    ;;

  "archive" | "ar" )
    indev $1
    ;;

  "copy" | "cp" )
    indev $1
    ;;

  "dump" | "d" )
    indev $1
    ;;

  "go" | "g" )
    indev $1
    ;;

  "list" | "ls" )
    indev $1
    ;;

  # Start command. Start a new project.
  "start" | "s" )
    [ $# -lt 2 ] && err "missing required project name" && start_usage && exit 1
    ;;

  "todo" | "t" )
    indev $1
    ;;

  *)
    # TODO: if $1 is a project name, switch to its directory
    failwith "unknown command: $1"
    ;;
esac

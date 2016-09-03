#!/bin/bash

answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}

ask() {
  print_question "$1"
  read
}

ask_for_confirmation() {
  print_question "$1 (y/n) "
  read -n 1
  printf "\n"
}

ask_for_sudo() {

  # Ask for the administrator password upfront
  sudo -v

  # Update existing `sudo` time stamp until this script has finished
  # https://gist.github.com/cowboy/3118588
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done &> /dev/null &

}

cmd_exists() {
  [ -x "$(command -v "$1")" ] \
    && printf 0 \
    || printf 1
}

execute() {
  $1 &> /dev/null
  print_result $? "${2:-$1}"
}

get_answer() {
  printf "$REPLY"
}

get_os() {

  declare -r OS_NAME="$(uname -s)"
  local os=""

  if [ "$OS_NAME" == "Darwin" ]; then
    os="osx"
  elif [ "$OS_NAME" == "Linux" ] && [ -e "/etc/lsb-release" ]; then
    os="ubuntu"
  fi

  printf "%s" "$os"

}

is_git_repository() {
  [ "$(git rev-parse &>/dev/null; printf $?)" -eq 0 ] \
    && return 0 \
    || return 1
}

mkd() {
  if [ -n "$1" ]; then
    if [ -e "$1" ]; then
      if [ ! -d "$1" ]; then
        print_error "$1 - a file with the same name already exists!"
      else
        print_success "$1"
      fi
    else
      execute "mkdir -p $1" "$1"
    fi
  fi
}

print_error() {
  # Print output in red
  printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
  # Print output in purple
  printf "\n\e[0;35m $1\e[0m\n\n"
}

print_question() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
  [ $1 -eq 0 ] \
    && print_success "$2" \
    || print_error "$2"

  [ "$3" == "true" ] && [ $1 -ne 0 ] \
    && exit
}

print_success() {
  # Print output in green
  printf "\e[0;32m  [✔] $1\e[0m\n"
}

source "install/configs.sh"

# Get current dir (so run this script from anywhere)
FILE_WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export FILE_WORKING_DIR

# Create dotfiles_old in homedir
print_info "Creating $dir_backup for backup of any existing dotfiles in ~..."
mkd $dir_backup
print_info "done"


print_info "Moving any existing dotfiles from ~ to $dir_backup"
for i in ${FILES_TO_SYMLINK[@]}; do
  mv ~/.${i##*/} ~/dotfiles_old/
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

  local i=''
  local sourceFile=''
  local targetFile=''

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  for i in ${FILES_TO_SYMLINK[@]}; do

    sourceFile="$FILE_WORKING_DIR/$i"
    targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"

    execute "chmod -w $sourceFile"
    if [ ! -e "$targetFile" ]; then 
      execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    elif [ "$(readlink "$targetFile")" == "$sourceFile" ]; then
      print_success "$targetFile → $sourceFile"
    else
      ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
      if answer_is_yes; then
        rm -rf "$targetFile"
        execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
      else
        print_error "$targetFile → $sourceFile"
      fi
    fi

  done

  #Symlink and Grant Execute Perms on Scripts
  #mkd "$HOME/.bin"
  #chmod +x $dir/scripts/batcharge.py
  #ln -fs $dir/scripts/batcharge.py $HOME/.bin/batcharge.py

  # Symlink online-check.sh
  #chmod +x $dir/scripts/online-check.sh
  #ln -fs $dir/scripts/online-check.sh $HOME/.bin/online-check.sh

  # Write out current crontab
  #crontab -l > /tmp/mycron
  # Echo new cron into cron file
  
  #echo "* * * * * $HOME/.bin/online-check.sh" >> /tmp/mycron
  # Install new cron file
  #crontab /tmp/mycron
  #rm /tmp/mycron

}

main


# Install the Solarized Dark theme for iTerm
#open "${HOME}/dotfiles/iterm/themes/Solarized Dark.itermcolors"

# Don’t display the annoying prompt when quitting iTerm
#defaults write com.googlecode.iterm2 PromptOnQuit -bool false


###############################################################################
# Git                                                                         #
###############################################################################

# github.com/jamiew/git-friendly
# the `push` command which copies the github compare URL to my clipboard is heaven
#bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)


###############################################################################
# OSX defaults                                                                #
# https://github.com/hjuutilainen/dotfiles/blob/master/bin/osx-user-defaults.sh
###############################################################################

sh osx/set-defaults.sh

###############################################################################
# Install Packages                                          #
###############################################################################

chmod +x install/mac.sh
sh install/mac.sh

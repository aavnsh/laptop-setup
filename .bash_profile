#   -------------------------------
#   1.  ENVIRONMENT CONFIGURATION

#Set default blocksize for ls, df, du
#   from this: http://hints.macworld.com/comment.php?mode=view&cid=24491
#   ------------------------------------------------------------
export BLOCKSIZE=1k
#   Add color to terminal
#   (this is all commented out as I use Mac Terminal Profiles)
#   from http://osxdaily.com/2012/02/21/add-color-to-the-terminal-in-mac-os-x/
#   ------------------------------------------------------------
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export WORKON_HOME=$HOME/projects_venv
#Pip will only work if inside a virtualenv
export PIP_REQUIRE_VIRTUALENV=true
#Pip will use the current virtual env, -E <env> will be ignored
export PIP_RESPECT_VIRTUALENV=true


# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file

source /usr/local/bin/virtualenvwrapper.sh

if [ -f "$HOME/bash_profile_local" ]; then
	source $HOME/bash_profile_local
fi

### Startup messages
clear
e_header "Welcome"
e_note `scutil --get ComputerName`"/" 
e_success "Login"

e_underline "["`sw_vers -productName`"@"`sw_vers -productVersion`"]"
df -hl | grep 'disk1' | awk '{print $4"/"$2" free ("$5" used)"}'
#w

prompt

#set -o xtrace	# Print Command before executing


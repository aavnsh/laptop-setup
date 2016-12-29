#!/bin/sh

# Inspired by the thoughtbot laptop script!
# https://github.com/thoughtbot/laptop/blob/master/mac
# no haters here - A lot of this is personal choice 
# to turn my mac into an awesome development machine.

##########################################################################
# Config
##########################################################################


#https://github.com/pathikrit/mac-setup-script/blob/master/setup.sh

pips=(
      glances #Glances is a cross-platform curses-based system monitoring tool written in Python. https://pypi.python.org/pypi/Glances
      Pygments #Pygments is a syntax highlighting package written in Python https://pypi.python.org/pypi/Pygments
      )
gems=(
      bundle
      )
npms=(
      #mermaid MArkdown Syntax for generating diagrams https://www.npmjs.com/package/mermaid
      )
clibs=(
       bpkg/bpkg
       )
bkpgs=(
       )
apms=(
      )

fails=()



##########################################################################
# Functions
##########################################################################

set -e
set +x

fancy_echo() {
  local fmt="$1"; shift

  printf "\n$fmt\n" "$@"
}

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    fancy_echo "Executing: $exec"
    if $exec ; then
      fancy_echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

append_to_profile() {
  local text="$1" profile
  local skip_new_line="${2:-0}"

  BASH_LOCAL="$HOME/.bash_profile_local"
  if [ -w "$BASH_LOCAL" ]; then
    profile="$BASH_LOCAL"
  else
    profile="$BASH_LOCAL"
  fi

  if ! grep -Fqs "$text" "$profile"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$profile"
    else
      printf "\n%s\n" "$text" >> "$profile"
    fi
  fi
}

find_latest_ruby() {
 rbenv install -l | grep -v - | tail -1 | sed -e 's/^ *//'
}

gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    gem update "$@"
  else
    gem install "$@"
    rbenv rehash
  fi
}

##########################################################################
# Main Install Script
##########################################################################

fancy_echo "Mac setup start..."

# trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT


if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

append_to_profile 'export PATH="$HOME/.bin:$PATH"'

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  mkdir "$NVM_DIR"
  append_to_profile 'export NVM_DIR="$NVM_DIR"' 1
  append_to_profile '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' 1
  append_to_profile '[[ -r $NVM_DIR/bash_completion ]] && . $NVM_DIR/bash_completion' 1
  #append_to_profile '. "$(brew --prefix nvm)/nvm.sh"' 1
fi 

if [ ! -d "/Applications/Xcode.app" ]; then
	fancy_echo 'Install xcode manually before continuing'
	exit 1
fi

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS \
      'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    append_to_profile '# recommended by brew doctor'

    #One thing we need to do is tell the system to use programs installed by Hombrew (in `/usr/local/bin`) 
    # rather than the OS default if it exists. We do this by adding `/usr/local/bin` to your `$PATH` environment variable:
    append_to_profile 'export PATH="/usr/local/bin:$PATH"' 1
fi

if brew list | grep -Fq brew-cask; then
 fancy_echo "Uninstalling old Homebrew-Cask ..."
 brew uninstall --force brew-cask
fi

fancy_echo "Updating Homebrew formulae ..."
brew update

# echo "Installing Java ..."
# brew cask install java

fancy_echo "Installing brew..."
# https://github.com/Homebrew/homebrew-bundle
cd ~/dotfiles/brew/ && brew bundle

fancy_echo "Post Brew..."
if [ -x "$(command -v fzf)" ]; then
  /usr/local/opt/fzf/install --all
  append_to_profile "[ -f ~/.fzf.bash ] && source ~/.fzf.bash" 1
fi

#if [ command -v nvm ]
#then
#  echo "Installing a stable version of Node..."
  # Install the stable version of node.
#  nvm install 4
  # Switch to the installed version
#:  nvm use 4
  # Use the stable version of node by default.
#  nvm alias default 4
fi

fancy_echo "Installing secondary packages ..."
PIP_REQUIRE_VIRTUALENV=''
install 'pip install --upgrade' ${pips[@]}
PIP_REQUIRE_VIRTUALENV=true
#install 'gem install' ${gems[@]}
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}


mas list | cut -d' ' -f1 | sort -n > /tmp/mas_exist_apps
mas_to_install=(
)
if [ ${#mas_to_install[@]} -gt 0 ]; then 
  exist_apps_count=`wc -w /tmp/mas_exist_apps`
  if [ $exist_apps_count -gt 0 ]; then
    printf "%s\n" "${mas_to_install[@]}" | sort -n > /tmp/mas_to_install
    mas_apps=`comm -13 /tmp/mas_exist_apps /tmp/mas_to_install`
    install 'mas install' ${mas_apps[@]} 
  else
    install 'mas install' ${mas_to_install[@]}
  fi
else 
  fancy_echo 'No MAS apps to install' 
fi

# fancy_echo "Upgrading bash ..."
# sudo bash -c "echo $(brew --prefix)/bin/bash #>> /private/etc/shells"
#cd; 
#curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
#source ~/.bash_profile

GO_DIR="$HOME/go_work"
fancy_echo "Setting up go ..."
if [ -d "$GO_DIR" ]; then
  mkd "$GO_DIR"
  append_to_profile 'export GOPATH="$GO_DIR"' 1
  append_to_profile 'export PATH=$PATH:$GOPATH/bin' 1
fi

fancy_echo "Configuring Ruby ..."
ruby_version="$(find_latest_ruby)"
# shellcheck disable=SC2016
append_to_profile 'eval "$(rbenv init - --no-rehash)"' 1
eval "$(rbenv init -)"

if ! rbenv versions | grep -Fq "$ruby_version"; then
 RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/opt/openssl rbenv install -s "$ruby_version"
fi

rbenv global "$ruby_version"
rbenv shell "$ruby_version"
gem update --system
gem_install_or_update 'bundler'
number_of_cores=$(sysctl -n hw.ncpu)
bundle config --global jobs $((number_of_cores - 1))



fancy_echo "Upgrading ..."
#Instead of depending on system python do a brew install python and 
#curl https://bootstrap.pypa.io/get-pip.py > get-pip.py
# python get-pip.py --user
PIP_REQUIRE_VIRTUALENV=''
pip install --upgrade pip setuptools
PIP_REQUIRE_VIRTUALENV=true
brew upgrade --all
mas outdated
mas upgrade

fancy_echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

if [ -f "$HOME/.laptop.local" ]; then
  fancy_echo "Running your customizations from ~/.laptop.local ..."
  . "$HOME/.laptop.local"
fi

fancy_echo "Run 'mackup restore' after DropBox has done syncing"

fancy_echo "Mac setup end..."

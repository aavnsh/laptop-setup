#!/bin/sh

# Inspired by the thoughtbot laptop script!
# https://github.com/thoughtbot/laptop/blob/master/mac
# no haters here - A lot of this is personal choice 
# to turn my mac into an awesome development machine.

##########################################################################
# Config
##########################################################################


#https://github.com/pathikrit/mac-setup-script/blob/master/setup.sh
brews=(
       openssl
       xz
       go
       mas
       clib
       mackup
       thefuck # (https://github.com/nvbn/thefuck): Correct your previous command. Note
              #   that this needs to be added to zsh or bash. See the project README.
       coreutils
       fpp
       gpg
       hh
       tree #Tree (http://mama.indstate.edu/users/ice/tree/): A directory listing utility
#   that produces a depth indented listing of files.
       trash
       'git'
       'git-lfs'
       #git-extras (https://vimeo.com/45506445): Adds a shit ton of useful commands #   to git.
       #meld Visual Diff Tool http://meldmerge.org/
       # - autoenv (https://github.com/kennethreitz/autoenv): this utility makes it
      #   easy to apply environment variables to projects. I mostly use it for Go and
      #   Node.js projects. For Ruby projects, I just use Foreman or Forego.
      # - autojump (https://github.com/joelthelion/autojump): a faster way to navigate
      #   your filesystem.
      nvm # (https://github.com/creationix/nvm) instead
      # of installing Node directly. This gives me more explicit control over
      # which version I'm using.
      rbenv #https://github.com/rbenv/rbenv
       )

casks=(
       commander-one
       franz
       google-chrome
       github-desktop
       iterm2
       launchrocket
       skype
       slack
       )
pips=(
      glances #Glances is a cross-platform curses-based system monitoring tool written in Python. https://pypi.python.org/pypi/Glances
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

git_configs=(
  "user.name aavnsh"
  "user.email avinash+github@zenefits.com"
  "push.default simple"
)

fails=()



##########################################################################
# Functions
##########################################################################

set -e
set +x

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
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

  if [ -w "$HOME/bash_profile_local" ]; then
    profile="$HOME/bash_profile_local"
  else
    profile="$HOME/bash_profile_local"
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

# shellcheck disable=SC2016
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
  append_to_profile '. "$(brew --prefix nvm)/nvm.sh"' 1
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
brew bundle --file=- <<EOF
# # Unix
# brew "ctags"
#brew "openssl"
# brew "imagemagick"
# # Testing
# brew "qt"
# # Programming languages
# brew "libyaml" # should come after openssl
# brew "node"
# # Databases
# brew "postgres", restart_service: true
# brew "redis", restart_service: true
#cask 'java' unless system '/usr/libexec/java_home --failfast'
#cask 'firefox', args: { appdir: '~/my-apps/Applications' }
EOF

# echo "Installing Java ..."
# brew cask install java

fancy_echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

fancy_echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions
brew tap homebrew/services
brew tap caskroom/cask

fancy_echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install --appdir=/Applications' ${casks[@]}

if test ! $(which nvm)
then
  echo "Installing a stable version of Node..."
  # Install the stable version of node.
  nvm install 4
  # Switch to the installed version
  nvm use 4
  # Use the stable version of node by default.
  nvm alias default 4
fi

fancy_echo "Installing secondary packages ..."
install 'pip install --upgrade' ${pips[@]}
#install 'gem install' ${gems[@]}
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}


mas list | cut -d' ' -f1 | sort -n > /tmp/mas_exist_apps
mas_to_install=(1018899653 #HeliumLift
425955336 #Skitch
823766827 #OneDrive
497799835 #Xcode
803453959 #Slack
449589707 #Dash
411246225 #Caffeine
)
printf "%s\n" "${mas_to_install[@]}" | sort -n > /tmp/mas_to_install
mas_apps=`comm -13 /tmp/mas_exist_apps /tmp/mas_to_install`
install 'mas install' ${mas_apps[@]} 
#for i in ${mas_apps[@]}; do
#  mas install $i
#done

#fancy_echo "Upgrading bash ..."
#sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
#cd; 
#curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
#source ~/.bash_profile

fancy_echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

fancy_echo "Setting up go ..."
#if [ ! -d "/usr/libs/go" ]; then
#  sudo mkdir -p /usr/libs/go
  append_to_profile 'export GOPATH=/usr/libs/go' 1
  append_to_profile 'export PATH=$PATH:$GOPATH/bin' 1
#fi

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
pip install --upgrade pip setuptools
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
  # shellcheck disable=SC1090
  . "$HOME/.laptop.local"
fi

fancy_echo "Run 'mackup restore' after DropBox has done syncing"

#read -p "Hit enter to run [OSX for Hackers] script..." c
#sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"


fancy_echo "Mac setup end..."

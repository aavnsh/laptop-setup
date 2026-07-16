# To help migrate from brew to mise
# #!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

LOGFILE="$(date '+%Y%m%d-%H%M%S')-migrate-from-homebrew.log"

echo "Homebrew Formulae and Casks:"
ALL_BREW_FORMULAE=$(brew leaves)
ALL_BREW_CASKS=$(brew list --cask)
ALL_BREW_PACKAGES="$ALL_BREW_FORMULAE $ALL_BREW_CASKS"
MIGRATABLE_PACKAGES=()
PACKAGE_TYPE=""

# For each package, check if there is an equivalent using mise
if command -v mise &> /dev/null; then
  for package in $ALL_BREW_PACKAGES; do
    LOG_DATE=$(date '+%Y/%m/%d %H:%M:%S')
    if echo "$ALL_BREW_FORMULAE" | grep -wq "$package"; then
      PACKAGE_TYPE="FORMULA"
    elif echo "$ALL_BREW_CASKS" | grep -wq "$package"; then
      PACKAGE_TYPE="CASK"
    else
      PACKAGE_TYPE="UNKNOWN"
    fi
    if mise ls-remote "$package" &> /dev/null; then
      echo -e "ok to migrate: ${GREEN}$package${NC}"
      echo "$LOG_DATE - MIGRATING - $PACKAGE_TYPE - $package found in brew, migratable to mise" >> "$LOGFILE"
      MIGRATABLE_PACKAGES+=("$package:$PACKAGE_TYPE")
    else
      echo -e "${ORANGE}No migration possible: $package${NC}"
      echo "$LOG_DATE - MIGRATING - $PACKAGE_TYPE - $package found in brew, not migratable to mise" >> "$LOGFILE"
    fi
  done

  for entry in "${MIGRATABLE_PACKAGES[@]}"; do
    package="${entry%%:*}"
    PACKAGE_TYPE="${entry##*:}"
    echo -ne "Would you like to migrate the following: ${GREEN}${package}${NC}? (y/N/u/c to cancel) "
    read yn
    yn=${yn:-n}
    case $yn in
      [Yy]*)
        LOG_DATE=$(date '+%Y/%m/%d %H:%M:%S')
        echo -e "installing through mise: ${GREEN}$package${NC}"
        MISE_OUTPUT=$(mise use -g "$package" 2>&1)
        if [ $? -eq 0 ]; then
          echo "$LOG_DATE - SUCCESS - $PACKAGE_TYPE - $package installed with mise" >> "$LOGFILE"
        else
          echo "$LOG_DATE - FAILED - $PACKAGE_TYPE - $package mise install failed: $MISE_OUTPUT" >> "$LOGFILE"
          echo -e "${RED}Error: mise failed to install $package. Skipping migration for this package.${NC}"
          continue
        fi
        LOG_DATE=$(date '+%Y/%m/%d %H:%M:%S')
        echo -e "removing from brew: ${GREEN}$package${NC}"
        BREW_OUTPUT=$(brew uninstall "$package" 2>&1)
        if [ $? -eq 0 ]; then
          echo "$LOG_DATE - SUCCESS - $PACKAGE_TYPE - $package uninstalled from brew" >> "$LOGFILE"
        else
          echo "$LOG_DATE - FAILED - $PACKAGE_TYPE - $package brew uninstall failed: $BREW_OUTPUT" >> "$LOGFILE"
          echo -e "${RED}Error: brew failed to uninstall $package. You may have both installed.${NC}"
          continue
        fi
        echo "Migration complete for $package"
        ;;
      [Nn]*)
        LOG_DATE=$(date '+%Y/%m/%d %H:%M:%S')
        echo -e "Skipping ${CYAN}$package${NC} migration."
        echo "$LOG_DATE - MIGRATING - $PACKAGE_TYPE - $package skipped by user" >> "$LOGFILE"
        ;;
      [Uu]*)
        LOG_DATE=$(date '+%Y/%m/%d %H:%M:%S')
        echo -e "uninstalling from brew only: ${GREEN}$package${NC}"
        BREW_OUTPUT=$(brew uninstall "$package" 2>&1)
        if [ $? -eq 0 ]; then
          echo "$LOG_DATE - SUCCESS - $PACKAGE_TYPE - $package uninstalled from brew only" >> "$LOGFILE"
        else
          echo "$LOG_DATE - FAILED - $PACKAGE_TYPE - $package brew only uninstall failed: $BREW_OUTPUT" >> "$LOGFILE"
          echo -e "${RED}Error: brew failed to uninstall $package. You may have both installed.${NC}"
        fi
        ;;
      [Cc]*|[Cc]ancel)
        echo -e "${RED}Cancelling migration. Exiting.${NC}"
        exit 0
        ;;
      *)
        echo "Please answer y, n, u, or c (cancel)."
        ;;
    esac
  done
fi

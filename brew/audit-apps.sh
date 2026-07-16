#!/bin/bash

# Ensure Homebrew is available
if ! command -v brew &>/dev/null; then
    echo "❌ Error: Homebrew is not installed or not in your PATH."
    exit 1
fi

echo "🔍 Fetching your local /Applications list..."
local_apps=$(find /Applications ~/Applications -maxdepth 2 -name "*.app" 2>/dev/null | sed 's|.*/||' | sed 's|\.app$||')

echo "📦 Fetching the current list of available Homebrew Casks (this may take a moment)..."
available_casks=$(brew search --casks "*")

echo "📋 Fetching currently installed Homebrew packages..."
installed_recipes=$(brew list --formula -1 2>/dev/null)
installed_casks=$(brew list --cask -1 2>/dev/null)

# Create temporary lists for categorization
touch /tmp/brew_already /tmp/brew_migration /tmp/brew_unmatched

while read -r app_name; do
    [ -z "$app_name" ] && continue

    # Normalize name: lowercase, replace spaces/underscores with hyphens, remove symbols
    normalized_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed -e 's/[ _]/-/g' -e 's/[()//]//g')

    # Look for an exact match or close match in available casks
    matched_cask=$(echo "$available_casks" | grep -E "^${normalized_name}$" | head -n 1)

    if [ -n "$matched_cask" ]; then
        # Check if it's already managed by brew (as a cask or formula)
        if echo "$installed_casks" | grep -E "^${matched_cask}$" &>/dev/null || echo "$installed_recipes" | grep -E "^${matched_cask}$" &>/dev/null; then
            echo "cask \"$matched_cask\"  # Already managed by Brew (Matches $app_name)" >> /tmp/brew_already
        else
            echo "cask \"$matched_cask\"  # MIGRATION TARGET: Currently manual (Matches $app_name)" >> /tmp/brew_migration
        fi
    else
        # Filter out core native Apple system apps from clogging unmatched list
        case "$normalized_name" in
            safari|imovie|garageband|pages|numbers|keynote|preview|mail|finder|textedit|calculator|system-settings|clock|contacts|maps|notes|photos|reminders|stocks|weather)
                ;;
            *)
                echo "- $app_name" >> /tmp/brew_unmatched
                ;;
        esac
    fi
done <<< "$local_apps"

# --- OUTPUT RESULTS ---

echo -e "\n======================================================================"
echo "✅ ALREADY MANAGED BY BREW (Safe to keep in your Brewfile)"
echo "======================================================================"
cat /tmp/brew_already

echo -e "\n======================================================================"
echo "🚀 MIGRATION TARGETS (Available in Brew, but you installed them manually)"
echo "👉 Action: Run 'brew install --cask <name> --force' to let Brew take over."
echo "======================================================================"
cat /tmp/brew_migration

echo -e "\n======================================================================"
echo "⚠️  UNMATCHED APPS (App Store, system tools, or unique binaries)"
echo "======================================================================"
cat /tmp/brew_unmatched

# Cleanup temporary files
rm /tmp/brew_already /tmp/brew_migration /tmp/brew_unmatched

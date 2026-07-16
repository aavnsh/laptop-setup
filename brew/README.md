# Backup
`brew bundle dump`
`brew bundle dump --force`
This will generate a new `Brewfile` in current directory.
--force if the file already exists

# Install from list
`brew bundle install`

# Check if dependencies are present
`brew bundle check`

# Remove specific packages
# brew uninstall tmux
# brew uninstall --cask <cask_name>

# Cleanup 
`brew bundle cleanup`

Run it first to see if it only have the few packages you want to be gone. else better to remove specific packages
or you may need to update the Brewfile because you have installed packages but forgotten to add it to brewfile

TODO: Write a script that will periodically compare installed vs configured and alert if difference

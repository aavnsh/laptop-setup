declare -a FILES_TO_SYMLINK=(

  'shell/shell_aliases'
  #'shell/shell_config'
  #'shell/shell_exports'
  'shell/shell_functions'
  'shell/path'
  'shell/bash_profile'
  'shell/bash_prompt'
  #'shell/bashrc'
  #'shell/zshrc'
  #'shell/ackrc'
  #'shell/curlrc'
  #'shell/gemrc'
  #'shell/inputrc'
  #'shell/screenrc'
  'fzf/fzf-functions'

  #'git/gitattributes'
  'git/gitconfig'
  'git/gitignore_global'
  'git/git-completion.bash'
  'git/git-prompt.sh'
  'git/git-aliases'

)

dir=~/dotfiles                        # dotfiles directory
dir_backup=~/dotfiles_old             # old dotfiles backup directory

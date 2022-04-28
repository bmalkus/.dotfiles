[ -z $PROMPT_COLOR ] && export PROMPT_COLOR=1

. "$DOTFILES_DIR/.shellrc.bash.zsh"

prompt_command()
{
  if [[ $PROMPT_COLOR == 0 ]]; then
    if [[ -n $SSH_CLIENT ]]; then
      PS1="\u@\h | \W $ "
    else
      PS1="\u | \W $ "
    fi
  else
    PS1="\[\e[0;1;34m\]\u"
    if [[ -n $SSH_CLIENT ]]; then
      PS1="${PS1}\[\e[0;36m\]@\h"
    fi
    PS1="$PS1 \[\e[0;1;39m\]| \W $ \[\e[0m\]"
  fi
}

[[ ! $PROMPT_COMMAND =~ "__dir_history" ]] && PROMPT_COMMAND="$PROMPT_COMMAND prompt_command; __dir_history;"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

alias sr=". $HOME/.bashrc"

[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

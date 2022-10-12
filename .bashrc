export DOTFILES_DIR="$HOME/.dotfiles"

. "$DOTFILES_DIR/.shellrc.bash.zsh"
. "$DOTFILES_DIR/z.sh"

if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi

set -o physical

bind '"\ex": alias-expand-line'

_NORMAL="\[\e[0m\]"
_BOLD="\[\e[0;1;39m\]"

_ENV_INFO_COLOR="\[\e[0;34m\]"
_CONTEXT_COLOR="\[\e[0;38;2;215;175;135m\]"
_RC_ERROR_COLOR="\[\e[0;38;2;215;0;0m\]"
_TIMER_COLOR="\[\e[0;38;2;95;135;135m\]"
_PWD_ANCHOR_COLOR="\[\e[0;1;38;2;0;175;255m\]"
_PWD_REGULAR_COLOR="\[\e[0;38;2;0;135;175m\]"
_PWD_TRUNC_COLOR="\[\e[0;38;2;135;135;175m\]"

_PWD_MARKERS=( .git .shorten_folder_marker )

_RED="\[\e[0;31m\]"
_LIGHT_RED="\[\e[0;1;31m\]"

_GREEN="\[\e[0;32m\]"
_LIGHT_GREEN="\[\e[0;1;32m\]"

_YELLOW="\[\e[0;33m\]"
_LIGHT_YELLOW="\[\e[0;1;33m\]"

_BLUE="\[\e[0;34m\]"
_LIGHT_BLUE="\[\e[0;1;34m\]"

_MAGENTA="\[\e[0;35m\]"
_LIGHT_MAGENTA="\[\e[0;1;35m\]"

_CYAN="\[\e[0;36m\]"
_LIGHT_CYAN="\[\e[0;1;36m\]"

__virtual_env_info()
{
  local ret=""
  [[ -n $VIRTUAL_ENV ]] && ret="$(basename $VIRTUAL_ENV)"
  [[ -n $ret ]] && echo "${ret}${1}"
}

__git_info()
{
  [[ $PROMPT_GIT_INFO == 0 ]] && return
  [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) != true ]] && return

  if [[ $(git rev-parse --is-bare-repository 2>/dev/null) == true ]]; then
    echo "$_YELLOW/bare repo/${1}"
    return
  fi

  local branch="$(git branch 2> /dev/null | grep '* ' | cut -c3-)"

  local ahead_behind="$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)"
  local behind="$(cut -f 2 <<< "$ahead_behind")"
  local ahead="$(cut -f 1 <<< "$ahead_behind")"

  local stashes="$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null || echo 0)"

  local git_status="$(git status --porcelain --ignore-submodules -unormal 2>/dev/null)"
  local untracked="$(<<<"$git_status" grep -c '^?? ')"
  local unstaged="$(<<<"$git_status" grep -c '^[ MADRC][MADRC] ')"
  local staged="$(<<<"$git_status" grep -c '^[MADRC][ MADRC] ')"

  local ret="$_YELLOW${branch}"
  [[ $behind -gt 0 ]] && ret+=" $_BLUE⇣$behind"
  [[ $ahead -gt 0 ]] && ret+=" $_BLUE⇡$ahead"
  [[ $stashes -gt 0 ]] && ret+=" $_YELLOW*$stashes"
  [[ $unstaged -gt 0 ]] && ret+=" $_YELLOW!$unstaged"
  [[ $staged -gt 0 ]] && ret+=" $_YELLOW+$staged"
  [[ $untracked -gt 0 ]] && ret+=" $_BLUE?$untracked"

  [[ -n $ret ]] && echo "${ret}${1}"
}

__prompt_pwd()
{
  local tilde="~" # on different bash versions, replacing with ~ and "~" works differently, this unifies it
  IFS='/' read -ra split_pwd <<< "${PWD/$HOME/$tilde}"
  declare -a split_pwd_for_output

  if [[ "${#split_pwd[@]}" -gt 1 ]] || [[ "$PWD" == "/" ]]; then
    # Anchor first and last directories (which may be the same)
    if [[ -n "${split_pwd[0]}" ]]; then # ~/foo/bar, hightlight ~
      split_pwd_for_output=( "$_PWD_ANCHOR_COLOR${split_pwd[0]}$_PWD_REGULAR_COLOR" "${split_pwd[@]:1}" )
    else # /foo/bar, hightlight foo not empty string
      split_pwd_for_output=( "$_PWD_REGULAR_COLOR" "$_PWD_ANCHOR_COLOR${split_pwd[1]}$_PWD_REGULAR_COLOR" "${split_pwd[@]:2}" )
    fi
    local last_index=$((${#split_pwd_for_output[@]} - 1))
    split_pwd_for_output[last_index]=$_PWD_ANCHOR_COLOR${split_pwd[last_index]}$_PWD_REGULAR_COLOR

    for i in $(seq 1 $((${#split_pwd[@]} - 2))); do
      local parent_dir="$(__join_by / ${split_pwd[@]:0:i})" # Uses i before increment
      parent_dir="${parent_dir/$tilde/$HOME}"
      local curr_dir="${split_pwd[i]}"

      local test_cmd=( test -z false )
      for marker in ${_PWD_MARKERS[@]}; do
        test_cmd+=( -o -e "$parent_dir/$curr_dir/$marker" )
      done
      # Returns true if any markers exist in dir_section
      if "${test_cmd[@]}"; then
        split_pwd_for_output[i]="$_PWD_ANCHOR_COLOR$curr_dir$_PWD_REGULAR_COLOR"
      else
        split_pwd_for_output[i]="$_PWD_TRUNC_COLOR${curr_dir:0:1}$_PWD_REGULAR_COLOR"
      fi
      ((++i))
    done
    echo "$(__join_by "/" "${split_pwd_for_output[@]}")"
  fi
}

__join_by() {
  local d=${1-} f=${2-}
  if shift 2; then
    printf "%s" "$f" "${@/#/$d}"
  fi
}

__get_prompt()
{
  local virtual_env="${_ENV_INFO_COLOR}$(__virtual_env_info " ")"
  local git_branch="$(__git_info " ")"

  if [[ -n $SSH_CLIENT ]]; then
    local user="$_CONTEXT_COLOR$1@$2 "
  fi
  local cwd="$(__prompt_pwd)"
  if [[ -n $cwd ]]; then
    cwd="$cwd "
  fi

  local whitespace=" "
  if [[ $PROMPT_MULTILINE != 0 ]]; then
    whitespace=$'\n'
  fi

  if [[ $4 -eq 0 ]]; then
    local last_exit_code=""
    local prompt_char="${_YELLOW}❯ ${_NORMAL}"
  else
    local last_exit_code="${_RC_ERROR_COLOR}✘ $4 "
    local prompt_char="${_RC_ERROR_COLOR}❯ ${_NORMAL}"
  fi

  local prefix=""
  if [[ -n $PROMPT_PREFIX ]]; then
    prefix="$_YELLOW${PROMPT_PREFIX} "
  fi

  echo "${prefix}${virtual_env}${user}${cwd}${git_branch}${last_exit_code}${prompt_char}"
}

prompt_command()
{
  local last_status="$?"
  if [ "${BASH_VERSINFO:-0}" -ge 4 ] && command -v readarray &>/dev/null; then
    PS1="$(__get_prompt "\u" "\H" "\W" "$last_status")"
  else
    if [[ $PROMPT_COLOR == 0 ]]; then
      if [[ -n $SSH_CLIENT ]]; then
        PS1="\u@\H | \W $ "
      else
        PS1="\u | \W $ "
      fi
    else
      PS1="\[\e[0;1;34m\]\u"
      if [[ -n $SSH_CLIENT ]]; then
        PS1="${PS1}\[\e[0;36m\]@\H"
      fi
      PS1="$PS1 \[\e[0;1;39m\]| \W $ \[\e[0m\]"
    fi
  fi
}

_completemarks() {
  local curw=${COMP_WORDS[COMP_CWORD]}
  local wordlist=$(find $MARKPATH -type l -printf "%f\n")
  COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
  return 0
}

complete -F _completemarks jump unmark j

if [[ ! $PROMPT_COMMAND =~ "__dir_history" ]]; then
  [[ -n $PROMPT_COMMAND && ! $PROMPT_COMMAND =~ \;$ ]] && PROMPT_COMMAND="$PROMPT_COMMAND;"
  PROMPT_COMMAND="$PROMPT_COMMAND prompt_command; __dir_history"
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

alias sr=". $HOME/.bashrc"

[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

### git aliases

alias g='git'

alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gapp='git apply'
alias gau='git add --update'

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbd!='git branch -D'
alias gbda='git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev)\s*$)" | command xargs -n 1 git branch -d'
alias gbl='git blame -b -w'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcn!='git commit -v --no-edit --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gcan!='git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gcam='git commit -a -m'
alias gcsm='git commit -s -m'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gcl='git clone --recursive'
alias gcls='git clone --recursive --depth 1 --shallow-submodules'
alias gclean='git clean -fd'
alias gpristine='git reset --hard && git clean -dfx'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcount='git shortlog -sn'
#compdef _git gcount complete -F _git gcount
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcps='git cherry-pick -s'
alias gcs='git commit -S'

alias gd='git diff'
alias gdca='git diff --cached'
alias gdcap='git diff --cached HEAD^'
alias gdct='git describe --tags `git rev-list --tags --max-count=1`'
alias gdp='git diff HEAD^'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'

gdv() {
  git diff -w "$@" | view -
}
#compdef _git gdv=git-diff

alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

gfg() {
  git ls-files | grep "$@"
}
#compdef _grep gfg

alias gg='git gui citool'
alias gga='git gui citool --amend'

ggf() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git push --force origin "${b:=$1}"
}
#compdef _git ggf=git-checkout

ggl() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git pull origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git pull origin "${b:=$1}"
  fi
}
#compdef _git ggl=git-checkout

ggp() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git push origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git push origin "${b:=$1}"
  fi
}
#compdef _git ggp=git-checkout

ggpnp() {
  if [[ "$#" == 0 ]]; then
    ggl && ggp
  else
    ggl "${*}" && ggp "${*}"
  fi
}
#compdef _git ggpnp=git-checkout

ggu() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git pull --rebase origin "${b:=$1}"
}
#compdef _git ggu=git-checkout

alias ggpur='ggu'
#compdef _git ggpur=git-checkout

alias ggpull='git pull origin $(git_current_branch)'
#compdef _git ggpull=git-checkout

alias ggpush='git push origin $(git_current_branch)'
#compdef _git ggpush=git-checkout

alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpsup!='git push --force-with-lease --set-upstream origin $(git_current_branch)'

alias ghh='git help'

alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
#compdef _git git-svn-dcommit-push=git

alias gk='\gitk --all --branches'
#compdef _git gk='gitk'
alias gke='\gitk --all $(git log -g --pretty=%h)'
#compdef _git gke='gitk'

alias gl='git pull'
alias glg='git log --stat'
alias glgp='git log --stat -p'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glola="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp="_git_log_prettily"
#compdef _git glp=git-log

alias gm='git merge'
alias gmom='git merge origin/master'
alias gmt='git mergetool --no-prompt'
alias gmtvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/master'

alias gp='git push'
alias gp!='git push --force-with-lease'
alias gpd='git push --dry-run'
alias gpoat='git push origin --all && git push origin --tags'
#compdef _git gpoat=git-push
alias gpu='git push upstream'
alias gpv='git push -v'

alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbm='git rebase master'
alias grbs='git rebase --skip'
alias grf='git reflog'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grs='git restore'
alias grset='git remote set-url'
alias grss='git restore --source'
alias grst='git restore --staged'
alias grt='cd $(git rev-parse --show-toplevel || echo ".")'
alias gru='git reset --'
alias grup='git remote update'
alias grv='git remote -v'

alias gsb='git status -sb'
alias gsd='git svn dcommit'
alias gsi='git submodule init'
alias gsps='git show --pretty=short --show-signature'
alias gsr='git svn rebase'
alias gss='git status -s'
alias gst='git status'
alias gsta='git stash save'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gsu='git submodule update'

alias gts='git tag -s'
alias gtv='git tag | sort -V'

alias guc='git reset --soft HEAD^'
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gup='git pull --rebase'
alias gupv='git pull --rebase -v'
alias gupa='git pull --rebase --autostash'
alias gupav='git pull --rebase --autostash -v'
alias glum='git pull upstream master'

alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify -m "--wip-- [skip ci]"'

set -xU DOTFILES_DIR "$HOME/.dotfiles"

if status --is-interactive && [ -z "$_DOTFILES_ONCE_" ]
  set -U _DOTFILES_ONCE_ 1

  if not functions -q fisher
    curl -sL git.io/fisher | source
    fisher update

    echo 1 1 1 1 1 1 y | tide configure > /dev/null
  end

  exec fish
end

if [ -z "$_DOTFILES_ONCE_ON_START_" ]
  set _DOTFILES_ONCE_ON_START_ 1

  if status --is-interactive
    . $DOTFILES_DIR/gcloud_sdk_argcomplete.fish
    complete -f -c gcloud -a '(gcloud_sdk_argcomplete)'
    complete -x -c gsutil -a '(gcloud_sdk_argcomplete)'
  end

  # iterm integration is not enabled properly in tmux for some reason, so this is a workaround
  function enable_iterm_integration --on-event fish_prompt
    . "$DOTFILES_DIR/iterm2_shell_integration.fish"
    functions --erase enable_iterm_integration
  end

  [ -r "$HOME/.config/fish/once.local.fish" ] && . "$HOME/.config/fish/once.local.fish"
end

. "$DOTFILES_DIR/.shellrc.config"

function bgFunc
  fish -c (string join -- ' ' (string escape -- $argv)) &
end
complete -c bgFunc -a "(functions)"

#######################################################################
#                               prompt                                #
#######################################################################

set tide_left_prompt_items scl virtual_env context pwd git status cmd_duration character
[ $PROMPT_GIT_INFO = 0  ] && set -e tide_left_prompt_items[5]
# set tide_right_prompt_items time
set tide_right_prompt_items
set tide_virtual_env_icon
set tide_git_color_upstream $tide_pwd_color_anchors
set tide_prompt_add_newline_before false
set tide_character_icon '>'
set tide_pwd_icon_unwritable ⛔

set tide_anaconda_color FFAB76
set tide_anaconda_bg_color normal
# set tide_pwd_color_anchors 00AFFF
# set tide_pwd_color_dirs 0087AF

set CONDA_LEFT_PROMPT 1

function _tide_item_scl
  if test -n "$X_SCLS"
    set -l scl (string trim "$X_SCLS")
    _tide_print_item scl (set_color -o $tide_anaconda_color)"/$scl/"
  end
end

#######################################################################
#                          when interactive                           #
#######################################################################

if status --is-interactive

function alias_if_needed
  set gcmd "g$argv[1]"
  set path_to "(which $gcmd 2>/dev/null)"
  if type -q $gcmd
    export _$argv[1]=$gcmd
  else
    export _$argv[1]=$argv[1]
  end
end

. "$DOTFILES_DIR/.shellrc.common"

alias sr=". $HOME/.config/fish/config.fish"

bind -k nul forward-char

#######################################################################
#                                marks                                #
#######################################################################

# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
export MARKPATH=$HOME/.marks

function jump
  if [ -z $argv[1] ]
    # ls -l "$MARKPATH" | tr -s ' ' | cut -d' ' -f9- | awk NF | awk -F ' -> ' '{printf "    %-10s -> %s\n", $1, $2}'
    mkdir -p "$MARKPATH"; ls "$MARKPATH" | xargs -I'{}' sh -c 'printf "    %-10s -> %s\n" {} "$(readlink -f "$MARKPATH/{}")"'
  else
    if ! cd "$MARKPATH/$argv[1]"
      echo "No such mark: $argv[1]"
    end
  end
end

complete -e -c jump
complete -x -c jump -a '(ls -l "$MARKPATH" | tr -s " " | cut -d" " -f9,11- | awk NF | sed "s/ /"\t"/")'

function mark
  mkdir -p "$MARKPATH"; ln -s (pwd) "$MARKPATH/$argv[1]"
end

function unmark
  rm -i "$MARKPATH/$argv[1]"
end

#######################################################################
#                              cd utils                               #
#######################################################################

function save_dir --on-event fish_prompt
  if begin [ -n "$_oldpwd" ]; and [ "$_oldpwd" != (realpath "$PWD") ]; end
    set -ga _cd_history "$_oldpwd"
  end
  set -g _oldpwd (realpath "$PWD")
end

function cd_hist
  if [ (count $argv) -eq 0 ]
    list_cd_hist 15
  else if string match -qr '^-l[0-9]+$' -- $argv[1]
    list_cd_hist (string sub -s 3 $argv[1])
  else if string match -qr '^-?[0-9]+$' -- $argv[1]
    go_to_dir $_cd_history[$argv[1]]
  else if [ $argv[1] = "-" ]
    go_to_dir $_cd_history[-1]
  end
end

function go_to_dir
  [ -z $argv[1] ];
  and return 1

  if [ -d $argv[1] ]
    cd "$argv[1]" && echo "$argv[1]"
  else
    echo "Not a directory: $argv[1]" >&2
  end
end

function list_cd_hist
  string match -qr '^[0-9]+$' -- "$argv[1]";
  or return 1

  set -l full_size (count $_cd_history)
  if [ $full_size -gt 0 ]
    set -l to_print $_cd_history[(math -$argv[1])..-1]
    set -l size (count $to_print)
    for ind in (seq -1 -1 -$size)
      printf "%4d %4d  %s\n" (math $full_size + $ind + 1) $ind $to_print[$ind]
    end
  end
end

function __complete_cd_hist
  if test (count $_cd_history) -eq 0
    return
  end
  for ind in (seq -1 -1 -(count $_cd_history))
    printf "%d\t%s\n" $ind $_cd_history[$ind]
  end
end

complete -e -c cd_hist
complete -x -c cd_hist -k -a '(__complete_cd_hist)'

function cd
  if begin [ -n "$argv[1]" ]; and [ -d "$argv[1]" ]; end
    builtin cd (realpath $argv[1]) $argv[2..-1]
  else if [ "$argv[1]" = "-" ]
    cd_hist -
  else
    builtin cd $argv
  end
end

#######################################################################
#                               abbrevs                               #
#######################################################################

# workaround - since fish 3.6 abbrevs must be initialized each time
set -e __git_plugin_initialized
__git.init

abbr -a gapp        git apply

abbr -a gbd         git branch -d
abbr -a gbd!        git branch -D

abbr -a gbcon        git branch --contains

function gbda --description "remove all local git branches already merged to current one"
  if [ "$argv[1]" = "-n" ]
    git branch --no-color --merged | command grep -vE '^(\+|\*|\s*(master|develop|dev)\s*$)' | command xargs -n 1 echo
  else
    git branch --no-color --merged | command grep -vE '^(\+|\*|\s*(master|develop|dev)\s*$)' | command xargs -n 1 git branch -d
  end
end

abbr -a gcl         git clone --recurse-submodules
abbr -a gcls        git clone --recurse-submodules --depth 1 --shallow-submodules
abbr -a gcmsg       git commit -m
abbr -a gcpa        git cherry-pick --abort
abbr -a gcpc        git cherry-pick --continue

abbr -a gdcap       git diff --cached HEAD^
abbr -a gdp         git diff HEAD^

abbr -a gignore     git update-index --skip-worktree

abbr -a gloga       git log --oneline --decorate --color --graph --all

abbr -a gma         git merge --abort
abbr -a gmc         git merge --continue

abbr -a gpsup       git push --set-upstream origin "(__git.current_branch)"
abbr -a gpsup!      git push --set-upstream --force-with-lease origin "(__git.current_branch)"

abbr -a grbia       git rebase --interactive --autosquash
abbr -a grf         git reflog
abbr -a grm         git reset --mixed HEAD^

abbr -a gstaa       git stash apply
abbr -a gstap       git stash --patch
abbr -a gstl        git stash list

abbr -a guc         git reset --soft HEAD^
abbr -a gunignore   git update-index --no-skip-worktree

function gwip -d "git commit a work-in-progress branch"
  git add -A; git rm (git ls-files --deleted) 2> /dev/null; git commit -n -m "--wip-- [ci skip]"
end

function last_history_item
  echo $history[1]
end

abbr -a !! --position anywhere --function last_history_item

abbr -a cd.         cd ..
abbr -a cd..        cd ..
abbr -a cd-         cd -
abbr -a ..          cd ..
abbr -a ...         cd ../..
abbr -a ....        cd ../../..

abbr -a j           jump

abbr -a c           cd_hist
abbr -a c-          cd -

[ -r "$HOME/.config/fish/config.local.fish" ] && . "$HOME/.config/fish/config.local.fish"

end

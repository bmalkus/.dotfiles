set -x DOTFILES_DIR "$HOME/.dotfiles"

if [ -z "$_ONCE_" ]
  set -g _ONCE_ 1

  if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher

    fisher add jethrokuan/z
    fisher add jhillyerd/plugin-git
  end

  [ -r "$HOME/.config/fish/once.local.fish" ] && . "$HOME/.config/fish/once.local.fish"
end

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

alias sed gsed

[ (less -V | head -n1 | cut -f2 -d' ') -ge 530 ] && export LESS={$LESS}F

alias sr=". $HOME/.config/fish/config.fish"

bind -k nul forward-char

#######################################################################
#                               prompt                                #
#######################################################################


function fish_prompt
  set rc $status
  echo -ns \
  (set_color yellow) \
  (__prefix) \
  (set_color blue) \
  (__virtual_env_info) \
  (__git_info) \
  (__user) \
  (__rc $rc) \
  (set_color --bold white) \
  (__prompt_pwd) "> " \
  (set_color normal)
end

function __sep
  set_color --bold white
  echo -n " | "
  set_color normal
end

function __rc
  if [ $argv[1] -ne 0 ]
    echo -ns (set_color --bold red) "/" $argv[1] "/ " (set_color normal)
  end
end

function __prefix
  [ -n $PROMPT_PREFIX ] && echo -n {$PROMPT_PREFIX} && __sep
end

function __virtual_env_info
  set ret ""
  if [ -n "$VIRTUAL_ENV" ]
    set ret (basename $VIRTUAL_ENV)
  end
  [ -n "$CONDA_DEFAULT_ENV" ] && set ret $CONDA_DEFAULT_ENV
  [ -n "$ret" ] && echo -ns $ret (__sep)
end

function __git_info
  [ $PROMPT_GIT_INFO = 0 ] && return
  git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null || return

  if [ (git rev-parse --is-bare-repository 2>/dev/null) = true ]
    set_color yellow
    echo -ns $argv[1] "/bare repo/" $argv[2]
    return
  end

  set_color yellow
  echo -ns (git branch 2> /dev/null | grep '* ' | cut -c3-)

  set ahead_behind (git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
  if [ "$status" = 0 ]
    set behind (echo $ahead_behind | $_sed -nre 's/^([0-9]+)\s+([0-9]+)$/\2/p')
    set ahead (echo $ahead_behind | $_sed -nre 's/^([0-9]+)\s+([0-9]+)$/\1/p')
    if begin [ "$behind" -gt 0 ]; or [ "$ahead" -gt 0 ]; end
      echo -n " "
      set_color blue
      [ $behind -gt 0 ]; and echo -ens \u21e3 $behind
      [ $ahead -gt 0 ]; and echo -ens \u21e1 $ahead
    end
  end

  set git_status (git status --porcelain --ignore-submodules -unormal 2>/dev/null | string collect)
  set untracked (echo $git_status | grep -c '^?? ')
  set unstaged (echo $git_status | grep -c '^[ MADRC][MADRC] ')
  set staged (echo $git_status | grep -c '^[MADRC][ MADRC] ')

  set_color yellow

  [ $untracked -gt 0 ]; and echo -ens " " \u2026 $untracked
  [ $unstaged -gt 0 ]; and echo -ens " " \u25cb $unstaged
  [ $staged -gt 0 ]; and echo -ens " " \u25cf $staged

  echo -n (__sep)
end

function __user
  set_color brblue
  echo -n "$USER"
  if [ -n "$SSH_CLIENT" ]
    set_color cyan
    echo -n "@"
    echo -n (prompt_hostname)
    set_color normal
  end
  __sep
end

function __prompt_pwd --description 'Print the current working directory, shortened to fit the prompt'
    set -l options 'h/help'
    argparse -n prompt_pwd --max-args=0 $options -- $argv
    or return

    if set -q _flag_help
        __fish_print_help prompt_pwd
        return 0
    end

    # This allows overriding fish_prompt_pwd_dir_length from the outside (global or universal) without leaking it
    set -q fish_prompt_pwd_dir_length
    or set -l fish_prompt_pwd_dir_length 1

    # Replace $HOME with "~"
    set realhome ~
    set -l tmp (string replace -r '^'"$realhome"'($|/)' '~$1' (realpath $PWD))

    if [ $fish_prompt_pwd_dir_length -eq 0 ]
        echo $tmp
    else
        # Shorten to at most $fish_prompt_pwd_dir_length characters per directory
        string replace -ar '(\.?[^/]{'"$fish_prompt_pwd_dir_length"'})[^/]*/' '$1/' $tmp
    end
end

#######################################################################
#                                marks                                #
#######################################################################


# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
export MARKPATH=$HOME/.marks

function jump
  if [ -z $argv[1] ]
    ls -l "$MARKPATH" | tr -s ' ' | cut -d' ' -f9- | awk NF | awk -F ' -> ' '{printf "    %-10s -> %s\n", $1, $2}'
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
    for ind in (seq -$size -1)
      printf "%4d %4d  %s\n" (math $full_size + $ind + 1) $ind $to_print[$ind]
    end
  end
end

function __complete_cd_hist
  for ind in (seq (count $_cd_history) 1)
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

abbr -a gapp        git apply

abbr -a gbd         git branch -d
abbr -a gbd!        git branch -D

function gbda --description "remove all local git branches already merged to current one"
  git branch --no-color --merged | command grep -vE '^(\+|\*|\s*(master|develop|dev)\s*$)' | command xargs -n 1 git branch -d
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

abbr -a gpsup       git push --set-upstream origin "(git_current_branch)"
abbr -a gpsup!      git push --set-upstream --force-with-lease origin "(git_current_branch)"

abbr -a grm         git reset --mixed HEAD^

abbr -a gstaa       git stash apply
abbr -a gstl        git stash list

abbr -a guc         git reset --soft HEAD^
abbr -a gunignore   git update-index --no-skip-worktree

function git_current_branch
  git rev-parse --abbrev-ref HEAD 2>/dev/null
end

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

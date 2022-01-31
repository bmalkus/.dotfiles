set -x DOTFILES_DIR "$HOME/.dotfiles"

if [ -z "$_ONCE_" ]
  set _ONCE_ 1

  if status --is-interactive && not functions -q fisher
    curl -sL git.io/fisher | source
    fisher update
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

alias sr=". $HOME/.config/fish/config.fish"

bind -k nul forward-char

#######################################################################
#                               prompt                                #
#######################################################################

set tide_left_prompt_items anaconda virtual_env context prompt_pwd git status cmd_duration character
set tide_right_prompt_items time
set tide_virtual_env_icon
set tide_git_color_upstream $tide_pwd_color_anchors
set tide_prompt_add_newline_before false

function _tide_item_anaconda
  if test -n "$CONDA_DEFAULT_ENV"
    _tide_print_item anaconda "$CONDA_DEFAULT_ENV"
  end
end

set -U tide_anaconda_color FFAB76
set -U tide_anaconda_bg_color normal

function _tide_item_prompt_pwd
  set -l split_pwd (string replace -- $HOME '~' $PWD | string split /)
  set -l _tide_color_anchors (set_color -o $tide_pwd_color_anchors)
  set -l _tide_color_truncated_dirs (set_color $tide_pwd_color_truncated_dirs)
  set -l _tide_reset_to_color_dirs (set_color normal -b $tide_pwd_bg_color; set_color $tide_pwd_color_dirs)
  if test (count $split_pwd) -gt 1
    # Anchor first and last directories (which may be the same)
    if test -n "$split_pwd[1]" # ~/foo/bar, hightlight ~
      set split_pwd_for_output $_tide_color_anchors$split_pwd[1]$_tide_reset_to_color_dirs $split_pwd[2..]
    else # /foo/bar, hightlight foo not empty string
      set split_pwd_for_output '' $_tide_color_anchors$split_pwd[2]$_tide_reset_to_color_dirs $split_pwd[3..]
    end
    set split_pwd_for_output[-1] $_tide_color_anchors$split_pwd[-1]$_tide_reset_to_color_dirs

    if not test -w $PWD
      set -g tide_pwd_icon $tide_pwd_icon_unwritable' '
    else if test $PWD = $HOME
      set -g tide_pwd_icon $tide_pwd_icon_home' '
    else
      set -g tide_pwd_icon $tide_pwd_icon' '
    end

    i=1 for dir_section in $split_pwd[2..-2]
      set -l parent_dir (string join -- / $split_pwd[..$i] | string replace '~' $HOME) # Uses i before increment

      set i (math $i + 1)

      # Returns true if any markers exist in dir_section
      if test -z false (string split --max 2 " " -- "-o -e "$parent_dir/$dir_section/$tide_pwd_markers)
        set split_pwd_for_output[$i] $_tide_color_anchors$dir_section$_tide_reset_to_color_dirs
      else
        set split_pwd_for_output[$i] $_tide_color_truncated_dirs(string sub -s 1 -l 1 $dir_section)$_tide_reset_to_color_dirs
      end
    end

    _tide_print_item prompt_pwd (string join -- / $split_pwd_for_output)
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

function gwip -d "git commit a work-in-progress branch"
  git add -A; git rm (git ls-files --deleted) 2> /dev/null; git commit -m "--wip-- [ci skip]"
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

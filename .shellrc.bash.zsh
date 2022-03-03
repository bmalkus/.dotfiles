export DOTFILES_DIR="$HOME/.dotfiles"

alias_if_needed()
{
  gcmd="g$1"
  path_to="$(which $gcmd 2>/dev/null)"
  if [[ ! -x "$path_to" ]]; then
    export _$1=$1
  else
    export _$1=$gcmd
  fi
}

. "$DOTFILES_DIR/.shellrc.common"

alias c='local_cd_hist'

alias cd.='cd ..'
alias cd..='cd ..'
alias cd-='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c-='c -'
alias j='jump'

if [[ ! $(uname -s) =~ Darwin || $_ls == "gls" ]]; then
  alias ls='$_ls --color=auto'
fi

#######################################################################
#                                marks                                #
#######################################################################

# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
export MARKPATH="$HOME/.marks"

jump()
{
  [[ -z $1 ]] \
    && ls -l "$MARKPATH" | tr -s ' ' | cut -d' ' -f9- | awk NF | awk -F ' -> ' '{printf "    %-10s -> %s\n", $1, $2}' \
    || cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}

mark()
{
  mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

unmark()
{
  rm -i "$MARKPATH/$1"
}

#######################################################################
#                              cd utils                               #
#######################################################################

declare -a __cd_history__

__add_to_hist()
{
  local hist_size="${#__cd_history__[@]}"
  if [[ ${__cd_history__[$hist_size]} != $1 && ! -z $1 ]]; then
    __cd_history__[$(( $hist_size + 1 ))]="$1"
  fi
}

__dir_history()
{
  if [[ $PWD != $OLDPWD ]]; then
    __add_to_hist $OLDPWD
  fi
}

function _list_cd_local_hist()
{
  [[ $# -gt 0 && ! $1 =~ ^[1-9][0-9]*$ ]] &&
    return
  local hist_size="${#__cd_history__[@]}"
  local min
  if [[ $# -eq 1 ]]; then
    min="$(( $hist_size - $1 + 1 ))"
    min="$(( $min < 1 ? 1 : $min ))"
  else
    min=1
  fi
  for (( i = $min ; i <= $hist_size ; ++i )); do
    printf "%4d %4d  %s\n" "$i" "$(($i - $hist_size - 1))" "${__cd_history__[$i]}"
  done
}

function local_cd_hist()
{
  local dir
  if [[ $# -eq 0 || $1 =~ ^-l([1-9][0-9]*)?$ ]]; then
    local limit
    if [[ ${1:2} =~ ^[1-9][0-9]*$ ]]; then
      limit="${1:2}"
    elif [[ $# -eq 0 ]]; then
      limit=15
    fi
    _list_cd_local_hist $limit
  else
    local pat
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
      dir="${__cd_history__[$1]}"
    elif [[ $1 = "-" ]]; then
      dir="${__cd_history__[-1]}"
    fi
    if [[ -z $dir ]]; then
      pat="$@"
      pat="$($_sed 's/\./\\./g' <<< "$pat")"
      pat="$($_sed 's/\ /.*/g' <<< "$pat")"
      dir=$(printf "%s\n" "${__cd_history__[@]}" | grep $pat | tail -n1)
    fi
    [[ -z $dir ]] && return
    if [[ -d $dir ]]; then
      cd "$dir" && echo "$dir"
    else
      echo "Not a directory: $dir" >&2
    fi
  fi
}

# vim: ft=zsh

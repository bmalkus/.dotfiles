#!/bin/bash

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is needed to install dotfiles" >&2
  exit 1
fi

target_dir="$HOME/.dotfiles"

if [ ! -d $target_dir/.git ]; then
  git clone --recursive https://github.com/bmalkus/.dotfiles "$target_dir"
fi

_install()
{
  target=$(basename "$1")
  [ -L "$target" ] && unlink "$target"
  [ -e "$target" ] && mv "$target" "${target}.old" && echo "$target -> ${target}.old"
  ln -s "$1"
}

_install_cp()
{
  target=$(basename "$1")
  [ -L "$target" ] && unlink "$target"
  [ -e "$target" ] && mv "$target" "${target}.old" && echo "$target -> ${target}.old"
  cp "$1" .
}

cd

_install "$target_dir/.gitconfig"

_install "$target_dir/.zshrc"
_install "$target_dir/.bashrc"

_install "$target_dir/.tmux.conf"

_install "$target_dir/.vim"
_install "$target_dir/.vim/.vimrc"

_install "$target_dir/.terminfo"

if [[ $(uname -s) =~ Darwin ]]; then
  cd $HOME/Library/Filters/
  for f in $target_dir/filters/*; do
    _install_cp "$f"
  done
fi

mkdir -p $HOME/.config/fish/
cd $HOME/.config/fish/

_install "$target_dir/config.fish"
_install "$target_dir/fish_plugins"

if [ ! -f "$target_dir/.vim/vim-plug/autoload/plug.vim" ]; then
  echo "Downloading plug.vim"
  curl -#fLo "$target_dir/.vim/vim-plug/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

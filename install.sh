#!/bin/bash

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is needed to install dotfiles" >&2
  exit 1
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

TARGET_DIR="$HOME/.dotfiles"

if [ ! -d $TARGET_DIR/.git ]; then
  mkdir "$TARGET_DIR"
  chmod 700 "$TARGET_DIR"
  git clone --recursive https://github.com/bmalkus/.dotfiles "$TARGET_DIR"
fi

cd

[ -L ".gitconfig" ] && unlink ".gitconfig"
if ! git config --global --get include.path "^${TARGET_DIR/./\\.}/\.gitconfig\$" >/dev/null; then
  git config --global --add include.path "$TARGET_DIR/.gitconfig"
fi


_install "$TARGET_DIR/.zshrc"
_install "$TARGET_DIR/.bashrc"

_install "$TARGET_DIR/.tmux.conf"

_install "$TARGET_DIR/.vim"
_install "$TARGET_DIR/.vim/.vimrc"

mkdir -p $HOME/.config/fish/
cd $HOME/.config/fish/

_install "$TARGET_DIR/config.fish"
_install "$TARGET_DIR/fish_plugins"

cd $HOME/.config

_install "$TARGET_DIR/nvim"
[ ! -e "./nvim/lua/conf/local.lua" ] && cp "./nvim/lua/conf/local.lua.template" "./nvim/lua/conf/local.lua"

if [ ! -f "$TARGET_DIR/.vim/vim-plug/autoload/plug.vim" ]; then
  echo "Downloading plug.vim"
  curl -#fLo "$TARGET_DIR/.vim/vim-plug/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

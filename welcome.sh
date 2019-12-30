#!/bin/bash

mkdir -p ~/.config/git/diff-so-fancy
curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy -o ~/.config/git/diff-so-fancy/diff-so-fancy
chmod 740 ~/.config/git/diff-so-fancy/diff-so-fancy

#git clone https://github.com/ecalifornica/dotfiles.git

rm -f ~/.tmux.conf && ln -s dotfiles/.tmux.conf ~/.tmux.conf
rm -f ~/.vimrc && ln -s dotfiles/.vimrc ~/.vimrc
rm -f ~/.gitconfig && ln -s dotfiles/.gitconfig ~/.gitconfig
rm -f ~/.bash_aliases && ln -s dotfiles/.bash_aliases ~/.bash_aliases

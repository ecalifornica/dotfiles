#!/bin/bash

rm -f ~/.tmux.conf && ln -s dotfiles/.tmux.conf ~/.tmux.conf
rm -f ~/.vimrc && ln -s dotfiles/.vimrc ~/.vimrc
rm -f ~/.gitconfig && ln -s dotfiles/.gitconfig ~/.gitconfig
rm -f ~/.bash_aliases && ln -s dotfiles/.bash_aliases ~/.bash_aliases

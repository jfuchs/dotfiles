#!/bin/sh

# CODESPACES INSTALL SCRIPT

set -e # -e: exit on error

printf 'Installing apt-get packages...\n'
sudo apt-get update -y
sudo apt-get install -y \
  fd-find \
  fzf \
  gh \
  jq \
  wget \
  git \
  zsh-autosuggestions \
  zsh-syntax-highlighting

printf 'Installing starship...\n'
curl -sS https://starship.rs/install.sh | sh -s -- -y

printf 'Setting zsh as shell\n'
if [ -n "$(grep $(whoami) /etc/passwd)" ] && ! grep -q "$(whoami).*/bin/zsh" /etc/passwd; then
  sudo chsh -s /bin/zsh $(whoami)
fi

printf 'Installing dotfiles via chezmoi...\n'
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jfuchs

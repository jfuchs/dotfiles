#!/bin/sh

# CODESPACES INSTALL SCRIPT

set -e # -e: exit on error

printf 'Removing broken Yarn apt repo if present...\n'
sudo rm -f /etc/apt/sources.list.d/yarn.list

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

printf 'Installing jj...\n'
gh release download --repo jj-vcs/jj --pattern '*x86_64-unknown-linux-musl.tar.gz' --dir /tmp --clobber
sudo tar xzf /tmp/jj-*-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin --strip-components=1 --wildcards '*/jj'
rm -f /tmp/jj-*-x86_64-unknown-linux-musl.tar.gz

printf 'Setting zsh as shell\n'
if [ -n "$(grep $(whoami) /etc/passwd)" ] && ! grep -q "$(whoami).*/bin/zsh" /etc/passwd; then
  sudo chsh -s /bin/zsh $(whoami)
fi

printf 'Installing dotfiles via chezmoi...\n'
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jfuchs

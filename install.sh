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
  git

# Install jj (Jujutsu) for Linux
if ! command -v jj &> /dev/null; then
  printf 'Installing jj (Jujutsu)...\n'
  if command -v cargo &> /dev/null; then
    cargo install --git https://github.com/martinvonz/jj jj-cli --bin jj
  else
    # Install Rust/Cargo first, then jj
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    cargo install --git https://github.com/martinvonz/jj jj-cli --bin jj
  fi
fi

printf 'Setting zsh as shell\n'
if [ -n "$(grep $(whoami) /etc/passwd)" ] && ! grep -q "$(whoami).*/bin/zsh" /etc/passwd; then
  sudo chsh -s /bin/zsh $(whoami)
fi

printf 'Installing ohmyzsh\n'
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

printf 'Installing zsh syntax highlighting\n'
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

printf 'Installing zsh autosuggestions\n'
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

printf 'Installing p10k\n'
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

printf 'Installing zshrc\n'
if [ -f "$HOME/.zshrc" ]; then
  if [ "$(diff $HOME/.zshrc ./dot_zshrc)" ]; then
    mv --backup=t $HOME/.zshrc $HOME/.zshrc.bak
    printf 'Backed up existing .zshrc\n'
  fi
fi
cp ./dot_zshrc $HOME/.zshrc

printf 'Installing p10k config\n'
if [ -f "$HOME/.p10k.zsh" ]; then
  if [ "$(diff $HOME/.p10k.zsh ./dot_p10k.zsh)" ]; then
    mv --backup=t $HOME/.p10k.zsh $HOME/.p10k.zsh.bak
    printf 'Backed up existing .p10k.zsh\n'
  fi
fi
cp ./dot_p10k.zsh $HOME/.p10k.zsh



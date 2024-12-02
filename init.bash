#!/bin/bash
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)

echo "Installing Haskling Font"

sudo apt install -y fontconfig

wget -P $USER_HOME/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hasklig.zip \
&& cd $USER_HOME/.local/share/fonts \
&& unzip Hasklig.zip \
&& rm Hasklig.zip \
&& fc-cache -fv

cd $USER_HOME/
echo "Installing Applications"


# Install NeoVim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo rm nvim-linux64.tar.gz

# Install NeoVim Package Manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Install fzf
mkdir /opt/fzf
wget -qO- https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-linux_amd64.tar.gz | tar -xvz -C /opt/fzf


# Install DotFiles
echo "Creating Your Enviorment"
ln -sf $USER_HOME/dotfiles/bashrc $USER_HOME/.bashrc
ln -sf $USER_HOME/dotfiles/bash_aliases $USER_HOME/.bash_aliases

mkdir -p $USER_HOME/.config/nvim
ln -sf $USER_HOME/dotfiles/nvim $USER_HOME/.config/nvim/init.vim


# Fin
echo ""
echo ""
echo "Everything is fine..."
echo "Please reload with '. $USER_HOME/.bashrc'"

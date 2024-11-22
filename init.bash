echo "Installing Haskling Font"

sudo apt install -y fontconfig

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hasklig.zip \
&& cd ~/.local/share/fonts \
&& unzip Hasklig.zip \
&& rm Hasklig.zip \
&& fc-cache -fv

cd ~/
echo "Installing Applications"




# Install NeoVim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo rm nvim-linux64.tar.gz

# Install NeoVim Package Manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "Creating Your Enviorment"
ln -s ~/dotfiles/bashrc ~/.bashrc
ln -s ~/dotfiles/bash_aliases ~/.bash_aliases

mkdir -p ~/.config/nvim
ln -s ~/dotfiles/nvim ~/.config/nvim/init.vim


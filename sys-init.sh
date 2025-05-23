#!/usr/bin/env bash

# Check if the user has sudo privileges
if ! sudo -v; then
    echo "Error: User does not have sudo privileges. Exiting."
    exit 1
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh

# MARK: Fancy Functions
# usage: run_with_spinner "command" "Loading Message"
run_with_spinner() {
    local cmd="$1"
    local msg="$2"

    echo -n "$msg  "

    # bash -c "$cmd" > /dev/null 2>&1 &
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!

    local spin='|/-\'
    local i=0

    # Show spinner while the command runs
    while kill -0 $pid 2>/dev/null; do
        printf "\b${spin:i++%${#spin}:1}"
        sleep 0.1
    done

    wait $pid
    echo -e "\b\b - done."
}

# MARK: Update Packages
run_with_spinner "sudo apt update" "Updating package lists"
run_with_spinner "sudo apt upgrade -y" "Upgrading installed packages"

# MARK: Add ssh-agent to bashrc
line='eval $(ssh-agent)'
if ! grep -Fxq "$line" ~/.bashrc; then
    echo "$line" >> ~/.bashrc
    echo "Appended ssh-agent to ~/.bashrc"
else
    echo "ssh-agent already exists in ~/.bashrc"
fi

# MARK: Add authorized_keys
AUTH_KEYS=~/.ssh/authorized_keys
if [ ! -s "$AUTH_KEYS" ]; then
    echo ""
    read -p "Do you want to generate and add a new SSH key? (y/n): " add_ssh_key
    if [[ "$add_ssh_key" =~ ^[Yy]$ ]]; then

        # Generate SSH key if it doesn't already exist
        read -p "Enter username for SSH key comment (e.g., johndoe): " ssh_user
        read -p "Enter name for key file (e.g., computer_key): " computer_key
        ssh-keygen -t ed25519 -b 4096 -C "$ssh_user" -f ~/.ssh/$computer_key -N "" > /dev/null 2>&1
        mv ~/.ssh/$computer_key ~/.ssh/$computer_key.key
        mv ~/.ssh/$computer_key.pub ~/.ssh/$computer_key.pem
        cat ~/.ssh/$computer_key.pem >> "$AUTH_KEYS"        
        chmod 600 "$AUTH_KEYS"
        echo "SSH public key added to authorized_keys."
        echo "Keep it secret. Keep it safe."

    else
        echo "Skipping SSH key setup."
    fi
else
    echo "Authorized Key already configured"
fi

# MARK: Add bitbucket keys
bitbucket_file=$(find ~/.ssh -type f -name "*bitbucket*.key" 2>/dev/null | head -n 1)
if [ -z "$bitbucket_file" ]; then
    echo ""
    read -p "No Bitbucket .key file found in ~/.ssh. Do you want to generate one? (y/n):" add_bitbucket_key
    if [[ "$add_bitbucket_key" =~ ^[Yy]$ ]]; then
        # Generate Key
        read -p "Enter eMail for SSH key comment (e.g., johndoe@work.com): " ssh_user
        read -p "Enter name for key file (e.g., work): " bitbucket_key
        ssh-keygen -t ed25519 -b 4096 -C "$ssh_user" -f ~/.ssh/bitbucket-$bitbucket_key -N "" > /dev/null 2>&1
        mv ~/.ssh/bitbucket-$bitbucket_key ~/.ssh/bitbucket-$bitbucket_key.key
        mv ~/.ssh/bitbucket-$bitbucket_key.pub ~/.ssh/bitbucket-$bitbucket_key.pem

        # Add Key to Config
        SSH_CONFIG=~/.ssh/config
        BITBUCKET_HOST_CONFIG=$(cat <<EOF
Host bitbucket.org
    AddKeysToAgent Yes
    IdentityFile ~/.ssh/bitbucket-$bitbucket_key.key
EOF
)
        if ! grep -q "Host bitbucket.org" "$SSH_CONFIG"; then
            echo -e "\n$BITBUCKET_HOST_CONFIG" >> "$SSH_CONFIG"
            echo "Added Bitbucket host config to $SSH_CONFIG"
        else
            echo "Bitbucket host config already exists in $SSH_CONFIG"
        fi
    else
        echo "Skipping Bitbucket setup."
    fi
    # Optional: prompt to generate or import a Bitbucket key here
else
    echo "Bitbucket key found: $bitbucket_file"
fi

# MARK: Git Setup
existing_username=$(git config --global user.name)
existing_email=$(git config --global user.email)
if [ -n "$existing_username" ] && [ -n "$existing_email" ]; then
    echo "Git username and email are already set"
else
    echo ""
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email

    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    echo "Git username and email set to:"
    git config --global user.name
    git config --global user.email
    echo ""
fi


# MARK: Install Docker
install_docker() {
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

DOCKER_LOG_CONFIG=$(cat <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
)
echo "$DOCKER_LOG_CONFIG" | sudo tee /etc/docker/daemon.json > /dev/null

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

}

if ! command -v docker &> /dev/null; then
    read -p "Do you want configure docker? (y/n): " config_docker
    if [[ "$config_docker" =~ ^[Yy]$ ]]; then
    run_with_spinner install_docker "Installing Docker"
    echo "You must log out and log back in for Docker group changes to take effect."
    fi
else
    echo "Docker is already installed, no action needed"
fi

echo ""
echo "System is now fully configured."
echo "Have Fun"

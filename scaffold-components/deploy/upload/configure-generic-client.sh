#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

# # sleep until instance is ready
# until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
#     sleep 1
# done

CONSOLE_PASSWORD=$1

sudo apt update -y && sudo apt install -y snapd
sudo snap install core
sudo snap refresh core
sudo snap install snapd
sudo snap refresh snapd

if [[ -z "$(which make)" ]]; then
    sudo apt install -y make
fi

# Install Go if not present
if [[ -z "$(which go)" ]]; then
    sudo snap install --classic --channel=1.22/stable go
fi

# Install dasel if not present
if [[ -z "$(which dasel)" ]]; then
    sudo wget -qO /usr/local/bin/dasel https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_amd64
    sudo chmod +x /usr/local/bin/dasel
fi

# Install jq if not present
if [[ -z "$(which jq)" ]]; then
    sudo apt update -y
    sudo apt install -y jq
fi

# Install Ignite CLI if not present
if [[ -z "$(which ignite)" ]]; then
    sudo curl https://get.ignite.com/cli! | sudo bash
fi

# Install certbot if not present
if [[ -z "$(which certbot)" ]]; then
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
fi

# Kill existing processes
pkill newchaind || :

sleep 1

# Set maximum number of open files
ulimit -n 4096

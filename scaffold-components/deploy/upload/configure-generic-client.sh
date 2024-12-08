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
if [[ -z "$(which go)" ]]; then
    sudo snap install --classic --channel=1.22/stable go
fi
if [[ -z "$(which dasel)" ]]; then
    sudo wget -qO /usr/local/bin/dasel https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_amd64
    sudo chmod a+x /usr/local/bin/dasel
fi
if [[ -z "$(which jq)" ]]; then
    sudo apt update -y && sudo apt install -y jq
fi
if [[ -z "$(which ignite)" ]]; then
    sudo curl https://get.ignite.com/cli! | sudo bash
fi
if [[ -z "$(which certbot)" ]]; then
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
fi

# pkill ignite || : # if failed, ignite wasn't running
pkill newchaind || : # if failed, newchaind wasn't running
sleep 1

ulimit -n 4096 # set maximum number of open files to 4096

sudo usermod --password $(echo $CONSOLE_PASSWORD | openssl passwd -1 -stdin) ubuntu

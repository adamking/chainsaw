#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

NODE_INDEX=$1
DNS_ZONE_NAME=$2

# Install Node.js v20.x
curl -sL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh

# Install Yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

# Clone explorer if not present
if [[ ! -d "explorer" ]]; then
    git clone https://github.com/ping-pub/explorer.git explorer
fi
cd explorer

# Set new chain variables
NEW_CHAIN_LOWER='newchain'
NEW_CHAIN_UPPER='NEWCHAIN'
NEW_CHAIN_TITLE='Newchain'
NEW_DOMAIN='newdomain.com'

git checkout ${NEW_CHAIN_LOWER}-deployment
git pull

# Replace placeholders
git grep -l "$NEW_CHAIN_LOWER" | xargs sed -i -e "s/${NEW_CHAIN_LOWER}/newchain/g"
git grep -l "$NEW_CHAIN_UPPER" | xargs sed -i -e "s/${NEW_CHAIN_UPPER}/NEWCHAIN/g"
git grep -l "$NEW_CHAIN_TITLE" | xargs sed -i -e "s/${NEW_CHAIN_TITLE}/Newchain/g"
git grep -l "$NEW_DOMAIN" | xargs sed -i -e "s/${NEW_DOMAIN}/${DNS_ZONE_NAME}/g"

# Move logo and config files if they exist
if [[ -f "public/logos/${NEW_CHAIN_LOWER}.png" ]]; then
    git mv public/logos/${NEW_CHAIN_LOWER}.png public/logos/newchain.png
fi

if [[ -f "public/logos/${NEW_CHAIN_LOWER}stake.png" ]]; then
    git mv public/logos/${NEW_CHAIN_LOWER}stake.png public/logos/newchainstake.png
fi

if [[ -f "src/chains/mainnet/${NEW_CHAIN_LOWER}.json" ]]; then
    git mv src/chains/mainnet/${NEW_CHAIN_LOWER}.json src/chains/mainnet/newchain.json
fi

if [[ -f "src/chains/testnet/${NEW_CHAIN_LOWER}.json" ]]; then
    git mv src/chains/testnet/${NEW_CHAIN_LOWER}.json src/chains/testnet/newchain.json
fi

yarn

# Configure systemd service
cat >/tmp/explorer.service <<-EOF
[Unit]
Description=blockchain explorer
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/upload/start-explorer.sh
ExecStop=sudo killall node
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/explorer.service /etc/systemd/system/explorer.service
sudo chmod 664 /etc/systemd/system/explorer.service
sudo systemctl daemon-reload

# Configure system settings
# Uncomment the cron job if needed
# line="* * * * * /home/ubuntu/upload/drop_caches.sh"
# (
#     sudo crontab -l
#     echo "$line"
#     echo
# ) | sudo crontab -u root -

sudo sysctl vm.swappiness=0
sudo setcap cap_net_bind_service=ep /usr/bin/node

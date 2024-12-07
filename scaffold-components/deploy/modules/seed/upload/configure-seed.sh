#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

ENV=$1
NODE_INDEX=$2
SEED_IPS_STR=$3
VALIDATOR_IPS_STR=$4
TOKEN_NAME=$5

# Validate NODE_INDEX
if [[ "$NODE_INDEX" -lt 0 || "$NODE_INDEX" -ge $(echo "$VALIDATOR_IPS_STR" | tr ',' '\n' | wc -l) ]]; then
    echo "Invalid NODE_INDEX: $NODE_INDEX"
    exit 1
fi

# Assign MONIKER based on NODE_INDEX
if [[ "$NODE_INDEX" == "0" ]]; then
    MONIKER="black"
elif [[ "$NODE_INDEX" == "1" ]]; then
    MONIKER="white"
else
    MONIKER="gray"
fi

# Convert IP strings to arrays
IFS=',' read -r -a SEED_IPS <<< "$SEED_IPS_STR"
IFS=',' read -r -a VALIDATOR_IPS <<< "$VALIDATOR_IPS_STR"

# Placeholder P2P keys (replace with secure key management)
SEED_P2P_KEYS=(9038832904699724f0b62188e088a86acb629fad de77ff9811178b9b14507dae3cde3ffa0df68130 192fd886732afb466690f1e098ddd62cfe7a63e4)
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

# External Address
P2P_EXTERNAL_ADDRESS="tcp://${SEED_IPS[$NODE_INDEX]}:26656"

# Build persistent peers string
P2P_PERSISTENT_PEERS=""
for i in "${!VALIDATOR_IPS[@]}"; do
    if [[ "$i" != "$NODE_INDEX" ]]; then
        P2P_PERSISTENT_PEERS+="${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
    fi
done

# Initialize newchain
rm -rf ~/.newchain
~/upload/newchaind init "$MONIKER" --chain-id "newchain-${ENV}-1"
cp "/home/ubuntu/upload/node_key_seed_${NODE_INDEX}.json" ~/.newchain/config/node_key.json
cp "/home/ubuntu/upload/genesis.json" ~/.newchain/config/

# Configure systemd service
cat >/tmp/newchain.service <<-EOF
[Unit]
Description=Start newchain blockchain client running as a seed node
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/upload/start-seed.sh ${NODE_INDEX}
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/newchain.service /etc/systemd/system/newchain.service
sudo chmod 664 /etc/systemd/system/newchain.service
sudo systemctl daemon-reload

# Update configuration using dasel
dasel put -f ~/.newchain/config/config.toml -v "${P2P_EXTERNAL_ADDRESS}" ".p2p.external_address"
dasel put -f ~/.newchain/config/config.toml -v "${P2P_PERSISTENT_PEERS}" ".p2p.persistent_peers"
dasel put -t bool -f ~/.newchain/config/app.toml -v true ".api.enable"
dasel put -f ~/.newchain/config/app.toml -v "1${TOKEN_NAME}" ".minimum-gas-prices"

# Install Nginx
sudo DEBIAN_FRONTEND=noninteractive apt install -y nginx

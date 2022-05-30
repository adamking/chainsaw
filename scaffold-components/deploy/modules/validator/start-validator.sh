#!/usr/bin/env bash
set -x
set -e

NODE_INDEX=$1

if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi
echo MONIKER=$MONIKER

cd ~/newchain
# nohup ignite chain serve --verbose >newchain.out 2>&1 </dev/null &
nohup build/newchaind start >newchain.out 2>&1 </dev/null &
sleep 2
echo "Started validator node ${MONIKER} with NODE_INDEX ${NODE_INDEX} and id $(build/newchaind tendermint show-node-id)"

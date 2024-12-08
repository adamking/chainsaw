#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))
ENV=$1
NUM_VALIDATORS=$2

if [[ (! $ENV =~ ^mainnet|testnet$) || "$NUM_VALIDATORS" = "" ]]; then
    echo "Usage: ./backup-keys.sh <testnet|mainnet> <num-validators>"
    exit 1
fi

mkdir -p ~/newchain-keys-backup
NUM_VALIDATORS_MINUS_1=$(($NUM_VALIDATORS - 1))
for i in $(seq 0 $NUM_VALIDATORS_MINUS_1);
do
    scp ubuntu@$(deploy/show-ip.sh validator $i):.newchain/config/keys-backup/\*.txt ~/newchain-keys-backup/
done

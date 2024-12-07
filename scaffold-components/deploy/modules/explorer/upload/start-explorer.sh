#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

echo "About to start ping-pub block explorer server via yarn..."
cd ~/explorer
yarn serve >> ~/explorer/server.log 2>&1

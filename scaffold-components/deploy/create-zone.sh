#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..
ENV=$1
AWS_PROFILE=$2
DNS_ZONE_PARENT=$3
TLS_CERTIFICATE_EMAIL=$4
TOKEN_NAME=$5
VALIDATOR_KEYS_PASSPHRASE=$6
CONSOLE_PASSWORD=$7

if [[ (! $ENV =~ ^mainnet|testnet$) || "$AWS_PROFILE" = "" ||  "$DNS_ZONE_PARENT" = "" || "$TLS_CERTIFICATE_EMAIL" = "" || "${TOKEN_NAME}" = "" || "${VALIDATOR_KEYS_PASSPHRASE}" = "" ]]; then
    echo "Usage: ./create-zone.sh <testnet|mainnet> <aws-profile> <dns-zone-parent> <tls-certificate-contact-email> <token-name> <valdiator-keys-passphrase>"
    exit 1
fi
cat >${SCRIPT_DIR}/persistent.${ENV}.tfvars <<EOF
dns_zone_parent = "$DNS_ZONE_PARENT"
tls_certificate_email = "$TLS_CERTIFICATE_EMAIL"
validator_keys_passphrase = "$VALIDATOR_KEYS_PASSPHRASE"
console_password = "$CONSOLE_PASSWORD"
token_name = "${TOKEN_NAME}"
aws_profile = "${AWS_PROFILE}"
env = "${ENV}"
EOF

terraform -chdir=deploy workspace select -or-create ${ENV}
terraform -chdir=deploy apply -auto-approve -var="env=${ENV}" -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var-file="persistent.${ENV}.tfvars"

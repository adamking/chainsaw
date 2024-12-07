#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and ensure pipelines fail correctly.
set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $(basename "$0") <github-org-name> <chain-name>"
    echo
    echo "Options:"
    echo "  github-org-name: Your GitHub organization or username"
    echo "  chain-name: Name of your blockchain (lowercase letters and hyphens only)"
    exit 1
}

# Function to check if a command exists
check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required command '$1' not found."
        echo "Please install it using one of the following:"
        case "$1" in
            ignite)
                echo "  brew install ignite"
                ;;
            terraform)
                echo "  brew install terraform"
                ;;
            docker)
                echo "  Please install Docker Desktop from https://docs.docker.com/get-docker/"
                ;;
            *)
                echo "  brew install $1"
                ;;
        esac
        exit 1
    fi

    # Check versions for critical dependencies
    case "$1" in
        go)
            GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
            if [[ "$(printf '%s\n' "1.21.0" "$GO_VERSION" | sort -V | head -n1)" != "1.21.0" ]]; then
                echo "Error: Go version must be at least 1.21.0 (found $GO_VERSION)"
                exit 1
            fi
            ;;
        docker)
            if ! docker info >/dev/null 2>&1; then
                echo "Error: Docker Desktop is not running. Please start Docker Desktop."
                exit 1
            fi
            ;;
    esac
}

# Function to validate input
validate_input() {
    local input=$1
    local pattern="^[a-z][a-z0-9-]*$"
    if [[ ! $input =~ $pattern ]]; then
        echo "Error: '$input' is not valid. Use only lowercase letters, numbers, and hyphens, starting with a letter."
        exit 1
    fi
}

# Check dependencies
check_dependency "ignite"
check_dependency "terraform"
check_dependency "git"
check_dependency "perl"
check_dependency "aws"
check_dependency "docker"
check_dependency "go"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if the required arguments are provided
if [[ $# -ne 2 ]]; then
    usage
fi

GITHUB_USERNAME="$1"
CHAIN_NAME_INPUT="$2"

# Validate inputs
validate_input "$GITHUB_USERNAME"
validate_input "$CHAIN_NAME_INPUT"

# Convert CHAIN_NAME to different cases
CHAIN_NAME=$(echo "$CHAIN_NAME_INPUT" | tr '[:upper:]' '[:lower:]')
CHAIN_NAME_UPPER=$(echo "$CHAIN_NAME" | tr '[:lower:]' '[:upper:]')
CHAIN_NAME_TITLE="$(echo "${CHAIN_NAME:0:1}" | tr '[:lower:]' '[:upper:]')${CHAIN_NAME:1}"

# Define directories - use portable path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
IGNITE_DIR="$HOME/.ignite/local-chains"
GITIGNORE_CONTENT="
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
.DS_Store
.env
*.log
"

# Create backup of existing chain if it exists
if [ -d "$CHAIN_NAME" ]; then
    BACKUP_DIR="${CHAIN_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "📦 Creating backup of existing chain as $BACKUP_DIR..."
    
    # Attempt to create backup
    if ! cp -r "$CHAIN_NAME" "$BACKUP_DIR"; then
        echo "Error: Failed to create backup of existing chain"
        exit 1
    fi
    
    # Verify backup was created successfully
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Error: Backup directory was not created successfully"
        exit 1
    fi
    
    # Compare file counts to ensure complete backup
    ORIGINAL_COUNT=$(find "$CHAIN_NAME" -type f | wc -l)
    BACKUP_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
    
    if [ "$ORIGINAL_COUNT" != "$BACKUP_COUNT" ]; then
        echo "Error: Backup appears to be incomplete (file count mismatch)"
        echo "Original: $ORIGINAL_COUNT files, Backup: $BACKUP_COUNT files"
        exit 1
    fi
    
    # Remove original directory only after successful backup
    rm -rf "$CHAIN_NAME"
    echo "✅ Backup created successfully"
fi

echo "🔄 Cleaning existing chain directories..."
# Clean existing chain directories
rm -rf "$HOME_DIR/.$CHAIN_NAME" "$IGNITE_DIR/$CHAIN_NAME"

echo "🏗️  Scaffolding new chain..."
# Scaffold new chain
if ! ignite scaffold chain "github.com/${GITHUB_USERNAME}/${CHAIN_NAME}" --address-prefix "$CHAIN_NAME" --clear-cache; then
    echo "Error: Failed to scaffold chain"
    exit 1
fi

cd "$CHAIN_NAME" || exit 1

echo "📋 Copying scaffold components..."
# Copy scaffold components
if ! cp -r "${SCRIPT_DIR}/scaffold-components/"* .; then
    echo "Error: Failed to copy scaffold components"
    exit 1
fi

echo "🔄 Replacing placeholders in files..."
# Replace placeholders in files
find . -type f -exec perl -i -pe "s/newchain/${CHAIN_NAME}/g" {} +
find . -type f -exec perl -i -pe "s/Newchain/${CHAIN_NAME_TITLE}/g" {} +
find . -type f -exec perl -i -pe "s/NEWCHAIN/${CHAIN_NAME_UPPER}/g" {} +
find . -type f -exec perl -i -pe "s/github_username/${GITHUB_USERNAME}/g" {} +

# Append to .gitignore
echo "$GITIGNORE_CONTENT" >> .gitignore

echo "🌱 Initializing Terraform..."
# Initialize Terraform
if ! terraform -chdir=deploy init; then
    echo "Error: Failed to initialize Terraform"
    exit 1
fi

echo "📦 Setting up Git repository..."
# Initialize git if needed
if [ ! -d ".git" ]; then
    git init
fi

# Add all changes to git and create initial commit
git add .
git commit -m "Initial chain scaffold for ${CHAIN_NAME}"

echo "✅ Chain setup complete! You can now cd into ${CHAIN_NAME} to start development."
echo "📝 Next steps:"
echo "1. Set up your DNS zone using deploy/create-zone.sh"
echo "2. Deploy your testnet using deploy/create-servers.sh"
echo
echo "🔍 For more information, check the README.md file in your chain directory."

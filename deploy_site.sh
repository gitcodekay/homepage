#!/bin/bash
LOG_FILE="/var/log/deploy-site.log"
FLAG_NAME="hold_deploy.txt"
TEMP_DIR="/tmp/main"

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "$(date) [ERROR] : Missing parameters. Usage: $0 <repo_dir> <sub-site>" >> "$LOG_FILE"
    echo "Usage: $0 <repo_dir> <sub-site>" >&2
    echo "  sub-site: Use '-' for root directory or specify sub-site name" >&2
    exit 1
fi

REPO_DIR="$1"
SUB_SITE="$2"

# Determine the full repository path and flag location
if [ "$SUB_SITE" = "-" ]; then
    FULL_REPO_DIR="$REPO_DIR"
    FLAG_FILE="$REPO_DIR/$FLAG_NAME"
else
    FULL_REPO_DIR="$REPO_DIR/$SUB_SITE"
    FLAG_FILE="$FULL_REPO_DIR/$FLAG_NAME"
    
    # Check if sub-site directory exists
    if [ ! -d "$FULL_REPO_DIR" ]; then
        echo "$(date) [$SUB_SITE] : ERROR - Sub-site directory does not exist: $FULL_REPO_DIR" >> "$LOG_FILE"
        exit 1
    fi
fi

# Check if flag file exists - if it does, deployment is BLOCKED
if [ -f "$FLAG_FILE" ]; then
    # Silently exit - deployment is blocked
    exit 0
fi

echo "$(date) [$SUB_SITE] : No deploy flag found, starting deployment" >> "$LOG_FILE"

# Handle root directory deployment differently
if [ "$SUB_SITE" = "-" ]; then
    # Remove and recreate temp directory
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Clone/pull repo to temp directory
    if [ -d "$TEMP_DIR/.git" ]; then
        cd "$TEMP_DIR" || {
            echo "$(date) [$SUB_SITE] : Failed to change to $TEMP_DIR" >> "$LOG_FILE"
            exit 1
        }
        git pull origin main >> "$LOG_FILE" 2>&1
    else
        # Get the git remote URL from REPO_DIR if it exists
        if [ -d "$REPO_DIR/.git" ]; then
            cd "$REPO_DIR" || {
                echo "$(date) [$SUB_SITE] : Failed to change to $REPO_DIR" >> "$LOG_FILE"
                exit 1
            }
            REMOTE_URL=$(git config --get remote.origin.url)
            git clone "$REMOTE_URL" "$TEMP_DIR" >> "$LOG_FILE" 2>&1
        else
            echo "$(date) [$SUB_SITE] : ERROR - No git repository found in $REPO_DIR" >> "$LOG_FILE"
            exit 1
        fi
    fi
    
    # Copy files one by one from temp to REPO_DIR
    echo "$(date) [$SUB_SITE] : Copying files from $TEMP_DIR to $REPO_DIR" >> "$LOG_FILE"
    
    cd "$TEMP_DIR" || {
        echo "$(date) [$SUB_SITE] : Failed to change to $TEMP_DIR" >> "$LOG_FILE"
        exit 1
    }
    
    # Use rsync or cp to copy files, excluding .git directory
    find . -type f ! -path './.git/*' ! -path './.git' | while read -r file; do
        # Create directory structure if needed
        dir=$(dirname "$file")
        mkdir -p "$REPO_DIR/$dir"
        # Copy file
        cp -f "$file" "$REPO_DIR/$file"
    done
    
    echo "$(date) [$SUB_SITE] : File copy complete" >> "$LOG_FILE"
    
else
    # Sub-site: normal git pull
    cd "$FULL_REPO_DIR" || {
        echo "$(date) [$SUB_SITE] : Failed to change to $FULL_REPO_DIR" >> "$LOG_FILE"
        exit 1
    }
    
    git pull origin main >> "$LOG_FILE" 2>&1
fi

# Create flag to block future deployments
touch "$FLAG_FILE"

echo "$(date) [$SUB_SITE] : Deployment complete, flag created to block future deployments" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

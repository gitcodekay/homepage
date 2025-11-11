#!/bin/bash
LOG_FILE="/var/log/deploy-site.log"
FLAG_NAME="hold_deploy.txt"

# Check if required parameters are provided
if [ $# -lt 4 ]; then
    echo "$(date) [ERROR] : Missing parameters. Usage: $0 <git_url> <build_dir> <dest_dir> <sub-site>" >> "$LOG_FILE"
    echo "Usage: $0 <git_url> <build_dir> <dest_dir> <sub-site>" >&2
    echo "  git_url: GitHub repository clone URL" >&2
    echo "  build_dir: Directory where repository will be cloned/built" >&2
    echo "  dest_dir: Destination directory for deployment" >&2
    echo "  sub-site: Use '-' for root directory or specify sub-site name" >&2
    exit 1
fi

GIT_URL="$1"
BUILD_DIR="$2"
DEST_DIR="$3"
SUB_SITE="$4"

# Determine the full destination path and flag location
if [ "$SUB_SITE" = "-" ]; then
    FULL_DEST_DIR="$DEST_DIR"
    FLAG_FILE="$DEST_DIR/$FLAG_NAME"
else
    FULL_DEST_DIR="$DEST_DIR/$SUB_SITE"
    FLAG_FILE="$FULL_DEST_DIR/$FLAG_NAME"
    
    # Check if sub-site directory exists, create if it doesn't
    if [ ! -d "$FULL_DEST_DIR" ]; then
        echo "$(date) [$SUB_SITE] : Sub-site directory does not exist, creating: $FULL_DEST_DIR" >> "$LOG_FILE"
        mkdir -p "$FULL_DEST_DIR"
    fi
fi

# Check if flag file exists - if it does, deployment is BLOCKED
if [ -f "$FLAG_FILE" ]; then
    # Silently exit - deployment is blocked
    exit 0
fi

echo "$(date) [$SUB_SITE] : No deploy flag found, starting deployment" >> "$LOG_FILE"

# Remove and recreate build directory for fresh clone
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clone repository to build directory
echo "$(date) [$SUB_SITE] : Cloning repository from $GIT_URL to $BUILD_DIR" >> "$LOG_FILE"
git clone "$GIT_URL" "$BUILD_DIR" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "$(date) [$SUB_SITE] : ERROR - Git clone failed" >> "$LOG_FILE"
    exit 1
fi

# Copy files one by one from build directory to destination
echo "$(date) [$SUB_SITE] : Copying files from $BUILD_DIR to $FULL_DEST_DIR" >> "$LOG_FILE"

cd "$BUILD_DIR" || {
    echo "$(date) [$SUB_SITE] : Failed to change to $BUILD_DIR" >> "$LOG_FILE"
    exit 1
}

# Copy all files excluding .git directory
find . -type f ! -path './.git/*' ! -path './.git' | while read -r file; do
    # Create directory structure if needed
    dir=$(dirname "$file")
    mkdir -p "$FULL_DEST_DIR/$dir"
    # Copy file
    cp -f "$file" "$FULL_DEST_DIR/$file"
done

echo "$(date) [$SUB_SITE] : File copy complete" >> "$LOG_FILE"

# Create flag to block future deployments
touch "$FLAG_FILE"
echo "$(date) [$SUB_SITE] : Deployment complete, flag created to block future deployments" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

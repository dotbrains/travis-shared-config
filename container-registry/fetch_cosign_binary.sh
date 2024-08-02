#!/usr/bin/env bash

# Exit on error
set -e

# Exit on error within any pipes used
set -o pipefail

# variables
DOWNLOAD_URL="https://github.com/sigstore/cosign/releases/download/v1.13.1/cosign-linux-pivkey-pkcs11key-amd64"
LOCAL_FILE="./cosign-linux-pivkey-pkcs11key-amd64"
TARGET_LOCATION="/usr/local/bin/cosign"

# Error handling
trap 'catch_error $? $LINENO' EXIT
catch_error() {
  EXIT_STATUS=$1
  if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Error on line $2: The script exited with status $EXIT_STATUS" >&2
    exit "$EXIT_STATUS"
  fi
}

echo "Starting the script"

echo "Downloading the file"
wget -P ./ $DOWNLOAD_URL

echo "Making the file executable"
chmod +x $LOCAL_FILE

echo "Moving the file to the target location"
sudo mv -f $LOCAL_FILE $TARGET_LOCATION

echo "Script finished successfully"

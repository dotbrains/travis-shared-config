#!/usr/bin/env bash

# Exit on error
set -e

# Exit on error within any pipes used
set -o pipefail

# Error handling
trap 'catch_error $? $LINENO' EXIT
catch_error() {
  EXIT_STATUS=$1
  if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Error on line $2: The script exited with status $EXIT_STATUS" >&2
    exit "$EXIT_STATUS"
  fi
}

# Get token
echo "Getting token"
token=$(curl -s -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$COS_APIKEY" | jq -r .'access_token')

if [ -z "$token" ]; then
  echo "Token acquisition failed" >&2
  exit 1
fi

# Get file
echo "Getting file"
result=$(curl -s -w 'RESP_CODE:%{response_code}' -O "https://s3.us-east.cloud-object-storage.appdomain.cloud/code-sign-bucket/client.tgz" \
  -H "Authorization: Bearer ${token}" | grep -o 'RESP_CODE:[1-4][0-9][0-9]')

if [[ $result == *"RESP_CODE:4"* ]]; then
  echo "File download failed with response code 4XX" >&2
  exit 1
elif [[ $result == *"RESP_CODE:1"* ]]; then
  echo "File download failed with response code 1XX" >&2
  exit 1
fi

# Echo response code
echo "Response code: $result"

# Extract file
echo "Extracting file"
tar zxvf client.tgz

# Set noninteractive mode
export DEBIAN_FRONTEND=noninteractive

# Prepare client
echo "Preparing client"
echo "$GARASIGN_PASSWORD" > client/credentials.txt
printf "%s" "$GARASIGN_PFX" | base64 --decode > client/client_auth.pfx

# Make setup script executable
echo "Making setup script executable"
chmod 775 client/setup.sh

# Run setup script
echo "Running setup script"
sudo ./client/setup.sh

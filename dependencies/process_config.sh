#!/bin/bash

CONFIG_FILE="config.json"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

# Check if the JSON is valid
if ! jq empty "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Invalid JSON in $CONFIG_FILE."
    exit 1
fi

# Check if required keys are present
if ! jq -e 'has("node") and has("voters") and has("votes") and has("memo")' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required keys in $CONFIG_FILE."
    exit 1
fi

# Parse config.json
mapfile -t voters < <(jq -r '.voters[]' $CONFIG_FILE)
mapfile -t votes < <(jq -r '.votes[]' $CONFIG_FILE)
node=$(jq -r '.node' $CONFIG_FILE)
memo=$(jq -r '.memo' $CONFIG_FILE)
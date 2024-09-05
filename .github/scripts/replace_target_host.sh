#!/bin/bash

# Ensure the TARGET_HOST environment variable is set
if [ -z "$TARGET_HOST" ]; then
  echo "Error: TARGET_HOST environment variable is not set."
  exit 1
fi

# Ensure the DIRECTORY environment variable is set
if [ -z "$DIRECTORY" ]; then
  echo "Error: DIRECTORY environment variable is not set."
  exit 1
fi

# Loop through all JSON files in the directory
for json_file in "$directory"/*.json; do
  # Check if the file exists
  if [ -f "$json_file" ]; then
    # Use jq to modify the JSON file in place, replacing the target host with the value of the TARGET_HOST environment variable
    jq --arg target_host "$TARGET_HOST" '.api_definition.proxy.target_url |= if . == "TARGET_HOST" then $target_host else . end' "$json_file" > tmpfile && mv tmpfile "$json_file"

    # Check the exit status to confirm successful replacement
    if [ $? -eq 0 ]; then
      echo "Processed: $json_file"
    else
      echo "Error processing: $json_file"
    fi
  else
    echo "No JSON files found in the directory."
  fi
done

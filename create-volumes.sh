#!/bin/bash

# Create Docker volumes for the client
# Usage: ./create-volumes.sh

if [ -z "$CLIENT_NAME" ]; then
    echo "Error: CLIENT_NAME environment variable is not set"
    echo "Please set CLIENT_NAME before running this script"
    exit 1
fi

echo "Creating volumes for client: $CLIENT_NAME"

docker volume create postgres_data_${CLIENT_NAME}
docker volume create n8n_data_${CLIENT_NAME}
docker volume create n8n_files_${CLIENT_NAME}

echo "Volumes created successfully!"
#!/bin/bash

# Configurable variables

# Target Container to be migrated
CONTAINER_NAME="$container_name" #Eg: my-web-app

# Image used by the Container
IMAGE_NAME="$image_name"  #Eg: nginx:latest

# Ports exposed
PORT_MAPPING="$port_mapping" #Eg: 8080:80

# Backup Tar File
BACKUP_FILE="$HOME/image_${CONTAINER_NAME}.tar"

# Your Login Credentials
REMOTE_USER="$user" #Eg: ubuntu

# Destination Server Location
REMOTE_HOST="$destination_server_location" #Eg: 192.168.1.10 or server.example.com

# Path where Backup Tar File needs to be stored
REMOTE_PATH="/home/$REMOTE_USER"

# Enable strict mode and add error handler
set -e
trap 'echo "❌ An error occurred. Exiting."; exit 1' ERR

# Step 1: Save the Docker image
echo "📦 Saving Docker image..."
docker save -o "$BACKUP_FILE" "$IMAGE_NAME" || { echo "Failed to save Docker image."; exit 1; }

# Step 2: Transfer the image to the remote server
echo "🚚 Transferring image to $REMOTE_HOST..."
scp "$BACKUP_FILE" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/" || { echo "Failed to transfer file."; exit 1; }

# Step 3: SSH into the remote server and restore + run the container
echo "🚀 Starting restore on $REMOTE_HOST..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" <<EOF || { echo "SSH command failed."; exit 1; }
  echo "📥 Loading image..."
  docker load -i "$REMOTE_PATH/$(basename "$BACKUP_FILE")" || { echo "Failed to load image."; exit 1; }

  echo "🔄 Running container..."
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -p $PORT_MAPPING \
    --restart unless-stopped \
    "$IMAGE_NAME" || { echo "Failed to start container."; exit 1; }

  echo "✅ Migration complete on $REMOTE_HOST"
EOF

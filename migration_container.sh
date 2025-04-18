#!/bin/bash

# Prompt user for input
read -p "🛠️  Enter container name to migrate: " CONTAINER_NAME
read -p "📦 Enter Docker image name (e.g., repo/image:tag): " IMAGE_NAME
read -p "🔌 Enter port mapping (e.g., 8080:80): " PORT_MAPPING
read -p "👤 Enter remote server username: " REMOTE_USER
read -p "🌐 Enter remote server address (hostname or IP): " REMOTE_HOST

# Backup Tar File
BACKUP_FILE="$HOME/image_${CONTAINER_NAME}.tar"

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
    -p \$PORT_MAPPING \
    --restart unless-stopped \
    "$IMAGE_NAME" || { echo "Failed to start container."; exit 1; }

  echo "✅ Migration complete on $REMOTE_HOST"
EOF

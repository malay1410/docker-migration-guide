
# 🐳 Docker Container Migration – Step-by-Step Guide

> Seamlessly migrate Docker containers — including images, volumes, and configuration — from one server to another with **zero data loss**.

---

## 📌 Why This Guide?

Whether you're upgrading infrastructure, moving to the cloud, or cloning environments, this guide gives you a **safe, repeatable process** to migrate containers with full data integrity and minimal hassle.

---

## ✅ What You'll Learn

- 🔁 Export and load Docker images
- 💾 Backup and restore Docker volumes
- 🧠 Preserve container configuration (entrypoint, env vars, network)
- 🚀 Recreate containers confidently on a new server

---

## 🛠️ Prerequisites

- Docker installed on both source and destination servers
- SSH access between servers
- Basic Linux command-line skills
- `jq` installed for JSON parsing (if recreating from config)

```bash
# Debian/Ubuntu
sudo apt install jq

# macOS (via Homebrew)
brew install jq
```

---

## 🚀 Migration Steps

### 📤 On the **Source Server**

#### 1. Identify the container and its image
```bash
docker ps
docker inspect --format='{{.Config.Image}}' <container_id>
```

#### 2. Save the Docker image to a file
```bash
docker save <image_name> -o ~/image_<container_id>.tar
```

#### 3. Backup any named volumes
```bash
docker inspect <container_id> | grep Name
```

Then for each named volume:
```bash
docker run --rm -v <volume_name>:/volume -v ~/vol_backup:/backup alpine \
  tar czf /backup/<volume_name>.tar.gz -C /volume .
```

#### 4. Export container configuration (optional but useful)
```bash
docker inspect <container_id> > container_config.json
```

#### 5. Transfer all backup files to the destination server
```bash
scp ~/image_<container_id>.tar user@target-host:/home/user/docker_migration/
scp container_config.json user@target-host:/home/user/docker_migration/
scp ~/vol_backup/*.tar.gz user@target-host:/home/user/docker_migration/
```

---

### 📥 On the **Destination Server**

#### 6. Load the Docker image
```bash
docker load -i image_<container_id>.tar
```

#### 7. Restore Docker volumes
```bash
cd /home/user/docker_migration/vol_backup

for archive in *.tar.gz; do
  volume_name=$(basename "$archive" .tar.gz)
  docker volume create "$volume_name"
  docker run --rm -v "$volume_name:/volume" -v $(pwd):/backup alpine \
    tar xzf "/backup/$archive" -C /volume
done
```

#### 8. Recreate the container
Use information from the container config or memory:
```bash
docker run -dit \
  --name <container_name> \
  --network host \
  <image_name> \
  /bin/bash
```

> Add `--restart unless-stopped` if you want it to auto-restart after reboot.

---

## 🧠 Optional Enhancements

- Enable auto-restart:
```bash
--restart unless-stopped
```

- Full example:
```bash
docker run -dit \
  --name my-container \
  --network host \
  --restart unless-stopped \
  my-image-name \
  /bin/bash
```

---

## 🔍 Validation Checklist

- ✅ Is the container running? → `docker ps`
- ✅ Do logs look good? → `docker logs <container_name>`
- ✅ Can you shell into it? → `docker exec -it <container_name> /bin/bash`

---

## 🏁 Success!

You’ve now:

- ✅ Backed up your container’s image, config, and data
- ✅ Transferred all assets to the new host
- ✅ Restored everything and relaunched the container

---

> Save this repo as your go-to guide for Docker container migrations.  
> Built for engineers who value **stability, simplicity, and repeatability**.

---

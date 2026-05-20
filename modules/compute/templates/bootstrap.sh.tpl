#!/bin/bash
set -euo pipefail

# ----- System packages -----
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Docker Compose plugin
COMPOSE_DIR=/usr/local/lib/docker/cli-plugins
mkdir -p "$${COMPOSE_DIR}"
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o "$${COMPOSE_DIR}/docker-compose"
chmod +x "$${COMPOSE_DIR}/docker-compose"

# ----- Mount data EBS volume -----
DEVICE=/dev/xvdf
MOUNT=/var/lib/perpetual-share

# Wait for the volume to appear (EBS attach is async)
for i in $(seq 1 30); do
  [ -b "$${DEVICE}" ] && break
  sleep 2
done

if ! blkid "$${DEVICE}" &>/dev/null; then
  mkfs.ext4 -L perpetual-share-data "$${DEVICE}"
fi

mkdir -p "$${MOUNT}/database"
echo "LABEL=perpetual-share-data $${MOUNT} ext4 defaults,nofail 0 2" >> /etc/fstab
mount -a

# ----- Fetch admin password from SSM -----
ADMIN_PASSWORD=$(aws ssm get-parameter \
  --region "${region}" \
  --name "/perpetual-share/${environment}/admin-password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text 2>/dev/null || echo "secret-admin")

# ----- Write docker-compose -----
APP_DIR=/opt/perpetual-share
mkdir -p "$${APP_DIR}"

cat > "$${APP_DIR}/docker-compose.yml" <<COMPOSE
version: '3.8'
services:
  app:
    image: ${image_uri}
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      PORT: "8080"
      ADMIN_PASSWORD: "$${ADMIN_PASSWORD}"
      S3_BUCKET: "${s3_bucket}"
      AWS_REGION: "${region}"
    volumes:
      - /var/lib/perpetual-share/database:/app/database
    logging:
      driver: awslogs
      options:
        awslogs-region: "${region}"
        awslogs-group: "${cloudwatch_log_group}"
        awslogs-stream-prefix: app
COMPOSE

# ----- Start app (non-fatal if image not yet pushed to ECR) -----
docker compose -f "$${APP_DIR}/docker-compose.yml" up -d || true

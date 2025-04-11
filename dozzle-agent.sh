#!/bin/bash

set -e

# === Настройки ===
DOZZLE_IMAGE="amir20/dozzle:latest"
CERT_DIR="/opt/dozzle/certs"
DATA_DIR="/opt/dozzle/data"
AGENT_NAME="dozzle-agent"
DOCKER_SOCK="/var/run/docker.sock"
DOZZLE_PORT=7007

# === Создание директорий ===
echo "🛠️  Создаю директории..."
sudo mkdir -p "$CERT_DIR"
sudo mkdir -p "$DATA_DIR"

# === Генерация TLS-сертификатов ===
echo "🔐 Генерирую TLS-сертификаты..."
sudo openssl genpkey -algorithm RSA -out "$CERT_DIR/key.pem" -pkeyopt rsa_keygen_bits:2048
sudo openssl req -new -key "$CERT_DIR/key.pem" -out "$CERT_DIR/request.csr" -subj "/C=US/ST=Secure/L=Local/O=Dozzle"
sudo openssl x509 -req -in "$CERT_DIR/request.csr" -signkey "$CERT_DIR/key.pem" -out "$CERT_DIR/cert.pem" -days 365
sudo rm "$CERT_DIR/request.csr"

# === Запуск Dozzle агента ===
echo "🚀 Запускаю Dozzle агент..."
docker run -d \
  --name "$AGENT_NAME" \
  --restart unless-stopped \
  -v "$DOCKER_SOCK":"$DOCKER_SOCK" \
  -v "$CERT_DIR/cert.pem":/dozzle_cert.pem:ro \
  -v "$CERT_DIR/key.pem":/dozzle_key.pem:ro \
  -p "$DOZZLE_PORT":7007 \
  "$DOZZLE_IMAGE" agent

echo "✅ Dozzle агент запущен на порту $DOZZLE_PORT с TLS"
echo "📁 Сертификаты сохранены в: $CERT_DIR"

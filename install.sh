#!/bin/bash

# Проверяем, что скрипт выполняется от root
if [ "$(id -u)" -ne 0 ]; then
  echo "Этот скрипт должен быть запущен с правами root."
  exit 1
fi

# Шаг 1: Обновление и установка зависимостей
echo "Обновление системы и установка зависимостей..."
apt update -y
apt install -y software-properties-common wget git apt-transport-https ca-certificates curl

# Шаг 2: Добавление репозитория и установка Python 3.8 и docker
echo "Добавление репозитория и установка Python 3.8 и docker..."
add-apt-repository ppa:deadsnakes/ppa -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update -y
apt install -y python3.8 python3.8-distutils python3.8-venv install docker-ce

# Шаг 3: Установка pip и виртуального окружения
echo "Установка pip и виртуального окружения..."
wget https://bootstrap.pypa.io/get-pip.py
python3.8 get-pip.py
python3.8 -m pip install virtualenv

# Шаг 4: Клонирование репозитория API
echo "Клонирование репозитория API..."
git clone -b dev https://github.com/hikkahost/api /root/api
cd /root/api

# Шаг 5: Создание виртуального окружения и установка зависимостей
echo "Создание виртуального окружения и установка зависимостей..."
python3.8 -m venv venv
source venv/bin/activate
python3.8 -m pip install -r requirements.txt

# Шаг 6: Выполнение тестов
echo "Запуск тестов..."
python3.8 -m pytest

# Шаг 7: Генерация секретного ключа
SECRET_KEY=$(openssl rand -base64 32)
echo "Секретный ключ сгенерирован: $SECRET_KEY"

# Шаг 8: Создание конфигурации для приложения
echo "Создание конфигурационного файла..."
cat <<EOL > /root/api/app/config.py
# import os
# from dotenv import load_dotenv

# load_dotenv()

CONTAINER = {
    "cpu": 1.0,
    "memory": "512M",
    "size": "3g",
    "rate": "50mbit",
    "burst": "32kbit",
    "latency": "400ms",
}

class Config:
    SECRET_KEY = "$SECRET_KEY"
EOL

# Шаг 9: Создание файла службы systemd
echo "Создание файла systemd для API..."
cat <<EOL > /etc/systemd/system/api.service
[Unit]
Description=docker api
After=network.target

[Service]
WorkingDirectory=/root/api
ExecStart=/root/api/venv/bin/python3.8 -m app
Type=simple
Restart=always
RestartSec=1
User=root

[Install]
WantedBy=multi-user.target
EOL

# Шаг 10: Перезагрузка systemd, запуск и включение службы
echo "Перезагрузка systemd и запуск службы..."
systemctl daemon-reload
systemctl enable api.service
systemctl start api.service

# Шаг 11: Вывод IP адреса и сгенерированного ключа
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "API запущен на IP: $IP_ADDRESS"
echo "Секретный ключ: $SECRET_KEY"

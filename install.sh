#!/bin/bash
set -e

echo "[1/5] Обновление системы..."
sudo apt update && sudo apt install -y python3 python3-pip python3-venv git i2c-tools ddcutil build-essential python3-dev inotify-tools

echo "[2/5] Клонирование репозитория..."
mkdir -p ~/rpi_autobrightness
cd ~/rpi_autobrightness
[ -f autobrightness.py ] || git clone https://github.com/exceptioncpp/rpi_autobrightness.git . || true

echo "[3/5] Настройка виртуального окружения..."
python3 -m venv autobrightness-venv
source autobrightness-venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "[4/5] Установка systemd unit-файлов..."
sudo cp systemd/autobrightness.service /etc/systemd/system/
sudo cp systemd/autobrightness-watcher.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable autobrightness.service autobrightness-watcher.service

echo "[5/5] Настройка прав sudo..."
echo 'pi ALL=NOPASSWD: /bin/systemctl restart autobrightness' | sudo tee /etc/sudoers.d/autobrightness
sudo chmod 440 /etc/sudoers.d/autobrightness

echo "✅ Установка завершена. Запуск служб..."
sudo systemctl start autobrightness.service autobrightness-watcher.service

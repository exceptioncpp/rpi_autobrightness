#!/bin/bash
set -e

echo "[install] Обновление системы и установка зависимостей..."
sudo apt update && sudo apt install -y \
    python3 python3-venv python3-pip git ddcutil i2c-tools \
    python3-dev build-essential libgpiod-dev

echo "[install] Клонирование репозитория и переход в папку..."
REPO_DIR="$HOME/rpi_autobrightness"
if [ ! -d "$REPO_DIR" ]; then
  git clone https://github.com/exceptioncpp/rpi_autobrightness.git "$REPO_DIR"
fi
cd "$REPO_DIR"

echo "[install] Настройка виртуального окружения..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install adafruit-blinka adafruit-circuitpython-bh1750

echo "[install] Добавление пользователя в группы i2c и video..."
sudo usermod -aG i2c,video $USER

echo "[install] Разрешение ddcutil без sudo..."
echo 'ATTRS{name}=="i2c-*", ENV{DEVNAME}=="*i2c*", TAG+="uaccess", GROUP="video", MODE="0660"' | sudo tee /etc/udev/rules.d/99-i2c.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

echo "[install] Установка systemd-сервисов..."
sudo cp autobrightness.service /etc/systemd/system/
sudo cp autobrightness-watcher.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable autobrightness.service autobrightness-watcher.service

echo "[install] Настройка sudo без пароля для перезапуска службы..."
echo "$USER ALL=NOPASSWD: /bin/systemctl restart autobrightness" | sudo tee /etc/sudoers.d/autobrightness
sudo chmod 440 /etc/sudoers.d/autobrightness

echo "[install] Настройка прав на watcher-скрипт..."
chmod +x watch-autobrightness.sh

echo "[install] Отключение светодиодов Raspberry Pi..."
CONFIG=/boot/config.txt
sudo sed -i '/^dtparam=act_led_trigger=/d' $CONFIG
sudo sed -i '/^dtparam=act_led_activelow=/d' $CONFIG
sudo sed -i '/^dtparam=pwr_led_trigger=/d' $CONFIG
sudo sed -i '/^dtparam=pwr_led_activelow=/d' $CONFIG
echo -e "\ndtparam=act_led_trigger=none"       | sudo tee -a $CONFIG
echo "dtparam=act_led_activelow=on"           | sudo tee -a $CONFIG
echo "dtparam=pwr_led_trigger=none"           | sudo tee -a $CONFIG
echo "dtparam=pwr_led_activelow=on"           | sudo tee -a $CONFIG

echo "[install] Запуск сервисов..."
sudo systemctl start autobrightness.service
sudo systemctl start autobrightness-watcher.service

echo "[install] Установка завершена!"
echo "💡 Перезагрузите Raspberry Pi для отключения светодиодов и применения всех настроек:"
echo "  sudo reboot"

#!/bin/bash
set -e

# Если скрипт запущен без root — повторный запуск через sudo
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт через sudo:"
  echo "  curl -sSL https://raw.githubusercontent.com/exceptioncpp/rpi_autobrightness/main/install.sh | sudo bash"
  exit 1
fi

USER_HOME="/home/${SUDO_USER:-$USER}"
REPO_DIR="$USER_HOME/rpi_autobrightness"

# 1. Системные обновления и установка пакетов
apt update
apt install -y python3 python3-venv python3-pip git i2c-tools ddcutil inotify-tools build-essential python3-dev

# 2. Включение I2C
grep -qxF "dtparam=i2c_arm=on" /boot/config.txt || echo "dtparam=i2c_arm=on" >> /boot/config.txt

# 3. Клонирование репозитория
if [ ! -d "$REPO_DIR" ]; then
  sudo -u "$SUDO_USER" git clone https://github.com/exceptioncpp/rpi_autobrightness.git "$REPO_DIR"
else
  cd "$REPO_DIR"
  sudo -u "$SUDO_USER" git pull
fi
cd "$REPO_DIR"

# 4. Пользовательские группы
usermod -aG i2c,video "${SUDO_USER:-$USER}"

# 5. Установка виртуального окружения и Python-зависимостей
sudo -u "$SUDO_USER" python3 -m venv "$REPO_DIR/autobrightness-venv"
source "$REPO_DIR/autobrightness-venv/bin/activate"
pip install --upgrade pip
pip install adafruit-circuitpython-bh1750 adafruit-blinka

# 6. Настройка udev-правил для доступа к I2C и DDC
cat <<EOF > /etc/udev/rules.d/99-rpi_autobrightness.rules
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"
EOF
udevadm control --reload-rules
udevadm trigger

# 7. Отключение LED-индикаторов
sed -i '/^dtparam=act_led_trigger=/d' /boot/config.txt
sed -i '/^dtparam=pwr_led_trigger=/d' /boot/config.txt
cat <<EOF >> /boot/config.txt
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=on
EOF

# 8. Установка systemd-сервисов
cp systemd/autobrightness.service /etc/systemd/system/
cp systemd/autobrightness-watcher.service /etc/systemd/system/
chmod +x watch-autobrightness.sh

systemctl daemon-reload
systemctl enable autobrightness.service autobrightness-watcher.service
systemctl start autobrightness.service
systemctl start autobrightness-watcher.service

# 9. Разрешение перезапускать service без пароля
echo "${SUDO_USER:-$USER} ALL=NOPASSWD: /bin/systemctl restart autobrightness" > /etc/sudoers.d/rpi_autobrightness
chmod 440 /etc/sudoers.d/rpi_autobrightness

echo "✅ Установка завершена! Пожалуйста, выполните: sudo reboot"

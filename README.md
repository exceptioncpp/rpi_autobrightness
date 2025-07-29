# 💡 Raspberry Pi HDMI Auto-Brightness

Автоматическая регулировка яркости HDMI-дисплея на Raspberry Pi 3 Model B с использованием:

- BH1750 (датчик освещённости по I2C)
- `ddcutil` для управления яркостью монитора через DDC/CI
- Python + systemd для работы в фоновом режиме
- Поддержка автоматического применения изменений при редактировании

---

## 📦 Установка

```bash
git clone https://github.com/exceptioncpp/rpi_autobrightness.git
cd rpi_autobrightness
./install.sh
```

---

## 🔌 Подключение BH1750 к Raspberry Pi (40-pin GPIO)

- VCC → Pin 1 (3.3V)
- GND → Pin 6 (GND)
- SDA → Pin 3 (GPIO2 / SDA1)
- SCL → Pin 5 (GPIO3 / SCL1)

```
Raspberry Pi 3 B 40-pin GPIO Header
+-----+-----+----------+------+---+---Pi 3 B---+---+------+----------+-----+-----+
| BCM | wPi |   Name   | Mode | V | Physical  | V | Mode | Name     | wPi | BCM |
+-----+-----+----------+------+---+----++----+---+------+----------+-----+-----+
|     |     |    3.3V  |      |   |  1 || 2  |   |      | 5V       |     |     |
|   2 |  8  |  SDA1    | ALT0 | 1 |  3 || 4  |   |      | 5V       |     |     |
|   3 |  9  |  SCL1    | ALT0 | 1 |  5 || 6  | 0 |      | GND      |     |     |
|     ... (сокращено) ...
```

---

## ⚙️ Что делает скрипт

- Считывает данные освещённости (lux) каждые 5 секунд
- Вычисляет целевую яркость в % (по кривой)
- Плавно меняет яркость монитора шагами по 2% с заданной скоростью (по умолчанию каждые 200 мс)
- Поддерживает `systemd` сервис
- Есть скрипт наблюдения, автоматически перезапускающий сервис при изменении кода

---

## 🔐 Настройка прав доступа

- Добавление пользователя в группу `i2c`:
  ```bash
  sudo usermod -aG i2c $USER
  ```

- Добавление прав на `ddcutil`:
  ```bash
  echo 'pi ALL=NOPASSWD: /bin/systemctl restart autobrightness' | sudo tee /etc/sudoers.d/autobrightness
  sudo chmod 440 /etc/sudoers.d/autobrightness
  ```

- Отключение светодиодов:
  ```bash
  echo none | sudo tee /sys/class/leds/led0/trigger
  echo 0    | sudo tee /sys/class/leds/led1/brightness
  ```

---

## 🧪 Проверка

```bash
i2cdetect -y 1   # для Raspberry Pi, BH1750 обычно на 0x23
ddcutil detect   # проверка доступности монитора
journalctl -u autobrightness -f  # лог автоскрипта
```

---

## 📁 Структура

- `autobrightness.py` — основной скрипт
- `watch-autobrightness.sh` — наблюдение за изменениями
- `install.sh` — автоматическая установка окружения, зависимостей, systemd, прав и LED


# 📺 Автоматическая регулировка яркости монитора через DDC на Raspberry Pi

Система позволяет автоматически управлять яркостью монитора HDMI с помощью датчика освещённости BH1750, Raspberry Pi и протокола DDC/CI (через `ddcutil`). Подходит для систем без графического интерфейса (headless).

---

## 🔧 Аппаратные требования

- Raspberry Pi 3 Model B (или аналог с поддержкой I2C и DDC через HDMI)
- Датчик BH1750 (I2C)
- Подключение к HDMI-монитору с поддержкой DDC/CI

---

## 📌 Схема подключения BH1750

```text
 Raspberry Pi (40 pin)    BH1750
 --------------------    --------
 Pin 1  (3.3V)          → VCC
 Pin 3  (GPIO2 / SDA)   → SDA
 Pin 5  (GPIO3 / SCL)   → SCL
 Pin 6  (GND)           → GND
```

---

## 🚀 Установка

```bash
curl -sSL https://raw.githubusercontent.com/exceptioncpp/rpi_autobrightness/main/install.sh | bash
```

Скрипт автоматически:

- Включает I2C
- Устанавливает зависимости (`ddcutil`, `adafruit-circuitpython-bh1750`, `blinka`)
- Настраивает systemd-сервисы
- Настраивает доступ к DDC и I2C без `sudo`
- Отключает светодиоды (ACT, PWR)

---

## 🛠 Настройка вручную

### 1. Включение I2C

```bash
sudo raspi-config
# Интерфейсные параметры → I2C → Включить
```

### 2. Установка зависимостей

```bash
sudo apt update && sudo apt install -y git python3 python3-venv python3-pip i2c-tools ddcutil
```

### 3. Настройка проекта

```bash
git clone https://github.com/exceptioncpp/rpi_autobrightness.git
cd rpi_autobrightness
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Разрешения и доступ

```bash
sudo usermod -aG i2c $USER
sudo usermod -aG video $USER

echo 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"' | sudo tee /etc/udev/rules.d/99-i2c.rules
echo 'KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"' | sudo tee /etc/udev/rules.d/99-ddc.rules
sudo udevadm control --reload-rules
```

### 5. Отключение светодиодов

Добавить в `/boot/config.txt`:

```ini
# Отключение LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=on
```

---

## 🔄 Автоматический запуск

### Сервисы `systemd`

```bash
sudo cp autobrightness.service /etc/systemd/system/
sudo cp autobrightness-watcher.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable autobrightness.service autobrightness-watcher.service
sudo systemctl start autobrightness.service autobrightness-watcher.service
```

---

## 🧪 Тестирование

```bash
journalctl -u autobrightness.service -f
```

Ожидаемый вывод:
```
Lux: 15.4 → Target: 21.2% → Smoothed: 20% → Step to: 22%
```

---

## 📄 Файлы проекта

- `autobrightness.py` — основной скрипт (датчик + управление яркостью)
- `watch-autobrightness.sh` — следит за изменениями скрипта
- `autobrightness.service` — `systemd`-сервис
- `autobrightness-watcher.service` — `systemd`-сервис для перезапуска

---

## 📦 Автообновление

Любое изменение файла `autobrightness.py` автоматически перезапускает службу `autobrightness`.

---


### 📌 Схема подключения (Raspberry Pi 3 Model B, 40-pin GPIO)

```plaintext
+-----+-----+---------+------+---+---Pi 3 B+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
|     |     |    3.3V |      |   |  1 || 2  |   |      | 5V      |     |     |
|   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5V      |     |     |
|   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | GND     |     |     |
|     |     |   GPIO  |      |   |  . || .  |   |      |         |     |     |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
```

🧩 **Подключение BH1750:**

| BH1750 Pin | Назначение         | Подключить к Raspberry Pi |
|------------|--------------------|----------------------------|
| VCC        | Питание            | Pin 1 (3.3V)               |
| GND        | Земля              | Pin 6 (GND)                |
| SDA        | I2C — данные       | Pin 3 (GPIO2 / SDA)        |
| SCL        | I2C — тактирование | Pin 5 (GPIO3 / SCL)        |
| ADDR       | (необязателен)     | Оставить неподключённым    |

## 📚 Благодарности

- [Adafruit CircuitPython BH1750](https://github.com/adafruit/Adafruit_CircuitPython_BH1750)
- [ddcutil](https://www.ddcutil.com/)
- [smbus2](https://pypi.org/project/smbus2/)

---


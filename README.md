# 🔆 rpi_autobrightness

Автоматическая регулировка яркости монитора HDMI на Raspberry Pi 3 B на основе освещенности с использованием BH1750 и `ddcutil`.

## 🚀 Установка

```bash
curl -sSL https://raw.githubusercontent.com/exceptioncpp/rpi_autobrightness/main/install.sh | bash
```

## 📁 Содержимое

- `autobrightness.py` — основной скрипт автояркости
- `watch-autobrightness.sh` — автоперезапуск при изменении скрипта
- `systemd/autobrightness.service` — systemd unit для основного сервиса
- `systemd/autobrightness-watcher.service` — systemd unit для inotify watcher

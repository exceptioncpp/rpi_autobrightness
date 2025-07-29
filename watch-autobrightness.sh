#!/bin/bash
SCRIPT=~/rpi_autobrightness/autobrightness.py
while true; do
  inotifywait -e modify "$SCRIPT"
  echo "[watcher] Изменение обнаружено, перезапуск autobrightness..."
  sudo systemctl restart autobrightness
  sleep 1
done

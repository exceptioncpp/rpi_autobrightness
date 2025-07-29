#!/usr/bin/env python3
import time
import subprocess
import board
import adafruit_bh1750
import bisect
import math

# --- Настройки ---
MEASURE_INTERVAL = 1       # сек, как часто измерять lux и пересчитывать целевую яркость
ADJUST_DELAY_MS = 100       # задержка между шагами изменения яркости (мс)
EMA_ALPHA = 0.3             # коэффициент сглаживания lux

# Таблица соответствия lux → яркость монитора (%)
LUX_BRIGHTNESS_TABLE = [
    (0,    0),
    (1,    10),
    (2,    15),
    (3,    20),
    (50,   30),
    (400,  75),
    (600,  85),
    (800, 100),
]

# --- Инициализация датчика и переменных ---
i2c = board.I2C()
sensor = adafruit_bh1750.BH1750(i2c)

smoothed_lux = None
target_brightness = None
current_brightness = None
last_measurement_time = 0
last_adjust_time = time.monotonic()
adjust_interval = ADJUST_DELAY_MS / 1000.0


def interpolate_brightness(lux):
    """Логарифмическая интерполяция lux → яркость (%)"""
    lux_values = [pt[0] for pt in LUX_BRIGHTNESS_TABLE]
    bright_values = [pt[1] for pt in LUX_BRIGHTNESS_TABLE]

    if lux <= lux_values[0]:
        return bright_values[0]
    if lux >= lux_values[-1]:
        return bright_values[-1]

    idx = bisect.bisect_right(lux_values, lux)
    l1, l2 = lux_values[idx - 1], lux_values[idx]
    b1, b2 = bright_values[idx - 1], bright_values[idx]

    ratio = (math.log10(lux) - math.log10(l1)) / (math.log10(l2) - math.log10(l1))
    return b1 + ratio * (b2 - b1)


def set_brightness(value):
    subprocess.run(['ddcutil', '--bus=2', 'setvcp', '10', str(int(value)), '--sleep-multiplier=0.1'], check=False)
    #subprocess.run(['ddcutil', 'setvcp', '10', str(int(value))], check=False)


# --- Основной цикл ---
while True:
    now = time.time()

    # --- Обновление lux и целевой яркости ---
    if now - last_measurement_time >= MEASURE_INTERVAL:
        try:
            raw_lux = sensor.lux
            if smoothed_lux is None:
                smoothed_lux = raw_lux
            else:
                smoothed_lux = EMA_ALPHA * raw_lux + (1 - EMA_ALPHA) * smoothed_lux

            target_brightness = round(interpolate_brightness(smoothed_lux))
            last_measurement_time = now

            print(f"Lux: {raw_lux:.1f} → Smoothed: {smoothed_lux:.1f} → Target: {target_brightness}%")
        except Exception as e:
            print(f"[Ошибка чтения lux]: {e}")

    # --- Плавное приближение яркости ---
    if target_brightness is not None:
        if current_brightness is None:
            current_brightness = target_brightness
            set_brightness(current_brightness)
            print(f"[init] Brightness set to {current_brightness}%")
        elif current_brightness < target_brightness:
            current_brightness += 1
            set_brightness(current_brightness)
            print(f"[up] → {current_brightness}%")
        elif current_brightness > target_brightness:
            current_brightness -= 1
            set_brightness(current_brightness)
            print(f"[down] → {current_brightness}%")

    # --- Точное ожидание с учётом времени ddcutil ---
    now_adjust = time.monotonic()
    elapsed = now_adjust - last_adjust_time
    remaining = adjust_interval - elapsed
    if remaining > 0:
        time.sleep(remaining)
    last_adjust_time = time.monotonic()

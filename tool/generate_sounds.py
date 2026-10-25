"""Original Ghost Runner sound design. Python standard library only.

Run from anywhere with: python tool/generate_sounds.py
All rendered samples are original procedural synthesis, dedicated to CC0.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
TAU = math.tau


def bell(t, frequency, duration, decay=7):
    if t < 0 or t >= duration:
        return 0.0
    attack = min(1.0, t / .006)
    release = min(1.0, (duration - t) / .035)
    return attack * release * math.exp(-decay * t) * (
        math.sin(TAU * frequency * t)
        + .22 * math.sin(TAU * frequency * 2.003 * t)
        + .07 * math.sin(TAU * frequency * 3.997 * t))


def render(name, duration, sample):
    data = [sample(i / RATE) for i in range(round(duration * RATE))]
    peak = max(abs(x) for x in data) or 1
    # Balanced, quiet source level plus short fades prevents clicks/clipping.
    frames = bytearray()
    for i, value in enumerate(data):
        edge = min(1, i / (RATE * .004), (len(data) - 1 - i) / (RATE * .012))
        frames += struct.pack('<h', round(32767 * .55 * value / peak * edge))
    with wave.open(str(OUT / name), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(frames)


render('candy_pop.wav', .18, lambda t:
       math.sin(TAU * (850 * t - 1650 * t * t)) * math.exp(-30 * t)
       + .16 * bell(t - .025, 1318.51, .13, 24))
render('chocolate_ding.wav', .36, lambda t:
       bell(t, 783.99, .36, 9) + .18 * bell(t, 1174.66, .36, 12))
render('golden_chime.wav', .70, lambda t: sum(
       .8 ** n * bell(t - n * .075, f, .70 - n * .075, 8)
       for n, f in enumerate([1046.50, 1318.51, 1567.98, 2093.00])))
render('ghost_boing.wav', .30, lambda t:
       math.sin(TAU * (210 * t + 150 * t * t
                      + 5 * (1 - math.cos(TAU * 11 * t))))
       * math.exp(-10 * t))
render('ghost_boo.wav', .72, lambda t:
       (math.sin(TAU * (380 * t - 165 * t * t + .6 * math.sin(TAU * 5 * t)))
        + .20 * math.sin(TAU * (760 * t - 330 * t * t)))
       * math.sin(math.pi * t / .72) ** 2 * math.exp(-2.2 * t))
rng = random.Random(1031)
noise = [rng.uniform(-1, 1) for _ in range(round(.4 * RATE))]
# Low-pass the air puff so it is soft rather than a harsh hiss.
for i in range(1, len(noise)):
    noise[i] = .85 * noise[i - 1] + .15 * noise[i]
render('shield_poof.wav', .40, lambda t:
       1.6 * noise[min(len(noise) - 1, int(t * RATE))] * math.exp(-13 * t)
       + .32 * bell(t - .025, 987.77, .36, 11)
       + .18 * bell(t - .07, 1479.98, .30, 12))
render('milestone_jingle.wav', .90, lambda t: sum(
       .75 * bell(t - n * .13, f, .90 - n * .13, 6)
       for n, f in enumerate([523.25, 659.25, 783.99, 1046.50]))
       + .15 * bell(t - .39, 1318.51, .51, 7))
print('Generated seven original, mono 22.05 kHz / 16-bit WAV effects.')

"""Extract a repeatable tempo grid from the bundled MP3 (numpy + ffmpeg)."""
import json
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE, HOP, WINDOW = 22050, 256, 1024
audio = np.frombuffer(subprocess.check_output([
    "ffmpeg", "-v", "error", "-i", str(ROOT / "assets/music/bumba-crossing.mp3"),
    "-f", "f32le", "-ac", "1", "-ar", str(RATE), "pipe:1",
]), dtype="<f4")
frames = np.lib.stride_tricks.sliding_window_view(audio, WINDOW)[::HOP]
spectrum = np.abs(np.fft.rfft(frames * np.hanning(WINDOW), axis=1))
# Percussion transients: compress magnitudes so a loud melodic note cannot dominate.
flux = np.maximum(0, np.diff(np.log1p(spectrum * 10), axis=0)).sum(axis=1)
flux = np.concatenate(([0.0], flux))
flux = np.maximum(0, flux - np.convolve(flux, np.ones(85) / 85, mode="same"))
times = (np.arange(len(flux)) * HOP + WINDOW / 2) / RATE
mask = (times > 8) & (times < len(audio) / RATE - 8)
envelope = flux[mask]
size = 1 << (2 * len(envelope) - 1).bit_length()
ac = np.fft.irfft(np.abs(np.fft.rfft(envelope, size)) ** 2, size)[:len(envelope)]
lags = np.arange(round(RATE / HOP * 60 / 150), round(RATE / HOP * 60 / 80))
order = lags[np.argsort(ac[lags])[-8:][::-1]]
print("Tempo candidates:", [(round(60 * RATE / HOP / lag, 2), round(float(ac[lag]), 1)) for lag in order])
# Refine both period and phase against the full track, avoiding accumulated drift.
# This percussion arrangement has a strong triplet subdivision near 123 BPM.
# Use the slower quarter-note candidate near 92 BPM for playable beat windows.
quarter = min(order, key=lambda lag: abs(60 * RATE / HOP / lag - 92))
rough = float(quarter * HOP / RATE)
best = (-1.0, 0.0, 0.0)
for period in np.linspace(rough - 0.014, rough + 0.014, 561):
    phases = np.remainder(times[mask], period)
    bins = np.floor(phases / period * 120).astype(int)
    energy = np.bincount(bins, weights=envelope, minlength=120)
    smooth = sum(np.roll(energy, offset) for offset in [-2, -1, 0, 1, 2])
    index = int(np.argmax(smooth))
    if smooth[index] > best[0]:
        best = (float(smooth[index]), float(period), (index + 0.5) / 120 * period)
_, period, offset = best
result = {
    "track": "bumba-crossing.mp3", "bpm": round(60 / period, 6),
    "beat_offset": round(offset, 6), "duration": round(len(audio) / RATE, 6),
    "method": "Whole-track percussion onset grid, refined tempo and phase",
}
(ROOT / "assets/music/beat_grid.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps(result, indent=2))

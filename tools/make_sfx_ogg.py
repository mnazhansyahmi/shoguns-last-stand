"""Cuts the original Sonniss / Pixabay recordings down to the short, loudness-matched .ogg files the game plays.

The originals are large (a 36 MB wav, a 65 second zombie recording) and are NOT kept in the project. To rebuild
the .ogg files, put the originals in one folder and run:

    python tools/make_sfx_ogg.py --src <folder with the originals> --out assets/audio

Every file is cut to the part the game uses, faded out, resampled to at most 44.1 kHz, scaled so its loud part sits
at a common level (TARGET_RMS_DB, peaks held below PEAK_LIMIT_DB) and written as Vorbis. The two eerie beds are
cross-faded into themselves so they loop without a click. Needs numpy, scipy and soundfile.
"""
import argparse
import os

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

TARGET_RMS_DB = -20.0
PEAK_LIMIT_DB = -1.0
MAX_RATE = 44100
QUALITY = 0.4

# (original file, output path below --out, start s, end s, fade-out s, mono, target rms dB)
CUTS = [
    ("GRWL ROAR ANGRY.wav", "sfx_sonniss/roar.ogg", 0.04, 2.45, 0.30, True, TARGET_RMS_DB),
    ("Bluezone_BC0294_modern_cinematic_impact_boom_003.wav", "sfx_sonniss/slam_1.ogg", 0.0, 2.6, 0.60, True, TARGET_RMS_DB),
    ("Bluezone_BC0294_modern_cinematic_impact_022.wav", "sfx_sonniss/slam_2.ogg", 0.0, 2.4, 0.60, True, TARGET_RMS_DB),
    ("Bluezone_BC0297_stone_impact_015.wav", "sfx_sonniss/stone_1.ogg", 0.0, 1.30, 0.25, True, TARGET_RMS_DB),
    ("Bluezone_BC0297_stone_impact_041.wav", "sfx_sonniss/stone_2.ogg", 0.0, 1.50, 0.30, True, TARGET_RMS_DB),
    ("EXPLReal_Medium Realistic Explosion 15_DDUMAIS_NONE.wav", "sfx_sonniss/explosion.ogg", 0.0, 2.10, 0.40, True, TARGET_RMS_DB),
    ("WOODCrsh_Designed Wood Crash And Debris 13_DDUMAIS_NONE.wav", "sfx_sonniss/gate_destroyed.ogg", 0.0, 1.10, 0.25, True, TARGET_RMS_DB),
    ("DSGN VORTEX IN.wav", "sfx_sonniss/boss_summon.ogg", 0.0, 3.20, 0.40, True, TARGET_RMS_DB),
    ("WHOOSH PASS SF LOW.wav", "sfx_sonniss/whoosh.ogg", 0.45, 1.85, 0.25, True, TARGET_RMS_DB),
    ("Short_PowerUp_005.wav", "sfx_sonniss/ultimate_ready.ogg", 0.25, 2.40, 0.40, True, TARGET_RMS_DB),
    ("zombie1.mp3", "sfx_gore/zombie_groan_1.ogg", 0.26, 2.20, 0.25, True, TARGET_RMS_DB),
    ("zombie1.mp3", "sfx_gore/zombie_groan_2.ogg", 2.95, 4.90, 0.25, True, TARGET_RMS_DB),
    ("zombie2.mp3", "sfx_gore/zombie_groan_3.ogg", 0.41, 2.39, 0.25, True, TARGET_RMS_DB),
    ("zombie2.mp3", "sfx_gore/zombie_groan_4.ogg", 4.79, 6.67, 0.25, True, TARGET_RMS_DB),
    ("zombie3.mp3", "sfx_gore/zombie_groan_5.ogg", 1.38, 3.50, 0.25, True, TARGET_RMS_DB),
    ("zombie3.mp3", "sfx_gore/zombie_groan_6.ogg", 8.29, 10.31, 0.25, True, TARGET_RMS_DB),
]

# (original file, output path, start s, loop length s, cross-fade s, target rms dB): quiet looping beds.
LOOPS = [
    ("DSGNErie_Eerie02_InMotionAudio_SinisterTexturesVolume2.wav", "sfx_sonniss/eerie_1.ogg", 4.0, 26.0, 3.0, -24.0),
    ("DSGNErie_Eerie06_InMotionAudio_SinisterTexturesVolume2.wav", "sfx_sonniss/eerie_2.ogg", 4.0, 26.0, 3.0, -24.0),
]


def load(path):
    data, rate = sf.read(path, always_2d=True, dtype="float64")
    return data, rate


def resample(data, rate):
    if rate <= MAX_RATE:
        return data, rate
    g = np.gcd(rate, MAX_RATE)
    return resample_poly(data, MAX_RATE // g, rate // g, axis=0), MAX_RATE


def normalise(data, target_db):
    """Scales so the loud part (everything within 40 dB of the peak) averages target_db, peaks held under the limit."""
    peak = np.abs(data).max()
    loud = data[np.abs(data).max(axis=1) > peak * 10 ** (-40 / 20)]
    rms = np.sqrt((loud ** 2).mean())
    gain = 10 ** (target_db / 20) / max(rms, 1e-9)
    gain = min(gain, 10 ** (PEAK_LIMIT_DB / 20) / max(peak, 1e-9))
    return data * gain


def write(path, data, rate):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with sf.SoundFile(path, "w", samplerate=rate, channels=data.shape[1], format="OGG", subtype="VORBIS",
                      compression_level=QUALITY) as f:
        data = data.astype(np.float32)
        for i in range(0, len(data), 8192):  # one big write overflows libsndfile's stack
            f.write(data[i:i + 8192])
    print("%-48s %5.2f s %d ch %6.1f kB" % (os.path.basename(path), len(data) / rate, data.shape[1], os.path.getsize(path) / 1024))


def cut(src, out, start, end, fade, mono, target):
    data, rate = load(src)
    data = data[int(start * rate):int(end * rate)]
    if mono:
        data = data.mean(axis=1, keepdims=True)
    data, rate = resample(data, rate)
    n_in = min(int(0.01 * rate), len(data))
    data[:n_in] *= np.linspace(0.0, 1.0, n_in)[:, None]
    n_out = min(int(fade * rate), len(data))
    data[-n_out:] *= (np.cos(np.linspace(0.0, np.pi / 2, n_out)) ** 2)[:, None]
    write(out, normalise(data, target), rate)


def loop(src, out, start, length, cross, target):
    # Reads only the window it needs: the originals are minutes of 96 kHz stereo.
    rate = sf.info(src).samplerate
    data, rate = sf.read(src, start=int(start * rate), frames=int((length + cross) * rate), always_2d=True, dtype="float64")
    seg, rate = resample(data, rate)
    n = int(length * rate)
    c = int(cross * rate)
    t = np.linspace(0.0, np.pi / 2, c)[:, None]
    head = seg[:c] * np.sin(t) + seg[n:n + c] * np.cos(t)
    result = np.concatenate([head, seg[c:n]])
    write(out, normalise(result, target), rate)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True)
    parser.add_argument("--out", default="assets/audio")
    args = parser.parse_args()
    for name, out, start, end, fade, mono, target in CUTS:
        cut(os.path.join(args.src, name), os.path.join(args.out, out), start, end, fade, mono, target)
    for name, out, start, length, cross, target in LOOPS:
        loop(os.path.join(args.src, name), os.path.join(args.out, out), start, length, cross, target)


if __name__ == "__main__":
    main()

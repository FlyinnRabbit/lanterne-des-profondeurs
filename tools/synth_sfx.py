# Bruitages supplémentaires générés par synthèse (aucun échantillon externe).
# python3 tools/synth_sfx.py -> sfx/whip.wav, hammer.wav, star.wav, star_hit.wav, crit.wav, crit_ready.wav, achievement.wav
import numpy as np, wave, os
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sfx")
rng = np.random.default_rng(7)

def env(n, a=0.005, d=1.0, curve=4.0):
    t = np.linspace(0, 1, n)
    e = np.exp(-curve * t) * d
    att = int(a * SR)
    if att > 0:
        e[:att] *= np.linspace(0, 1, att)
    return e

def write(name, x):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * 0.85, -1, 1)
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

def noise(n):
    return rng.uniform(-1, 1, n)

def bandpass(x, lo, hi):
    f = np.fft.rfft(x); fr = np.fft.rfftfreq(len(x), 1 / SR)
    f[(fr < lo) | (fr > hi)] = 0
    return np.fft.irfft(f, len(x))

# fouet : sifflement montant puis claquement sec
n = int(0.28 * SR); t = np.arange(n) / SR
swish = bandpass(noise(n), 2000, 7000) * np.sin(np.pi * np.clip(t / 0.2, 0, 1)) * 0.6
crack = np.zeros(n); c0 = int(0.19 * SR); cl = int(0.03 * SR)
crack[c0:c0 + cl] = noise(cl) * env(cl, 0, 1, 9)
write("whip", swish + crack * 1.4)

# marteau : choc grave + résonance métallique
n = int(0.5 * SR); t = np.arange(n) / SR
thud = np.sin(2 * np.pi * (90 - 40 * t) * t) * env(n, 0.002, 1, 7)
ring = (np.sin(2 * np.pi * 620 * t) + 0.6 * np.sin(2 * np.pi * 1340 * t)) * env(n, 0.001, 0.35, 6)
write("hammer", thud + ring + bandpass(noise(n), 100, 900) * env(n, 0, 0.5, 18))

# étoile lancée : sifflement aigu court
n = int(0.16 * SR); t = np.arange(n) / SR
write("star", bandpass(noise(n), 4000, 10000) * np.sin(np.pi * t / t[-1]) + 0.2 * np.sin(2 * np.pi * (2400 + 3000 * t) * t) * env(n, 0.002, 1, 5))

# étoile qui touche : tintement
n = int(0.18 * SR); t = np.arange(n) / SR
write("star_hit", (np.sin(2 * np.pi * 2900 * t) + 0.5 * np.sin(2 * np.pi * 4350 * t)) * env(n, 0.001, 1, 10) + noise(n) * env(n, 0, 0.3, 40))

# coup critique : impact lourd + éclat brillant
n = int(0.42 * SR); t = np.arange(n) / SR
boom = np.sin(2 * np.pi * (140 - 80 * t) * t) * env(n, 0.001, 1, 8)
spark = sum(np.sin(2 * np.pi * f * t) for f in (1760, 2217, 2637)) * env(n, 0.001, 0.4, 7)
write("crit", boom + spark + bandpass(noise(n), 1500, 6000) * env(n, 0, 0.6, 20))

# critique prêt (parade parfaite) : carillon montant
n = int(0.5 * SR); t = np.arange(n) / SR
x = np.zeros(n)
for i, f in enumerate((1047, 1319, 1568, 2093)):
    s0 = int(i * 0.06 * SR); m = n - s0
    tt = np.arange(m) / SR
    x[s0:] += np.sin(2 * np.pi * f * tt) * env(m, 0.002, 1, 6)
write("crit_ready", x)

# succès : petite fanfare
n = int(0.7 * SR); x = np.zeros(n)
for i, f in enumerate((784, 988, 1175, 1568)):
    s0 = int(i * 0.09 * SR); m = n - s0
    tt = np.arange(m) / SR
    x[s0:] += (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt)) * env(m, 0.003, 1, 4)
write("achievement", x)
print("ok")

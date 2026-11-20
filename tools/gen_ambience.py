#!/usr/bin/env python3
"""Ambiances sonores par biome et bruits de pas, synthétisés (aucun enregistrement).
Sorties : sfx/amb_<biome>.ogg (boucles de 16 s, sans couture) et sfx/step_<matière><n>.wav.
Usage : python3 tools/gen_ambience.py   (nécessite numpy et ffmpeg)"""
import numpy as np, subprocess, os, wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "sfx")
rng = np.random.default_rng(7)

def lowpass(x, a):            # filtre passe-bas d'ordre 1 (a : 0..1, petit = plus sourd)
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y

def lp(x, cutoff):
    # passe-bas rapide par FFT
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1.0 / (1.0 + (f / cutoff) ** 4)
    return np.fft.irfft(X, len(x))

def bp(x, lo, hi):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= (1.0 / (1.0 + (f / hi) ** 4)) * (1.0 / (1.0 + (lo / np.maximum(f, 1)) ** 4))
    return np.fft.irfft(X, len(x))

def noise(n):
    return rng.standard_normal(n)

def env_ad(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-np.maximum(t - a, 0) / d)

def place(buf, ev, pos):
    pos %= len(buf)
    end = min(len(buf), pos + len(ev))
    buf[pos:end] += ev[:end - pos]
    rest = len(ev) - (end - pos)
    if rest > 0:                       # déborde : on revient au début (boucle sans couture)
        buf[:rest] += ev[end - pos:]

def drip(freq=None):
    n = int(SR * 0.35)
    t = np.arange(n) / SR
    f0 = freq or rng.uniform(900, 1700)
    f = f0 * (1 + 0.6 * np.exp(-t * 40))   # « ploc » qui glisse vers le grave
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(n, 0.002, 0.06)
    return s

def echo(x, delay, fb, n=4):
    y = x.copy(); d = int(delay * SR)
    for k in range(1, n + 1):
        y[d * k:] += x[:-d * k] * fb ** k if d * k < len(x) else 0
    return y

def chime(freq):
    n = int(SR * 2.5); t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * freq * m * t) * (0.6 / m) for m in (1, 2.76, 5.4))
    return s * env_ad(n, 0.003, 0.7)

def click(n=600, cut=3000):
    return lp(noise(n), cut) * env_ad(n, 0.0005, 0.01)

def wind(n, base=400, var=0.6, speed=0.08):
    w = bp(noise(n), base * 0.5, base * 2.0)
    t = np.arange(n) / SR
    mod = 0.55 + var * 0.5 * np.sin(2 * np.pi * speed * t + 1.3) + 0.2 * np.sin(2 * np.pi * speed * 2.7 * t)
    return w * np.clip(mod, 0.05, 1.2)

def hum(n, f, amt=1.0):
    t = np.arange(n) / SR
    return amt * (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.5 * t + 0.4)) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.07 * t))

def loopify(x, fade=1.5):
    # fondu enchaîné fin → début : la boucle ne s'entend pas
    f = int(fade * SR)
    head = x[:f].copy(); tail = x[-f:].copy()
    w = np.linspace(0, 1, f)
    x = x[:-f].copy()
    x[:f] = head * w + tail * (1 - w)
    return x

def norm(x, peak):
    return x / (np.max(np.abs(x)) + 1e-9) * peak

def write_wav(path, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

def write_ogg(name, x):
    tmp = "/tmp/_amb.wav"
    write_wav(tmp, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, name)], check=True)

L = 17.5   # secondes avant bouclage (16 s de boucle)
N = int(L * SR)

def events(buf, maker, count, gain):
    for _ in range(count):
        place(buf, maker() * gain, int(rng.uniform(0, len(buf))))

def biome(name):
    b = np.zeros(N)
    if name == "profondeurs":
        b += lp(noise(N), 120) * 1.2 + hum(N, 55, 0.25)
        d = np.zeros(N); events(d, drip, 14, 0.5); b += echo(d, 0.23, 0.45)
    elif name == "jardins":
        b += lp(noise(N), 300) * 0.5 + wind(N, 900, 0.4, 0.05) * 0.25
        events(b, lambda: lp(noise(int(SR * 0.08)), 800) * env_ad(int(SR * 0.08), 0.005, 0.03), 40, 0.25)   # bulles de spores
        d = np.zeros(N); events(d, drip, 6, 0.3); b += echo(d, 0.18, 0.4)
    elif name == "jungle":
        rain = bp(noise(N), 1500, 7000) * 0.35
        t = np.arange(N) / SR
        insects = np.sin(2 * np.pi * 4200 * t) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 23 * t))) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.3 * t)) * 0.05
        b += rain + insects + lp(noise(N), 200) * 0.6
        events(b, drip, 25, 0.25)
    elif name == "glace":
        b += wind(N, 500, 0.9, 0.06) * 1.0 + wind(N, 1600, 0.7, 0.11) * 0.3
        events(b, lambda: lp(noise(int(SR * 0.4)), 900) * env_ad(int(SR * 0.4), 0.05, 0.15), 5, 0.6)   # craquements de glace
    elif name == "cristal":
        b += hum(N, 110, 0.3) + lp(noise(N), 150) * 0.4
        c = np.zeros(N)
        for _ in range(10):
            place(c, chime(rng.choice([1046, 1318, 1567, 1760, 2093])) * 0.35, int(rng.uniform(0, N)))
        b += echo(c, 0.31, 0.5)
    elif name == "forge":
        b += lp(noise(N), 90) * 2.0 + hum(N, 40, 0.4)
        events(b, lambda: click(800, 5000), 120, 0.35)   # crépitements de braises
        clank = lambda: (np.sin(2 * np.pi * 620 * np.arange(int(SR * 0.6)) / SR) + 0.6 * np.sin(2 * np.pi * 1490 * np.arange(int(SR * 0.6)) / SR)) * env_ad(int(SR * 0.6), 0.001, 0.12)
        e = np.zeros(N); events(e, clank, 3, 0.25); b += echo(e, 0.35, 0.4)
    elif name == "ruche":
        t = np.arange(N) / SR
        buzz = np.zeros(N)
        for f in (190, 213, 247):
            ph = 2 * np.pi * f * t + 3.0 * np.sin(2 * np.pi * rng.uniform(0.1, 0.3) * t)
            buzz += np.sign(np.sin(ph)) * 0.3
        b += lp(buzz, 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.09 * t)) * 0.5 + lp(noise(N), 250) * 0.4
    elif name == "ossuaire":
        b += wind(N, 300, 1.0, 0.05) * 0.9 + lp(noise(N), 100) * 0.6
        def rattle():
            ev = np.zeros(int(SR * 0.5))
            for k in range(rng.integers(3, 7)):
                place(ev, click(400, 2500), int(k * SR * 0.04 + rng.uniform(0, 400)))
            return ev
        e = np.zeros(N); events(e, rattle, 6, 0.4); b += echo(e, 0.25, 0.35)
    elif name == "desert":
        b += wind(N, 700, 1.0, 0.07) * 0.9 + bp(noise(N), 3000, 8000) * 0.12 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.13 * np.arange(N) / SR))
    elif name == "antique":
        b += lp(noise(N), 140) * 0.8 + hum(N, 73, 0.15)
        d = np.zeros(N); events(d, lambda: drip(rng.uniform(600, 1000)), 8, 0.4); b += echo(d, 0.4, 0.55, 6)
        events(b, lambda: lp(noise(int(SR * 1.2)), 200) * env_ad(int(SR * 1.2), 0.3, 0.4), 2, 0.5)   # pierre qui frotte
    elif name == "citadelle":
        t = np.arange(N) / SR
        water = lp(noise(N), 500) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.25 * t) ** 2)
        b += water * 1.0 + lp(noise(N), 120) * 0.5
        bell = lambda: sum(np.sin(2 * np.pi * 220 * m * np.arange(int(SR * 4)) / SR) * (0.5 / m) for m in (1, 2.0, 2.4, 3.0)) * env_ad(int(SR * 4), 0.005, 1.4)
        e = np.zeros(N); events(e, bell, 1, 0.25); b += echo(e, 0.5, 0.4)
    elif name == "bibliotheque":
        b += lp(noise(N), 180) * 0.35
        flutter = lambda: bp(noise(int(SR * 0.3)), 1500, 5000) * env_ad(int(SR * 0.3), 0.02, 0.08)
        events(b, flutter, 7, 0.35)
        tick = np.zeros(N)
        for k in range(int(L)):
            place(tick, click(300, 4000) * (0.25 if k % 2 else 0.18), int(k * SR))
        b += tick
    elif name == "hub":
        b += lp(noise(N), 160) * 0.5 + hum(N, 65, 0.1)
        events(b, lambda: click(700, 4000), 60, 0.2)   # feu qui crépite
        d = np.zeros(N); events(d, drip, 4, 0.25); b += echo(d, 0.2, 0.4)
    return norm(loopify(b), 0.5)

def step(kind, k):
    n = int(SR * 0.09)
    x = noise(n)
    if kind == "stone":
        s = bp(x, 300, 2500) * env_ad(n, 0.001, 0.025)
    elif kind == "grass":
        s = bp(x, 1500, 7000) * env_ad(n, 0.004, 0.035) * 0.7
    elif kind == "snow":
        s = bp(x, 600, 3500) * env_ad(n, 0.01, 0.04)
        s *= (rng.random(n) > 0.4)
    elif kind == "sand":
        s = bp(x, 2000, 9000) * env_ad(n, 0.006, 0.03) * 0.6
    elif kind == "wood":
        t = np.arange(n) / SR
        s = (np.sin(2 * np.pi * (180 + 40 * k) * t) * 0.8 + bp(x, 400, 2000) * 0.5) * env_ad(n, 0.001, 0.03)
    elif kind == "crystal":
        t = np.arange(n * 3) / SR
        s = bp(noise(n * 3), 500, 3000) * env_ad(n * 3, 0.001, 0.02) + np.sin(2 * np.pi * (2400 + 300 * k) * t) * env_ad(n * 3, 0.001, 0.08) * 0.25
    else:  # wax / mud
        s = lp(x, 900) * env_ad(n, 0.004, 0.035)
    return norm(s, 0.7)

if __name__ == "__main__":
    for nm in ["profondeurs", "jardins", "jungle", "glace", "cristal", "forge", "ruche", "ossuaire", "desert", "antique", "citadelle", "bibliotheque", "hub"]:
        write_ogg("amb_%s.ogg" % nm, biome(nm))
        print("amb", nm)
    for kind in ["stone", "grass", "snow", "sand", "wood", "crystal", "soft"]:
        for k in range(3):
            write_wav(os.path.join(OUT, "step_%s%d.wav" % (kind, k)), step(kind, k))
    print("pas ok")

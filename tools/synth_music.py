# Compositeur/synthétiseur procédural : produit des musiques originales en boucle (.ogg)
import numpy as np, subprocess, os, sys
from scipy.signal import lfilter, fftconvolve, butter

SR = 44100
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

def mtof(m): return 440.0 * 2 ** ((m - 69) / 12)
SCALES = {
    "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "harm": [0, 2, 3, 5, 7, 8, 11], "phryg": [0, 1, 3, 5, 7, 8, 10], "major": [0, 2, 4, 5, 7, 9, 11],
}
def deg(root, scale, d):
    s = SCALES[scale]; o, i = divmod(d, 7)
    return root + 12 * o + s[i]
def chord(root, scale, d, n=3):
    return [deg(root, scale, d + 2 * k) for k in range(n)]

def env(n, a, r, sustain=True):
    e = np.ones(n)
    na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)[:n] if na <= n else np.linspace(0, 1, n)
    if nr < n:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e

def lowpass(x, fc):
    b, a = butter(2, min(fc / (SR / 2), 0.99), "low"); return lfilter(b, a, x)
def highpass(x, fc):
    b, a = butter(2, fc / (SR / 2), "high"); return lfilter(b, a, x)
def bandpass(x, lo, hi):
    b, a = butter(2, [lo / (SR / 2), hi / (SR / 2)], "band"); return lfilter(b, a, x)

# ---------------- instruments (mono) ----------------
def piano(f, dur, vel):
    n = int((dur + 1.5) * SR); t = np.arange(n) / SR
    w = sum((0.6 ** k) * np.sin(2 * np.pi * f * (k + 1) * t * (1 + 0.0004 * k)) * np.exp(-t * (1.6 + 1.2 * k)) for k in range(5))
    w *= np.minimum(1, t / 0.004)
    w[int(dur * SR):] *= np.linspace(1, 0, n - int(dur * SR)) ** 2
    return w * vel * 0.5

def musicbox(f, dur, vel):
    n = int(2.5 * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) * np.exp(-t * 2.2) + 0.35 * np.sin(2 * np.pi * f * 4.07 * t) * np.exp(-t * 6) + 0.15 * np.sin(2 * np.pi * f * 6.8 * t) * np.exp(-t * 9)
    return w * np.minimum(1, t / 0.002) * vel * 0.45

def bell(f, dur, vel):
    n = int(4 * SR); t = np.arange(n) / SR
    parts = [(1, 1, 0.9), (2.76, 0.5, 2.2), (5.4, 0.25, 3.5), (0.5, 0.35, 0.7), (8.93, 0.1, 5)]
    w = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * d) for r, a, d in parts)
    return w * np.minimum(1, t / 0.003) * vel * 0.3

def pluck(f, dur, vel, bright=0.5):
    N = max(2, int(SR / f)); n = int((dur + 1.2) * SR)
    x = np.zeros(n); burst = np.random.uniform(-1, 1, N)
    burst = lowpass(burst, 2000 + 6000 * bright); x[:N] = burst
    d = 0.996
    a = np.zeros(N + 2); a[0] = 1; a[N] = -d * 0.5; a[N + 1] = -d * 0.5
    y = lfilter([1], a, x)
    y[int(dur * SR):] *= np.linspace(1, 0, n - int(dur * SR))
    return y * vel * 0.6

def saw(f, t):
    return 2 * ((f * t) % 1.0) - 1

def pad(freqs, dur, vel, cutoff=1400, attack=1.2, release=1.8, kind="saw"):
    n = int((dur + release) * SR); t = np.arange(n) / SR
    w = np.zeros(n)
    for f in freqs:
        for det in (-0.12, 0.0, 0.11):
            ff = f * 2 ** (det / 12)
            ph = np.random.rand()
            w += saw(ff, t + ph / ff) if kind == "saw" else np.sin(2 * np.pi * ff * t + ph * 6.28)
    w = lowpass(w, cutoff) / (len(freqs) * 3)
    return w * env(n, attack, release) * vel

def choir(freqs, dur, vel, vowel="a"):
    n = int((dur + 1.5) * SR); t = np.arange(n) / SR
    src = np.zeros(n)
    for f in freqs:
        for det in (-0.08, 0.07):
            ff = f * 2 ** (det / 12) * (1 + 0.004 * np.sin(2 * np.pi * 5 * t))
            src += saw(ff, t)
    F = {"a": [(700, 1100), (1100, 1300), (2400, 2800)], "o": [(400, 700), (750, 1000), (2300, 2600)]}[vowel]
    w = sum(bandpass(src, lo, hi) * g for (lo, hi), g in zip(F, (1, 0.6, 0.25)))
    return w / len(freqs) * env(n, 0.9, 1.5) * vel * 1.4

def organ(freqs, dur, vel):
    n = int((dur + 0.6) * SR); t = np.arange(n) / SR
    w = sum(sum(a * np.sin(2 * np.pi * f * h * t) for h, a in ((1, 1), (2, 0.5), (3, 0.25), (4, 0.2), (0.5, 0.4))) for f in freqs)
    return w / len(freqs) * env(n, 0.08, 0.6) * vel * 0.25

def bass(f, dur, vel, grit=0.0):
    n = int((dur + 0.3) * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t)
    if grit: w = np.tanh(w * (1 + grit * 3)) + grit * 0.3 * lowpass(saw(f, t), 900)
    return w * env(n, 0.01, 0.25) * vel * 0.5

def drone(f, dur, vel):
    n = int((dur + 2) * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.5 * t + 1) + 0.3 * lowpass(saw(f * 2, t), 500)
    return w * env(n, 2.5, 2.5) * vel * 0.3

def kick(vel):
    n = int(0.45 * SR); t = np.arange(n) / SR
    f = 45 + 110 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7) * vel
def snare(vel):
    n = int(0.3 * SR); t = np.arange(n) / SR
    return (bandpass(np.random.randn(n), 900, 6000) * 0.8 * np.exp(-t * 16) + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25) * 0.6) * vel
def hat(vel, open_=False):
    n = int(0.2 * SR); t = np.arange(n) / SR
    return highpass(np.random.randn(n), 7000) * np.exp(-t * (12 if open_ else 50)) * vel * 0.35
def tom(f, vel):
    n = int(0.5 * SR); t = np.arange(n) / SR
    ff = f * (1 + 0.5 * np.exp(-t * 20))
    return np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.exp(-t * 6) * vel * 0.8

# ---------------- table de mixage ----------------
class Track:
    def __init__(self, bpm, bars, beats=4):
        self.spb = 60 / bpm; self.bar = self.spb * beats
        self.length = bars * self.bar
        self.n = int(self.length * SR)
        self.buf = np.zeros((self.n + 6 * SR, 2))
        self.dry = np.zeros((self.n + 6 * SR, 2))
    def add(self, start, w, pan=0.0, rev=0.4):
        i = int(start * SR); j = min(len(self.buf), i + len(w)); w = w[: j - i]
        l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        self.buf[i:j, 0] += w * l * rev; self.buf[i:j, 1] += w * r * rev
        self.dry[i:j, 0] += w * l * (1 - rev * 0.6); self.dry[i:j, 1] += w * r * (1 - rev * 0.6)
    def render(self, path, rev_time=3.0, gain=0.85):
        irn = int(rev_time * SR); t = np.arange(irn) / SR
        out = self.dry.copy()
        for ch in range(2):
            ir = lowpass(np.random.randn(irn), 5000) * np.exp(-t * 6.9 / rev_time)
            ir /= np.sqrt(np.sum(ir ** 2))
            out[:, ch] += fftconvolve(self.buf[:, ch], ir)[: len(out)] * 0.9
        # boucle sans couture : la queue repasse au début
        loop = out[: self.n].copy(); tail = out[self.n:]
        loop[: len(tail)] += tail[: self.n]
        loop = highpass(loop.T, 30).T
        loop = np.tanh(loop / (np.max(np.abs(loop)) + 1e-9) * 1.2) / np.tanh(1.2) * gain
        pcm = (loop * 32767).astype(np.int16)
        tmp = path + ".raw"; pcm.tofile(tmp)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", tmp,
                        "-c:a", "libvorbis", "-q:a", "4", path], check=True)
        os.remove(tmp)
        print("ok", os.path.basename(path), round(self.length, 1), "s")

# ---------------- écriture mélodique ----------------
def melody(rng, root, scale, prog, bars, spb, rhythms, start_deg=7, lo=4, hi=13, density=1.0):
    """Motif de 2 mesures répété et varié : A A' B A''. Renvoie [(temps, durée, midi, vel)]."""
    def make_phrase(bar0, nb, cur):
        ev = []
        for b in range(nb):
            ch = prog[(bar0 + b) % len(prog)]
            tones = [ch + 2 * k for k in range(3)]
            rh = rhythms[rng.integers(len(rhythms))]
            t = 0.0
            for i, d in enumerate(rh):
                if rng.random() > density and i > 0:
                    t += d; continue
                if t == 0 or rng.random() < 0.35:   # temps fort : note de l'accord
                    cands = [x + 7 * o for x in tones for o in (0, 1, 2) if lo <= x + 7 * o <= hi]
                    cur = min(cands, key=lambda x: abs(x - cur) + rng.random() * 2)
                else:
                    cur = int(np.clip(cur + rng.choice([-2, -1, -1, 1, 1, 2]), lo, hi))
                ev.append(((bar0 + b) * 4 * spb + t * spb, d * spb, deg(root, scale, cur), 0.7 + 0.3 * rng.random()))
                t += d
        return ev, cur
    out = []; cur = start_deg; phrase = None
    for bar0 in range(0, bars, 2):
        sec = (bar0 // 2) % 4
        if sec in (0, 1, 3) and phrase is not None and rng.random() < 0.7:
            # répète le motif, transposé selon l'accord et légèrement varié
            shift = bar0 * 4 * spb - phrase[0][0] // (8 * spb) * 8 * spb
            base = phrase[0][0] - (phrase[0][0] % (8 * spb))
            for (t, d, m, v) in phrase:
                mm = m + (rng.choice([0, 0, 0, 2, -1]) if rng.random() < 0.25 else 0)
                out.append((t - base + bar0 * 4 * spb, d, mm, v))
        else:
            ev, cur = make_phrase(bar0, 2, cur); out += ev
            if phrase is None or sec == 0: phrase = ev
    return out

R_SLOW = [[2, 2], [3, 1], [1, 1, 2], [4], [2, 1, 1], [1.5, 0.5, 2]]
R_MID = [[1, 1, 1, 1], [1.5, 0.5, 1, 1], [2, 1, 1], [0.5, 0.5, 1, 2], [1, 0.5, 0.5, 2]]

# ---------------- morceaux ----------------
def tuto():
    rng = np.random.default_rng(11); np.random.seed(11)
    T = Track(84, 16); root = 57; sc = "minor"; prog = [2, 0, 5, 4, 2, 0, 3, 4]
    for b in range(16):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c)], T.bar, 0.18, 1000, attack=0.8), 0, 0.6)
        for i, n in enumerate(chord(root, sc, c) * 2):
            T.add(t0 + i * T.spb / 2, musicbox(mtof(n + 12), 0.4, 0.18), -0.4 + 0.1 * i, 0.5)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 16, T.spb, R_SLOW, density=0.9):
        T.add(t, piano(mtof(m), d, v * 0.5), 0.15, 0.45)
    T.render(f"{OUT}/tuto_premiers_pas.ogg")

def profondeurs(seed, name, arps):
    rng = np.random.default_rng(seed); np.random.seed(seed)
    T = Track(70 if not arps else 76, 24); root = 50; sc = "minor"
    prog = [0, 5, 3, 4, 0, 5, 6, 4] if seed % 2 else [0, 3, 5, 4, 0, 6, 3, 4]
    for b in range(0, 24, 2):
        T.add(b * T.bar, drone(mtof(root - 24), 2 * T.bar, 0.35), 0, 0.3)
    for b in range(24):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.2, 900, attack=1.5), rng.uniform(-0.3, 0.3), 0.7)
        if arps and b >= 4:
            ns = chord(root, sc, c, 4)
            for i in range(8):
                T.add(t0 + i * T.spb / 2, pluck(mtof(ns[[0, 1, 2, 3, 2, 1, 2, 3][i]]), 0.5, 0.25, 0.3), 0.5 * np.sin(i), 0.6)
        T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar * 0.9, 0.35), 0, 0.2)
    if b := 1:
        ev = melody(rng, root + 12, sc, prog, 24, T.spb, R_SLOW, density=0.8 if arps else 0.95)
        for (t, d, m, v) in ev:
            if t >= 4 * T.bar or not arps:
                T.add(t, piano(mtof(m), d, v * 0.55), -0.1, 0.55)
    T.render(f"{OUT}/{name}.ogg", rev_time=4.0)

def jardins(seed, name, marimba):
    rng = np.random.default_rng(seed); np.random.seed(seed)
    T = Track(90 if not marimba else 82, 24); root = 52; sc = "dorian"
    prog = [0, 3, 0, 6, 0, 3, 4, 3] if not marimba else [0, 1, 3, 0, 5, 3, 1, 4]
    for b in range(24):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root, sc, c, 4)], T.bar, 0.14, 1800, attack=0.6, kind="sine"), 0, 0.7)
        for beat in range(4):
            T.add(t0 + beat * T.spb, bass(mtof(deg(root - 24, sc, c + (0 if beat % 2 == 0 else 4))), T.spb * 0.6, 0.3), 0, 0.15)
        ns = chord(root + 12, sc, c, 4)
        for i in range(8):
            if rng.random() < 0.8:
                inst = pluck(mtof(ns[rng.integers(4)]), 0.25, 0.22, 0.8) if not marimba else musicbox(mtof(ns[rng.integers(4)] - 12), 0.3, 0.2)
                T.add(t0 + i * T.spb / 2, inst, rng.uniform(-0.6, 0.6), 0.5)
        if b % 4 == 3:
            T.add(t0 + 3 * T.spb, bell(mtof(deg(root + 24, sc, c + 4)), 1, 0.25), 0.4, 0.7)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 24, T.spb, R_MID, density=0.75):
        if t >= 2 * T.bar:
            T.add(t, bell(mtof(m), d, v * 0.35) if marimba else piano(mtof(m), d, v * 0.4), 0.2, 0.5)
    T.render(f"{OUT}/{name}.ogg", rev_time=2.5)

def citadelle(seed, name, bells):
    rng = np.random.default_rng(seed); np.random.seed(seed)
    T = Track(64 if not bells else 72, 20); root = 48; sc = "harm"
    prog = [0, 5, 3, 4, 0, 3, 1, 4]
    for b in range(20):
        c = prog[b % 8]; t0 = b * T.bar
        freqs = [mtof(n) for n in chord(root - 12, sc, c, 4)]
        if not bells:
            T.add(t0, organ(freqs, T.bar * 0.98, 0.5), 0, 0.6)
            T.add(t0, choir([mtof(n) for n in chord(root, sc, c)], T.bar, 0.25, "o" if b % 2 else "a"), 0, 0.8)
        else:
            T.add(t0, pad(freqs, T.bar, 0.22, 1100, attack=1.0), 0, 0.7)
            T.add(t0, bell(mtof(deg(root + 12, sc, c)), 2, 0.45), -0.3, 0.8)
            T.add(t0 + 2 * T.spb, bell(mtof(deg(root + 12, sc, c + 2)), 2, 0.3), 0.3, 0.8)
        T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar, 0.35), 0, 0.3)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 20, T.spb, R_SLOW, density=0.85):
        if t >= 4 * T.bar:
            T.add(t, (choir([mtof(m)], d, v * 0.35, "a") if not bells else piano(mtof(m), d, v * 0.45)), 0.1, 0.6)
    T.render(f"{OUT}/{name}.ogg", rev_time=5.0)

def boss(seed, name, final, bpm=None, root=None, sc=None, prog=None):
    rng = np.random.default_rng(seed); np.random.seed(seed)
    bars = 24 if final else 16
    T = Track(bpm or (140 if final else 132), bars)
    root = root or (45 if not final else 48)
    sc = sc or ("phryg" if not final else "harm")
    prog = prog or ([0, 0, 1, 0, 5, 6, 1, 4] if not final else [0, 5, 3, 4, 0, 1, 6, 4])
    for b in range(bars):
        c = prog[b % 8]; t0 = b * T.bar; e = T.spb / 2
        for i in range(8):
            if i in (0, 3, 6) or (final and i == 4 and b % 2): T.add(t0 + i * e, kick(0.9), 0, 0.1)
            if i in (2, 6): T.add(t0 + i * e, snare(0.55), 0.1, 0.25)
            T.add(t0 + i * e, hat(0.4 + 0.2 * (i % 2), i == 7), 0.4, 0.1)
            T.add(t0 + i * e, bass(mtof(deg(root - 24, sc, c) + (12 if i % 4 == 3 else 0)), e * 0.85, 0.45, grit=0.6), 0, 0.05)
        if b % 4 == 3:
            for k in range(4):
                T.add(t0 + 3 * T.spb + k * e / 2, tom(110 - k * 15, 0.6), -0.3 + 0.2 * k, 0.2)
        freqs = [mtof(n) for n in chord(root - 12, sc, c, 3)]
        T.add(t0, pad(freqs, T.bar, 0.22, 2500, attack=0.05, release=0.3), 0, 0.4)
        if final:
            T.add(t0, choir([mtof(n) for n in chord(root, sc, c)], T.bar, 0.3, "a"), 0, 0.7)
            T.add(t0, organ(freqs, T.bar * 0.95, 0.3), 0, 0.5)
        # ostinato
        ns = chord(root, sc, c, 3)
        for i in range(16):
            n = ns[[0, 1, 2, 1][i % 4]] + (12 if i % 8 >= 4 else 0)
            T.add(t0 + i * e / 2, pluck(mtof(n), e / 2, 0.18, 0.9), 0.5 if i % 2 else -0.5, 0.3)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, bars, T.spb, R_MID, density=0.9):
        if t >= 4 * T.bar:
            T.add(t, pad([mtof(m)], d, v * 0.45, 3500, attack=0.03, release=0.25), 0, 0.4)
    T.render(f"{OUT}/{name}.ogg", rev_time=2.0, gain=0.9)

def sanctuaire():
    rng = np.random.default_rng(5); np.random.seed(5)
    T = Track(66, 12); root = 51; sc = "major"; prog = [0, 4, 5, 3, 0, 4, 3, 4]
    for b in range(12):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.22, 1600, attack=1.2, kind="sine"), 0, 0.7)
        T.add(t0, bell(mtof(deg(root + 12, sc, c)), 3, 0.35), -0.2, 0.8)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 12, T.spb, R_SLOW, density=0.9):
        T.add(t, piano(mtof(m), d, v * 0.45), 0.1, 0.6)
    T.render(f"{OUT}/sanctuaire.ogg", rev_time=5.0)

jobs = {
    "tuto": tuto,
    "p1": lambda: profondeurs(21, "profondeurs_puits_d_ombre", False),
    "p2": lambda: profondeurs(34, "profondeurs_lanternes_eteintes", True),
    "j1": lambda: jardins(7, "jardins_spores_flottantes", False),
    "j2": lambda: jardins(8, "jardins_mycelium", True),
    "c1": lambda: citadelle(3, "citadelle_nef_engloutie", False),
    "c2": lambda: citadelle(4, "citadelle_cloches_sous_l_eau", True),
    "b1": lambda: boss(9, "boss_gardien_du_puits", False),
    "b2": lambda: boss(10, "boss_abbesse_engloutie", True),
    "s": sanctuaire,
}

# ---------------- biomes supplémentaires ----------------
def ambient(seed, name, bpm, root, sc, prog, lead, arp, perc=False, drone_on=True, bars=20, cutoff=1200, rev=3.5):
    rng = np.random.default_rng(seed); np.random.seed(seed)
    T = Track(bpm, bars)
    for b in range(bars):
        c = prog[b % len(prog)]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.18, cutoff, attack=1.0), rng.uniform(-0.3, 0.3), 0.7)
        if drone_on and b % 2 == 0:
            T.add(t0, drone(mtof(root - 24), 2 * T.bar, 0.3), 0, 0.3)
        T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar * 0.9, 0.3, grit=0.4 if perc else 0), 0, 0.2)
        if arp and b >= 2:
            ns = chord(root + (12 if arp == "bell" else 0), sc, c, 4)
            for i in range(8):
                n = ns[[0, 2, 1, 3, 2, 1, 3, 2][i]]
                w = {"pluck": lambda: pluck(mtof(n), 0.3, 0.2, 0.6), "box": lambda: musicbox(mtof(n), 0.3, 0.16),
                     "bell": lambda: bell(mtof(n), 0.5, 0.12)}[arp]()
                T.add(t0 + i * T.spb / 2, w, 0.5 * np.sin(i * 1.3), 0.55)
        if perc:
            e = T.spb / 2
            for i in range(8):
                if i in (0, 5): T.add(t0 + i * e, kick(0.6), 0, 0.1)
                if i == 4: T.add(t0 + i * e, snare(0.3), 0.1, 0.4)
                T.add(t0 + i * e, hat(0.25, i == 7), 0.4, 0.1)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, bars, T.spb, R_SLOW if bpm < 80 else R_MID, density=0.85):
        if t >= 4 * T.bar:
            w = {"piano": lambda: piano(mtof(m), d, v * 0.5), "bell": lambda: bell(mtof(m), d, v * 0.3),
                 "choir": lambda: choir([mtof(m)], d, v * 0.3, "o"), "organ": lambda: organ([mtof(m)], d, v * 0.8)}[lead]()
            T.add(t, w, 0.1, 0.55)
    T.render(f"{OUT}/{name}.ogg", rev_time=rev)

jobs.update({
    "cristal": lambda: ambient(41, "cristal_echos_de_quartz", 78, 54, "dorian", [0, 3, 5, 3, 0, 4, 6, 4], "bell", "bell", cutoff=2200),
    "forge": lambda: ambient(42, "forge_enclume_ardente", 104, 45, "phryg", [0, 1, 0, 5, 0, 1, 6, 4], "organ", "pluck", perc=True, cutoff=900, rev=2.0),
    "biblio": lambda: ambient(43, "bibliotheque_pages_muettes", 66, 50, "minor", [0, 5, 2, 6, 3, 5, 1, 4], "piano", "box", drone_on=False, rev=4.5),
    "glace": lambda: ambient(44, "glace_souffle_givre", 60, 52, "minor", [0, 6, 5, 6, 0, 3, 4, 4], "bell", None, cutoff=1800, rev=6.0),
    "ruche": lambda: ambient(45, "ruche_bourdonnement", 112, 57, "dorian", [0, 0, 3, 4, 0, 0, 6, 4], "piano", "pluck", perc=True, drone_on=False, cutoff=2000, rev=2.0),
    "ossuaire": lambda: ambient(46, "ossuaire_requiem", 62, 47, "harm", [0, 3, 4, 0, 5, 1, 4, 4], "choir", None, cutoff=900, rev=5.5),
})

# ---------------- bruitages ----------------
def sfx_all(outdir):
    os.makedirs(outdir, exist_ok=True)
    def save(name, w):
        w = w / (np.max(np.abs(w)) + 1e-9) * 0.8
        pcm = (np.stack([w, w], 1) * 32767).astype(np.int16)
        tmp = f"{outdir}/{name}.raw"; pcm.tofile(tmp)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", tmp, f"{outdir}/{name}.wav"], check=True)
        os.remove(tmp)
    np.random.seed(99)
    def tt(d): return np.arange(int(d * SR)) / SR
    t = tt(0.18); save("slash", bandpass(np.random.randn(len(t)), 1500, 7000) * np.exp(-t * 25) * np.minimum(1, t / 0.01))
    t = tt(0.2); save("hit", np.sin(2 * np.pi * (300 - 900 * t) * t) * np.exp(-t * 20) + bandpass(np.random.randn(len(t)), 400, 2000) * np.exp(-t * 30))
    t = tt(0.4); save("hurt", np.tanh(3 * np.sin(2 * np.pi * (180 - 200 * t) * t)) * np.exp(-t * 8) + lowpass(np.random.randn(len(t)), 1200) * np.exp(-t * 10) * 0.6)
    t = tt(0.6); save("parry", sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((1800, 6), (2700, 8), (4100, 12))) + highpass(np.random.randn(len(t)), 5000) * np.exp(-t * 40))
    t = tt(0.25); save("dash", bandpass(np.random.randn(len(t)), 800, 5000) * np.sin(np.pi * t / 0.25) ** 2)
    t = tt(0.15); save("jump", np.sin(2 * np.pi * (220 + 600 * t) * t) * np.exp(-t * 18) * 0.6)
    t = tt(1.2); save("ult", lowpass(np.random.randn(len(t)), 800) * np.exp(-t * 3) + np.sin(2 * np.pi * 55 * t) * np.exp(-t * 2.5) + sum(np.sin(2 * np.pi * f * t) * np.exp(-t * 3) * 0.3 for f in (440, 660, 880)))
    t = tt(0.7); save("pickup", sum(np.sin(2 * np.pi * f * t) * np.exp(-t * 5) * (t > i * 0.08) for i, f in enumerate((660, 880, 1320))))
    t = tt(0.3); save("heal", sum(np.sin(2 * np.pi * f * t) * np.sin(np.pi * t / 0.3) for f in (523, 659, 784)) * 0.5)
    t = tt(0.3); save("spit", lowpass(np.random.randn(len(t)), 600) * np.exp(-t * 15) + np.sin(2 * np.pi * (500 - 1000 * t) * t) * np.exp(-t * 12))
    t = tt(0.5); save("kill", lowpass(np.random.randn(len(t)), 900) * np.exp(-t * 9) + np.sin(2 * np.pi * (200 - 250 * t) * t) * np.exp(-t * 7))
    t = tt(0.5); save("door", sum(np.sin(2 * np.pi * f * t) * np.exp(-t * 4) for f in (392, 523, 784)) * np.minimum(1, t / 0.05))
    print("sfx ok")
jobs.update({
    "b3": lambda: boss(13, "boss_reine_essaim", False, bpm=150, root=50, sc="dorian", prog=[0, 3, 0, 6, 0, 3, 4, 4]),
    "b4": lambda: boss(14, "boss_colosse_d_os", True, bpm=112, root=40, sc="phryg", prog=[0, 1, 0, 5, 0, 1, 6, 0]),
    "b5": lambda: boss(15, "boss_ver_des_profondeurs", False, bpm=126, root=43, sc="minor", prog=[0, 5, 6, 4, 0, 3, 6, 4]),
    "b6": lambda: boss(16, "boss_chevalier_spectral", True, bpm=146, root=47, sc="harm", prog=[0, 4, 5, 1, 0, 4, 3, 4]),
})
jobs["sfx"] = lambda: sfx_all(OUT.replace("music", "sfx"))

# ---------------- boss finaux et fin ----------------
def oeil(seed, name):
    # L'Œil d'en Dessous : lent, dissonant, chœur grave et pulsations (rythme irrégulier)
    rng = np.random.default_rng(seed); np.random.seed(seed)
    bars = 20; T = Track(96, bars); root = 38; sc = "phryg"; prog = [0, 1, 0, 6, 0, 1, 4, 1]
    for b in range(bars):
        c = prog[b % 8]; t0 = b * T.bar; e = T.spb / 2
        T.add(t0, drone(mtof(root - 24), T.bar * 1.2, 0.45), 0, 0.3)
        T.add(t0, choir([mtof(n) for n in chord(root - 12, sc, c, 3)], T.bar, 0.32, "o"), rng.uniform(-0.4, 0.4), 0.8)
        for i in [0, 3, 5, 6]:
            T.add(t0 + i * e, kick(0.8 if i == 0 else 0.55), 0, 0.15)
        if b % 2:
            T.add(t0 + 2 * T.spb, tom(70, 0.7), -0.4, 0.4)
            T.add(t0 + 3.5 * T.spb, tom(55, 0.7), 0.4, 0.4)
        for i in range(8):
            T.add(t0 + i * e, bass(mtof(deg(root - 24, sc, c) + (1 if i == 5 else 0)), e * 0.9, 0.4, grit=0.8), 0, 0.05)
        # cloches désaccordées
        if b % 2 == 0:
            T.add(t0 + T.spb, bell(mtof(deg(root + 12, sc, c)) * 1.012, 2, 0.3), 0.6, 0.9)
            T.add(t0 + 2.5 * T.spb, bell(mtof(deg(root + 13, sc, c + 4)) * 0.988, 2, 0.25), -0.6, 0.9)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, bars, T.spb, R_SLOW, density=0.6):
        if t >= 4 * T.bar:
            T.add(t, pad([mtof(m)], d, v * 0.4, 1800, attack=0.2, release=0.6), 0, 0.6)
    T.render(f"{OUT}/{name}.ogg", rev_time=4.5, gain=0.9)

def fin(seed, name):
    # Thème de fin : la Lanterne rallumée — lent, majeur, cloches, chœur et piano
    rng = np.random.default_rng(seed); np.random.seed(seed)
    bars = 28; T = Track(72, bars); root = 50; sc = "major"; prog = [0, 4, 5, 3, 0, 3, 4, 4]
    for b in range(bars):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.2, 1800, attack=1.0, kind="sine"), 0, 0.7)
        if b >= 4:
            T.add(t0, choir([mtof(n) for n in chord(root, sc, c)], T.bar, 0.22 + 0.1 * (b >= 16), "a"), 0, 0.8)
        if b >= 8:
            T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar * 0.9, 0.3), 0, 0.2)
        T.add(t0, bell(mtof(deg(root + 12, sc, c)), 3, 0.3), -0.3, 0.8)
        if b >= 16:
            for i in range(4):
                T.add(t0 + i * T.spb, kick(0.35), 0, 0.3)
            T.add(t0, organ([mtof(n) for n in chord(root - 12, sc, c)], T.bar * 0.95, 0.18), 0, 0.5)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, bars, T.spb, R_SLOW, density=0.85):
        T.add(t, piano(mtof(m), d, v * 0.5), 0.15, 0.6)
    T.render(f"{OUT}/{name}.ogg", rev_time=5.0, gain=0.85)

jobs.update({
    "f1": lambda: boss(31, "boss_ombre_lanterne", True, bpm=138, root=46, sc="harm", prog=[0, 5, 1, 4, 0, 6, 5, 4]),
    "f2": lambda: boss(32, "boss_cerbere", True, bpm=158, root=41, sc="phryg", prog=[0, 1, 0, 1, 5, 6, 1, 0]),
    "f3": lambda: boss(33, "boss_centaure", True, bpm=172, root=45, sc="dorian", prog=[0, 6, 5, 6, 0, 3, 4, 4]),
    "f4": lambda: oeil(34, "boss_oeil_d_en_dessous"),
    "end": lambda: fin(35, "fin_lanterne_rallumee"),
})

for k in (sys.argv[2:] or jobs):
    jobs[k]()

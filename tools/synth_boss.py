# Musiques des 10 gardiens (boss), composées une par une : chacune a son motif (leitmotiv),
# sa mesure, son tempo, ses timbres et sa forme (thème A, thème B, reprise plus intense, puis une
# courte montée qui relance le thème A). Le combat démarre directement sur le thème ; la boucle est
# sans couture.
# Usage : python3 tools/synth_boss.py music [b1 b2 …]
import sys, os
import numpy as np

# instruments, filtres et table de mixage communs (synth_music.py, sans ses morceaux)
_src = open(os.path.join(os.path.dirname(__file__), "synth_music.py"), encoding="utf-8").read()
exec(_src.split("# ---------------- morceaux ----------------")[0])
SCALES.update({
    "phrygdom": [0, 1, 4, 5, 7, 8, 10],   # phrygien dominant (oriental, menaçant)
    "locrian": [0, 1, 3, 5, 6, 8, 10],
})

# ---------------- timbres supplémentaires ----------------
def horn(f, dur, vel, bright=1.0):
    """Cuivre : dent de scie, filtre qui s'ouvre à l'attaque, léger vibrato."""
    n = int((dur + 0.4) * SR); t = np.arange(n) / SR
    vib = 1 + 0.003 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.4)
    w = saw(f * vib, t) * 0.6 + saw(f * 1.003 * vib, t) * 0.4
    open_ = 700 + 2200 * bright
    a = lowpass(w, open_) * 0.7 + lowpass(w, open_ * 0.45) * 0.5
    return a * env(n, 0.06, 0.3) * vel * 0.55

def strings(freqs, dur, vel, trem=0.0):
    """Cordes : nappe douce, trémolo facultatif (coups d'archet rapides)."""
    n = int((dur + 0.8) * SR); t = np.arange(n) / SR
    w = np.zeros(n)
    for f in freqs:
        for det in (-0.07, 0.0, 0.06):
            ff = f * 2 ** (det / 12)
            w += saw(ff * (1 + 0.002 * np.sin(2 * np.pi * 5.5 * t + det * 9)), t + np.random.rand() / ff)
    w = lowpass(w, 2600) / (len(freqs) * 3)
    if trem:
        w *= 0.55 + 0.45 * np.abs(np.sin(np.pi * trem * t))
    return w * env(n, 0.12, 0.6) * vel

def marimba(f, dur, vel):
    """Bois frappé (xylophone d'os)."""
    n = int(1.2 * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) * np.exp(-t * 7) + 0.4 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t * 18) \
        + 0.15 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t * 35)
    return w * np.minimum(1, t / 0.001) * vel * 0.5

def taiko(vel, f=62):
    n = int(0.9 * SR); t = np.arange(n) / SR
    ff = f * (1 + 0.8 * np.exp(-t * 25))
    body = np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.exp(-t * 4.5)
    skin = lowpass(np.random.randn(n), 900) * np.exp(-t * 30) * 0.5
    return (body + skin) * vel

def anvil(vel):
    n = int(1.2 * SR); t = np.arange(n) / SR
    w = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, a, d in ((1180, 1, 6), (2950, 0.6, 9), (4410, 0.4, 14), (6320, 0.2, 20)))
    return w * vel * 0.25

def buzz(f, dur, vel):
    """Bourdonnement d'essaim : scie détunée, filtre qui bat."""
    n = int((dur + 0.2) * SR); t = np.arange(n) / SR
    w = saw(f, t) + saw(f * 1.012, t) + 0.6 * saw(f * 0.5, t)
    lfo = 900 + 700 * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * t))
    out = np.zeros(n)
    for i in range(0, n, 512):      # filtre balayé par blocs
        out[i:i + 512] = lowpass(w[i:i + 512], float(lfo[i]))
    return out * env(n, 0.01, 0.1) * vel * 0.3

def sub(f, dur, vel):
    """Basse sub qui gronde (le Ver)."""
    n = int((dur + 0.4) * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) + 0.5 * np.tanh(3 * np.sin(2 * np.pi * f * t)) * 0.6
    w += 0.25 * lowpass(saw(f * 2, t), 400) * (0.5 + 0.5 * np.sin(2 * np.pi * 3 * t))
    return w * env(n, 0.03, 0.35) * vel * 0.55

def glass(f, dur, vel):
    """Harmonica de verre (l'Œil) : sinus purs, battement lent."""
    n = int((dur + 1.5) * SR); t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.003 * t) + 0.2 * np.sin(2 * np.pi * f * 2.0 * t)
    return w * env(n, 0.35, 1.2) * vel * 0.35

def gallop_snare(vel):
    return snare(vel) * 0.8

# ---------------- moteur ----------------
class Boss:
    """Arrangement d'un boss. Une « mesure » compte `beats` temps ; les motifs sont des listes
    (degré de la gamme ou None pour un silence, durée en temps)."""
    def __init__(self, name, seed, bpm, root, sc, beats=4):
        self.name = name; self.rng = np.random.default_rng(seed); np.random.seed(seed)
        self.bpm = bpm; self.root = root; self.sc = sc; self.beats = beats
        self.parts = []          # (n_mesures, fonction(T, t0, mesure_index_section, intensité, accord))
    def section(self, bars, fn, prog, inten):
        self.parts.append((bars, fn, prog, inten))
    def render(self, rev=2.4, gain=0.9):
        total = sum(p[0] for p in self.parts)
        T = Track(self.bpm, total, self.beats)
        b0 = 0
        for bars, fn, prog, inten in self.parts:
            for b in range(bars):
                fn(T, (b0 + b) * T.bar, b, inten, prog[b % len(prog)])
            b0 += bars
        T.render(f"{OUT}/{self.name}.ogg", rev_time=rev, gain=gain)
        return T

def play_motif(T, t0, motif, root, sc, inst, vel=0.6, pan=0.0, rev=0.4, oct_=0, spb=None):
    spb = spb or T.spb
    t = 0.0
    for d, dur in motif:
        if d is not None:
            T.add(t0 + t * spb, inst(mtof(deg(root, sc, d) + 12 * oct_), dur * spb * 0.95, vel), pan, rev)
        t += dur

def drums(T, t0, pattern, vel=1.0, step=None):
    """pattern : chaînes par instrument, un caractère par pas (x fort, o faible, . rien)."""
    step = step or T.spb / 4
    for inst, row in pattern.items():
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            v = (1.0 if ch == "x" else 0.55) * vel
            tt = t0 + i * step
            if inst == "k": T.add(tt, kick(0.9 * v), 0, 0.08)
            elif inst == "s": T.add(tt, snare(0.6 * v), 0.1, 0.25)
            elif inst == "h": T.add(tt, hat(0.45 * v), 0.35, 0.1)
            elif inst == "H": T.add(tt, hat(0.45 * v, True), 0.35, 0.15)
            elif inst == "t": T.add(tt, taiko(0.8 * v), -0.2, 0.35)
            elif inst == "T": T.add(tt, taiko(0.7 * v, 95), 0.25, 0.35)
            elif inst == "a": T.add(tt, anvil(0.8 * v), 0.5, 0.4)
            elif inst == "m": T.add(tt, tom(120, 0.6 * v), -0.3, 0.2)
            elif inst == "n": T.add(tt, tom(80, 0.6 * v), 0.3, 0.2)

def chord_pad(T, t0, root, sc, c, dur, vel, inst="strings", **kw):
    fr = [mtof(n) for n in chord(root, sc, c, 3)]
    if inst == "strings": T.add(t0, strings(fr, dur, vel, **kw), 0, 0.6)
    elif inst == "choir": T.add(t0, choir(fr, dur, vel, kw.get("vowel", "a")), 0, 0.75)
    elif inst == "organ": T.add(t0, organ(fr, dur, vel), 0, 0.55)
    elif inst == "pad": T.add(t0, pad(fr, dur, vel, kw.get("cutoff", 1600), attack=kw.get("attack", 0.3), release=0.6), 0, 0.5)

def bassline(T, t0, root, sc, c, pattern, vel=0.45, grit=0.6, inst=None, step=None):
    """pattern : pas de croche/double ; chiffre = décalage d'octave (0 fondamentale, 1 octave), '.' silence, '5' quinte."""
    step = step or T.spb / 2
    for i, ch in enumerate(pattern):
        if ch == ".":
            continue
        n = deg(root - 24, sc, c)
        if ch == "1": n += 12
        elif ch == "5": n = deg(root - 24, sc, c + 4)
        elif ch == "b": n -= 1
        f = mtof(n)
        w = (inst or (lambda f, d, v: bass(f, d, v, grit=grit)))(f, step * 0.9, vel)
        T.add(t0 + i * step, w, 0, 0.05)

# ---------------- les dix gardiens ----------------
def gardien():
    # Le Gardien du Puits : scarabée cuirassé. Martèlement tribal, riff de cuivres trapu, ré phrygien.
    B = Boss("boss_gardien_du_puits", 101, 128, 50, "phryg")
    riff = [(0, 0.75), (0, 0.25), (1, 0.5), (0, 0.5), (None, 0.5), (-1, 0.5), (0, 1)]
    riff2 = [(4, 0.75), (3, 0.25), (1, 0.5), (0, 0.5), (1, 1), (-2, 1)]
    hook = [(7, 1.5), (8, 0.5), (7, 0.5), (5, 0.5), (4, 1), (None, 0.5), (3, 0.5), (4, 1), (1, 1), (0, 2)]
    D = {"k": "x...x..x..x.x...", "s": "....x.......x...", "h": "o.o.o.o.o.o.o.oo", "t": "x.......x.....x."}
    def intro(T, t0, b, it, c):
        drums(T, t0, {"t": "x...x...x...x.x.", "T": "....x.......x..." if b >= 2 else "................"})
        bassline(T, t0, B.root, B.sc, c, "0...0...0...0.0.", 0.4, 0.8)
        if b == 3: drums(T, t0, {"m": "........xxxx....", "n": "............xxxx"})
    def a(T, t0, b, it, c):
        drums(T, t0, D, it)
        bassline(T, t0, B.root, B.sc, c, "0.0.10.00.0.1050", 0.45, 0.7)
        play_motif(T, t0, riff if b % 2 == 0 else riff2, B.root - 12, B.sc, lambda f, d, v: horn(f, d, v, 0.6), 0.5, -0.2, 0.3)
        if it > 1.0 and b % 2 == 0:
            play_motif(T, t0, hook[:6], B.root, B.sc, horn, 0.45, 0.25, 0.4)
        elif it > 1.0:
            play_motif(T, t0, hook[6:], B.root, B.sc, horn, 0.45, 0.25, 0.4)
    def bsec(T, t0, b, it, c):
        drums(T, t0, {"k": "x.......x.......", "t": "x..x..x...x..x..", "T": "..x...x...x...x.", "h": "x.x.x.x.x.x.x.x."})
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.25, "strings", trem=12)
        bassline(T, t0, B.root, B.sc, c, "0...0...0.1.0...", 0.45)
        play_motif(T, t0, hook[:6] if b % 2 == 0 else hook[6:], B.root, B.sc, horn, 0.5, 0, 0.45)
    B.section(8, a, [0, 0, 1, 0, 0, 0, 6, 1], 1.0)
    B.section(8, bsec, [5, 6, 1, 0, 5, 6, 3, 4], 1.0)
    B.section(8, a, [0, 0, 1, 0, 5, 4, 1, 0], 1.2)
    B.section(4, intro, [0], 1.0)
    return B.render(2.0)

def abbesse():
    # L'Abbesse Engloutie : orgue d'église noyé, chœur, valse lente à 3 temps, mi mineur harmonique.
    B = Boss("boss_abbesse_engloutie", 102, 132, 52, "harm", beats=3)
    theme = [(4, 1), (5, 0.5), (4, 0.5), (2, 1), (0, 1.5), (1, 0.5), (2, 1), (4, 2), (None, 1),
             (7, 1), (6, 0.5), (4, 0.5), (5, 1), (3, 1.5), (2, 0.5), (1, 1), (0, 3)]
    def drip(T, t0, b):
        for k in range(2):
            if B.rng.random() < 0.7:
                T.add(t0 + B.rng.uniform(0, T.bar), bell(mtof(deg(B.root + 24, B.sc, int(B.rng.integers(0, 7)))), 1, 0.12), B.rng.uniform(-0.8, 0.8), 0.9)
    def intro(T, t0, b, it, c):
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.32, "organ")
        drip(T, t0, b)
    def waltz(T, t0, b, it, c):
        drums(T, t0, {"k": "x.....", "s": "..o.o.", "h": "oooooo"}, it * 0.8, T.spb / 2)
        bassline(T, t0, B.root, B.sc, c, "0.5.5.", 0.4, 0.2)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.26, "organ")
        if it > 1.0:
            chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.28, "choir", vowel="o")
        drip(T, t0, b)
        if b % 4 == 0:
            play_motif(T, t0, theme, B.root, B.sc, lambda f, d, v: choir([f], d, v, "a"), 0.55, 0, 0.7)
            play_motif(T, t0, theme, B.root, B.sc, lambda f, d, v: organ([f], d, v), 0.4 * it, 0.2, 0.5, oct_=1 if it > 1.0 else 0)
    def storm(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..", "t": "x.....", "s": "...x..", "h": "xoxoxo"}, 1.0, T.spb / 2)
        bassline(T, t0, B.root, B.sc, c, "010101", 0.45, 0.6)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "strings", trem=16)
        for i in range(6):
            n = chord(B.root + 12, B.sc, c, 3)[[0, 1, 2, 1, 2, 1][i]]
            T.add(t0 + i * T.spb / 2, pluck(mtof(n), T.spb / 2, 0.22, 0.8), 0.5 if i % 2 else -0.5, 0.4)
    B.section(16, waltz, [0, 0, 5, 3, 1, 4, 0, 4], 1.0)
    B.section(8, storm, [5, 3, 6, 4], 1.0)
    B.section(16, waltz, [0, 0, 5, 3, 1, 4, 0, 4], 1.3)
    B.section(4, intro, [0, 5, 3, 4], 1.0)
    return B.render(4.0)

def reine():
    # La Reine Essaim : rapide, nerveux, bourdonnements en doubles croches, ré dorien.
    B = Boss("boss_reine_essaim", 103, 156, 50, "dorian")
    sting = [(7, 0.25), (6, 0.25), (7, 0.25), (9, 0.25), (7, 0.5), (4, 0.5), (5, 0.25), (4, 0.25), (2, 0.5), (4, 1)]
    royal = [(0, 1), (2, 0.5), (4, 0.5), (7, 1.5), (6, 0.5), (4, 1), (5, 1), (3, 2)]
    def swarm(T, t0, c, vel):
        ns = chord(B.root, B.sc, c, 3)
        for i in range(16):
            n = ns[[0, 2, 1, 2][i % 4]] + (12 if (i // 4) % 2 else 0)
            T.add(t0 + i * T.spb / 4, buzz(mtof(n), T.spb / 4, vel), 0.6 * np.sin(i), 0.2)
    def intro(T, t0, b, it, c):
        swarm(T, t0, c, 0.15 + 0.08 * b)
        drums(T, t0, {"h": "xxxxxxxxxxxxxxxx"} if b >= 2 else {"h": "x.x.x.x.x.x.x.x."})
    def a(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..x...x..x..", "s": "....x.......x..x", "h": "xxxxxxxxxxxxxxxx"}, it)
        bassline(T, t0, B.root, B.sc, c, "0.1.0.1.0.1.0.15", 0.45, 0.5, step=T.spb / 4 * 2)
        swarm(T, t0, c, 0.18)
        play_motif(T, t0, sting, B.root + 12, B.sc, lambda f, d, v: buzz(f, d, v * 1.6), 0.6, 0, 0.3)
        if it > 1.0:
            play_motif(T, t0, sting, B.root, B.sc, lambda f, d, v: horn(f, d, v, 1.2), 0.4, -0.3, 0.3)
    def court(T, t0, b, it, c):
        drums(T, t0, {"k": "x.......x.......", "s": "....x.......x...", "m": "..............xx"})
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.28, "strings", trem=20)
        play_motif(T, t0, royal[:4] if b % 2 == 0 else royal[4:], B.root, B.sc, horn, 0.5, 0, 0.45)
        bassline(T, t0, B.root, B.sc, c, "0.......0...0...", 0.45)
    B.section(8, a, [0, 3, 0, 6, 0, 3, 4, 4], 1.0)
    B.section(8, court, [3, 4, 0, 5, 3, 4, 6, 4], 1.0)
    B.section(8, a, [0, 3, 0, 6, 0, 3, 4, 4], 1.3)
    B.section(4, intro, [0, 3], 1.0)
    return B.render(1.8)

def colosse():
    # Le Colosse d'Os : lourd et lent, taikos, xylophone d'os, mi phrygien, grands accords de cuivres.
    B = Boss("boss_colosse_d_os", 104, 92, 40, "phryg")
    bones = [(0, 0.5), (1, 0.5), (0, 0.5), (4, 0.5), (3, 0.5), (1, 0.5), (0, 1)]
    giant = [(0, 2), (1, 1), (3, 1), (4, 3), (3, 0.5), (1, 0.5), (0, 4)]
    def intro(T, t0, b, it, c):
        drums(T, t0, {"t": "x.......x.......", "T": "........x.....x." if b >= 2 else "................"})
        T.add(t0, drone(mtof(B.root - 12), T.bar, 0.4), 0, 0.4)
        play_motif(T, t0, bones, B.root + 24, B.sc, marimba, 0.45, 0.4, 0.5)
    def a(T, t0, b, it, c):
        drums(T, t0, {"t": "x.....x...x.....", "T": "....x.......x.x.", "k": "x.....x...x.....", "a": "....x.......x..." if it > 1 else "................"}, it)
        bassline(T, t0, B.root + 12, B.sc, c, "0...0.0.0...0.1.", 0.5, 0.9)
        play_motif(T, t0, bones, B.root + 24, B.sc, marimba, 0.4, 0.4, 0.4)
        play_motif(T, t0, bones, B.root + 24, B.sc, marimba, 0.3, -0.4, 0.4, spb=T.spb) if b % 2 else None
        if b % 2 == 0:
            play_motif(T, t0, giant, B.root, B.sc, lambda f, d, v: horn(f, d, v, 0.5), 0.55 * it, 0, 0.45)
            play_motif(T, t0, giant, B.root - 12, B.sc, lambda f, d, v: horn(f, d, v, 0.3), 0.45 * it, 0, 0.45)
    def chant(T, t0, b, it, c):
        drums(T, t0, {"t": "x...x...x...x...", "T": "..x...x...x...xx"})
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.35, "choir", vowel="o")
        bassline(T, t0, B.root + 12, B.sc, c, "0.......0.......", 0.5, 0.9)
    B.section(8, a, [0, 1, 0, 5, 0, 1, 6, 0], 1.0)
    B.section(4, chant, [5, 6, 1, 0], 1.0)
    B.section(8, a, [0, 1, 0, 5, 0, 1, 6, 0], 1.3)
    B.section(4, intro, [0], 1.0)
    return B.render(3.0)

def ver():
    # Le Ver des Profondeurs : mesure à 7/8 qui rampe, basse sub qui gronde, sol mineur.
    B = Boss("boss_ver_des_profondeurs", 105, 150, 43, "minor", beats=3.5)
    coil = [(0, 1), (2, 0.5), (3, 1), (2, 0.5), (0, 0.5)]
    surface = [(7, 1.5), (5, 0.5), (6, 1), (4, 0.5), (3, 1.5), (2, 0.5), (0, 1.5)]
    D = {"k": "x...x.x...x...", "s": "......x.....x.", "h": "o.o.o.o.o.o.o."}
    def intro(T, t0, b, it, c):
        bassline(T, t0, B.root, B.sc, c, "0...0.0...0...", 0.5, inst=sub, step=T.spb / 4)
        drums(T, t0, {"T": "x.............", "t": "......x......." if b >= 2 else ".............."})
    def a(T, t0, b, it, c):
        drums(T, t0, D, it)
        bassline(T, t0, B.root, B.sc, c, "0.1.0.b.0.1.5.", 0.5, inst=sub, step=T.spb / 4 * 2 / 2)
        play_motif(T, t0, coil, B.root, B.sc, lambda f, d, v: horn(f, d, v, 0.8), 0.45, -0.2, 0.3)
        if it > 1.0:
            play_motif(T, t0, coil, B.root + 12, B.sc, lambda f, d, v: pluck(f, d, v, 0.9), 0.4, 0.4, 0.3)
    def emerge(T, t0, b, it, c):
        drums(T, t0, {"k": "x.............", "t": "x.....x.......", "s": "......x.......", "H": "x.............", "m": "..........xxxx"})
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "strings", trem=10)
        play_motif(T, t0, surface, B.root + 12, B.sc, horn, 0.5, 0, 0.45) if b % 2 == 0 else None
        bassline(T, t0, B.root, B.sc, c, "0......0......", 0.5, inst=sub, step=T.spb / 4)
    B.section(8, a, [0, 0, 5, 6, 0, 0, 3, 4], 1.0)
    B.section(8, emerge, [5, 6, 3, 4, 5, 6, 0, 4], 1.0)
    B.section(8, a, [0, 0, 5, 6, 0, 0, 3, 4], 1.3)
    B.section(4, intro, [0], 1.0)
    return B.render(2.4)

def chevalier():
    # Le Chevalier Spectral : galop (rythme de cavalerie), fanfare héroïque mais sombre, si harmonique.
    B = Boss("boss_chevalier_spectral", 106, 144, 47, "harm")
    fanfare = [(0, 0.5), (0, 0.25), (0, 0.25), (4, 1), (3, 0.5), (4, 0.5), (6, 1), (7, 2), (None, 1),
               (8, 0.5), (7, 0.5), (6, 0.5), (4, 0.5), (5, 1), (4, 0.5), (3, 0.5), (4, 2)]
    oath = [(7, 2), (6, 1), (4, 1), (5, 2), (3, 2), (4, 3), (None, 1)]
    gallop = {"k": "x..x..x.x..x..x.", "s": "....x.......x...", "h": "x.xx.xx.xx.xx.xx"}
    def intro(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..x.x..x..x.", "h": "x.xx.xx.xx.xx.xx" if b >= 2 else "................"}, 0.7)
        T.add(t0, bell(mtof(B.root), 2, 0.35), 0, 0.9)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.22, "choir", vowel="o")
    def a(T, t0, b, it, c):
        drums(T, t0, gallop, it)
        bassline(T, t0, B.root, B.sc, c, "0.01.00.0.01.00.", 0.45, 0.5, step=T.spb / 4)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.18, "strings")
        if b % 4 == 0:
            play_motif(T, t0, fanfare, B.root, B.sc, lambda f, d, v: horn(f, d, v, 1.1), 0.55 * it, 0, 0.4)
            if it > 1.0:
                play_motif(T, t0, fanfare, B.root + 12, B.sc, lambda f, d, v: strings([f], d, v), 0.4, 0.3, 0.5)
    def vow(T, t0, b, it, c):
        drums(T, t0, {"k": "x.......x.......", "t": "x.......x...x...", "s": "............x..."})
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.32, "choir")
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.25, "organ")
        if b % 4 == 0:
            play_motif(T, t0, oath, B.root, B.sc, lambda f, d, v: bell(f, d, v * 1.5), 0.6, 0, 0.8)
        bassline(T, t0, B.root, B.sc, c, "0.......0.......", 0.45)
    B.section(8, a, [0, 4, 5, 1, 0, 4, 3, 4], 1.0)
    B.section(8, vow, [5, 3, 0, 4, 5, 6, 4, 4], 1.0)
    B.section(8, a, [0, 4, 5, 1, 0, 4, 3, 4], 1.3)
    B.section(4, intro, [0, 4, 5, 4], 1.0)
    return B.render(2.8)

def ombre():
    # L'Ombre de la Lanterne (boss final) : thème de la Lanterne retourné en mineur, chœur, orgue, épique.
    B = Boss("boss_ombre_lanterne", 107, 132, 46, "harm")
    lantern = [(0, 1), (4, 1), (7, 1.5), (6, 0.5), (4, 1), (5, 1), (4, 2),
               (2, 1), (4, 1), (3, 1), (1, 1), (0, 4)]
    dark = [(7, 0.5), (8, 0.5), (7, 0.5), (6, 0.5), (4, 1), (None, 0.5), (4, 0.5), (3, 0.5), (1, 0.5), (0, 2)]
    D = {"k": "x...x...x...x...", "s": "....x.......x...", "h": "o.x.o.x.o.x.o.xo", "t": "x.........x....."}
    def intro(T, t0, b, it, c):
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "organ")
        if b % 2 == 0:
            play_motif(T, t0, lantern[:7], B.root, B.sc, lambda f, d, v: musicbox(f, d, v), 0.5, 0, 0.8)
        else:
            play_motif(T, t0, lantern[7:], B.root, B.sc, lambda f, d, v: musicbox(f, d, v), 0.5, 0, 0.8)
    def a(T, t0, b, it, c):
        drums(T, t0, D, it)
        bassline(T, t0, B.root, B.sc, c, "0.0.0.010.0.0.15", 0.45, 0.6)
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.26 * it, "choir")
        for i in range(8):
            n = chord(B.root + 12, B.sc, c, 3)[[0, 1, 2, 1][i % 4]] + (12 if i >= 4 else 0)
            T.add(t0 + i * T.spb / 2, pluck(mtof(n), T.spb / 2, 0.2, 0.8), 0.5 if i % 2 else -0.5, 0.35)
        play_motif(T, t0, dark, B.root + 12, B.sc, lambda f, d, v: horn(f, d, v, 1.2), 0.5, 0, 0.4)
    def epic(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..x.x..x..x.", "s": "....x.......x...", "t": "x...x...x...x...", "h": "xxxxxxxxxxxxxxxx"})
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "organ")
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.32, "choir")
        bassline(T, t0, B.root, B.sc, c, "0101010101010101", 0.45, 0.7, step=T.spb / 4)
        mot = lantern[:7] if b % 2 == 0 else lantern[7:]
        play_motif(T, t0, mot, B.root, B.sc, lambda f, d, v: horn(f, d, v, 1.3), 0.6, 0, 0.45)
        play_motif(T, t0, mot, B.root + 12, B.sc, lambda f, d, v: strings([f], d, v), 0.4, 0.3, 0.5)
    B.section(8, a, [0, 5, 1, 4, 0, 6, 5, 4], 1.0)
    B.section(8, epic, [0, 5, 3, 4, 0, 1, 6, 4], 1.0)
    B.section(8, a, [0, 5, 1, 4, 0, 6, 5, 4], 1.3)
    B.section(4, intro, [0, 5, 1, 4], 1.0)
    return B.render(3.2)

def cerbere():
    # Le Cerbère : trois têtes, motif en trois notes répété trois fois, phrygien dominant, brutal.
    B = Boss("boss_cerbere", 108, 164, 41, "phrygdom")
    heads = [(0, 0.5), (1, 0.5), (2, 0.5), (0, 0.5), (1, 0.5), (2, 0.5), (0, 0.5), (1, 0.5), (4, 2)]
    howl = [(7, 2), (6, 0.5), (5, 0.5), (4, 1), (2, 2), (1, 1), (0, 1)]
    D = {"k": "x.x.x..xx.x.x..x", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x.", "t": "x.......x......."}
    def intro(T, t0, b, it, c):
        drums(T, t0, {"t": "x..x..x.x..x..x.", "T": "..........xx..xx" if b >= 2 else "................"})
        bassline(T, t0, B.root, B.sc, c, "0..0..0.0..0..0.", 0.5, 1.0, step=T.spb / 4)
    def a(T, t0, b, it, c):
        drums(T, t0, D, it)
        bassline(T, t0, B.root, B.sc, c, "0001000100010b0b", 0.5, 1.0, step=T.spb / 4)
        play_motif(T, t0, heads, B.root, B.sc, lambda f, d, v: horn(f, d, v, 1.4), 0.5, -0.4, 0.3)
        play_motif(T, t0, heads, B.root + 7 if False else B.root, B.sc, lambda f, d, v: horn(f * 1.5, d, v, 1.0), 0.3, 0.4, 0.3)
        if it > 1.0:
            play_motif(T, t0, heads, B.root + 12, B.sc, lambda f, d, v: buzz(f, d, v * 1.3), 0.4, 0, 0.3)
    def hell(T, t0, b, it, c):
        drums(T, t0, {"k": "x.......x.......", "t": "x..x..x...x..x..", "a": "....x.......x..."})
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.32, "choir", vowel="o")
        if b % 2 == 0:
            play_motif(T, t0, howl, B.root + 12, B.sc, horn, 0.55, 0, 0.5)
        bassline(T, t0, B.root, B.sc, c, "0.......0...0...", 0.5, 1.0)
    B.section(8, a, [0, 1, 0, 1, 5, 6, 1, 0], 1.0)
    B.section(8, hell, [0, 1, 5, 6], 1.0)
    B.section(8, a, [0, 1, 0, 1, 5, 6, 1, 0], 1.3)
    B.section(4, intro, [0], 1.0)
    return B.render(2.0)

def centaure():
    # Le Centaure Archer : 6/8 au galop, cordes pincées et cors de chasse, la dorien, très rapide.
    B = Boss("boss_centaure", 109, 184, 45, "dorian", beats=3)
    hunt = [(4, 0.5), (4, 0.5), (4, 0.5), (7, 1), (6, 0.5), (4, 1.5), (2, 1.5),
            (3, 0.5), (4, 0.5), (5, 0.5), (4, 1), (2, 0.5), (0, 3)]
    arrows = [(7, 0.5), (9, 0.5), (11, 0.5), (9, 0.5), (7, 0.5), (4, 0.5)]
    def intro(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..", "h": "x.xx.x"}, 0.7, T.spb / 2)
        play_motif(T, t0, [(0, 0.5), (4, 0.5), (7, 0.5), (4, 0.5), (0, 0.5), (4, 0.5)], B.root, B.sc, lambda f, d, v: pluck(f, d, v, 0.8), 0.45, 0.3, 0.3)
    def a(T, t0, b, it, c):
        drums(T, t0, {"k": "x..x..", "s": "...x..", "h": "xoxxox"}, it, T.spb / 2)
        bassline(T, t0, B.root, B.sc, c, "0.50.5", 0.45, 0.4)
        play_motif(T, t0, arrows, B.root + 12, B.sc, lambda f, d, v: pluck(f, d, v, 0.9), 0.35, 0.4, 0.3)
        if b % 4 == 0:
            play_motif(T, t0, hunt, B.root, B.sc, lambda f, d, v: horn(f, d, v, 0.9), 0.55 * it, -0.2, 0.45)
    def forest(T, t0, b, it, c):
        drums(T, t0, {"t": "x.....", "T": "...x..", "h": "x.x.x."}, 1.0, T.spb / 2)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "strings", trem=14)
        play_motif(T, t0, hunt[:7] if b % 4 < 2 else hunt[7:], B.root + 12, B.sc, lambda f, d, v: strings([f], d, v), 0.45, 0, 0.5) if b % 2 == 0 else None
        bassline(T, t0, B.root, B.sc, c, "0.....", 0.45)
    B.section(16, a, [0, 6, 5, 6, 0, 3, 4, 4], 1.0)
    B.section(8, forest, [3, 4, 5, 6], 1.0)
    B.section(16, a, [0, 6, 5, 6, 0, 3, 4, 4], 1.3)
    B.section(4, intro, [0, 6, 5, 6], 1.0)
    return B.render(2.2)

def oeil():
    # L'Œil d'en Dessous : mesure boiteuse à 5 temps, harmonica de verre, chœur grave, clusters.
    B = Boss("boss_oeil_d_en_dessous", 110, 100, 38, "locrian", beats=5)
    gaze = [(0, 1.5), (1, 0.5), (0, 1), (4, 2), (3, 1.5), (1, 0.5), (0, 3)]
    def intro(T, t0, b, it, c):
        T.add(t0, drone(mtof(B.root - 12), T.bar, 0.45), 0, 0.4)
        play_motif(T, t0, gaze[:4] if b % 2 == 0 else gaze[4:], B.root + 24, B.sc, glass, 0.4, B.rng.uniform(-0.5, 0.5), 0.9)
    def a(T, t0, b, it, c):
        drums(T, t0, {"k": "x.....x...", "t": "....x.....", "T": "........x.", "s": "......x..."}, it, T.spb / 2)
        bassline(T, t0, B.root, B.sc, c, "0..0..0.b.", 0.45, 0.9)
        chord_pad(T, t0, B.root - 12, B.sc, c, T.bar, 0.3, "choir", vowel="o")
        if b % 2 == 0:
            play_motif(T, t0, gaze, B.root + 12, B.sc, glass, 0.5, 0, 0.8)
        # cluster dissonant qui pulse
        if it > 1.0 and b % 2:
            fr = [mtof(B.root + k) for k in (0, 1, 3)]
            T.add(t0 + 2 * T.spb, pad(fr, T.spb * 2, 0.25, 1200, attack=0.4, release=0.8), 0, 0.7)
    def stare(T, t0, b, it, c):
        drums(T, t0, {"t": "x...x...x.", "k": "x.........", "a": "......x..."}, 1.0, T.spb / 2)
        chord_pad(T, t0, B.root, B.sc, c, T.bar, 0.3, "strings", trem=8)
        T.add(t0, bell(mtof(deg(B.root + 12, B.sc, c)) * 1.01, 2, 0.35), 0.5, 0.9)
        bassline(T, t0, B.root, B.sc, c, "0.........", 0.45, 0.9)
    B.section(8, a, [0, 1, 0, 6, 0, 1, 4, 1], 1.0)
    B.section(4, stare, [1, 6, 4, 1], 1.0)
    B.section(8, a, [0, 1, 0, 6, 0, 1, 4, 1], 1.3)
    B.section(4, intro, [0, 1], 1.0)
    return B.render(4.5)

jobs = {"b1": gardien, "b2": abbesse, "b3": reine, "b4": colosse, "b5": ver, "b6": chevalier,
        "f1": ombre, "f2": cerbere, "f3": centaure, "f4": oeil}
for k in (sys.argv[2:] or jobs):
    jobs[k]()

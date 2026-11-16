# Musiques de fête, originales (générées par ce script, aucune mélodie existante reprise) :
#   python3 tools/synth_fetes.py music_fetes
# Même moteur et mêmes instruments que tools/synth_music.py (le Sanctuaire : nappes, cloches, piano, boîte à musique).
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, "synth_music.py"), encoding="utf-8").read()
exec(src[: src.index("# ---------------- morceaux ----------------")])   # moteur, instruments, écriture mélodique

def jingle(vel):
    """Grelots : partiels aigus inharmoniques, très courts."""
    n = int(0.35 * SR); t = np.arange(n) / SR
    w = sum(a * np.sin(2 * np.pi * f * t + p) for f, a, p in ((3100, 1, 0), (4270, 0.8, 1), (5630, 0.6, 2), (7350, 0.4, 3), (9100, 0.25, 4)))
    w += highpass(np.random.randn(n), 6000) * 0.5
    return w * np.exp(-t * 22) * vel * 0.12

def flute(f, dur, vel):
    n = int((dur + 0.4) * SR); t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.3)
    w = np.sin(2 * np.pi * f * vib * t) + 0.25 * np.sin(2 * np.pi * 2 * f * vib * t) + 0.08 * np.sin(2 * np.pi * 3 * f * vib * t)
    w += bandpass(np.random.randn(n), f * 0.8, f * 2.5) * 0.06
    return w * env(n, 0.07, 0.35) * vel * 0.4

def theremin(f, dur, vel):
    n = int((dur + 0.5) * SR); t = np.arange(n) / SR
    vib = 1 + 0.012 * np.sin(2 * np.pi * 5.8 * t)
    w = np.sin(2 * np.pi * np.cumsum(f * vib) / SR) + 0.2 * np.sin(2 * np.pi * np.cumsum(2 * f * vib) / SR)
    return w * env(n, 0.18, 0.45) * vel * 0.3

def noel():
    """Veillée de neige : boîte à musique, grelots, cloches et chœur doux, en majeur."""
    rng = np.random.default_rng(1225); np.random.seed(1225)
    T = Track(92, 16); root = 53; sc = "major"; prog = [0, 5, 3, 4, 0, 2, 3, 4]
    for b in range(16):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.2, 1700, attack=0.9, kind="sine"), 0, 0.7)
        if b >= 8:
            T.add(t0, choir([mtof(n) for n in chord(root, sc, c)], T.bar, 0.07, "o"), 0, 0.8)
        T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar * 0.8, 0.28), 0, 0.2)
        ns = chord(root + 12, sc, c, 4)
        for i in range(8):                       # arpège de boîte à musique
            T.add(t0 + i * T.spb / 2, musicbox(mtof(ns[[0, 2, 1, 3, 2, 1, 3, 2][i]]), 0.4, 0.17), -0.35 + 0.1 * (i % 4), 0.55)
        for i in range(8):                       # grelots sur les croches, accent sur les temps
            T.add(t0 + i * T.spb / 2, jingle(1.0 if i % 2 == 0 else 0.55), 0.5 if i % 2 else -0.5, 0.35)
        if b % 2 == 0:
            T.add(t0, bell(mtof(deg(root + 12, sc, c)), 3, 0.3), 0.25, 0.8)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 16, T.spb, R_MID, density=0.85):
        T.add(t, musicbox(mtof(m + 12), d, v * 0.3), 0.1, 0.5)
        T.add(t, piano(mtof(m), d, v * 0.3), -0.1, 0.5)
    T.render(f"{OUT}/noel_veillee_de_neige.ogg", rev_time=4.0)

def halloween():
    """La Veillée des Ombres : orgue, pizzicati sur la pointe des pieds, thérémine, en mineur harmonique."""
    rng = np.random.default_rng(1031); np.random.seed(1031)
    T = Track(78, 16); root = 50; sc = "harm"; prog = [0, 5, 3, 4, 0, 1, 3, 4]
    for b in range(0, 16, 2):
        T.add(b * T.bar, drone(mtof(root - 24), 2 * T.bar, 0.3), 0, 0.3)
    for b in range(16):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, organ([mtof(n) for n in chord(root, sc, c, 4)], T.bar, 0.45), -0.2, 0.75)
        for beat in range(4):                    # basse qui marche : fondamentale / quinte
            T.add(t0 + beat * T.spb, pluck(mtof(deg(root - 12, sc, c + (0 if beat % 2 == 0 else 4))), 0.3, 0.42, 0.25), 0, 0.3)
            T.add(t0 + (beat + 0.5) * T.spb, pluck(mtof(chord(root + 12, sc, c)[beat % 3]), 0.18, 0.2, 0.7), 0.5 if beat % 2 else -0.5, 0.5)
        if b % 4 == 3:
            T.add(t0 + 2 * T.spb, bell(mtof(deg(root, sc, 4)), 3, 0.3), 0.3, 0.85)
        if b % 2 == 1:
            T.add(t0 + 3 * T.spb, tom(70, 0.25), -0.3, 0.6)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 16, T.spb, R_SLOW, density=0.9):
        if t >= 2 * T.bar:
            T.add(t, theremin(mtof(m + 12), d, v * 0.4), 0.15, 0.7)
        T.add(t, musicbox(mtof(m) * 1.004, d, v * 0.22), -0.3, 0.6)
    T.render(f"{OUT}/veillee_des_ombres.ogg", rev_time=4.5)

def valentin():
    """Valse des lanternes : piano, harpe pincée, nappes chaudes, cloches légères."""
    rng = np.random.default_rng(214); np.random.seed(214)
    T = Track(72, 16); root = 55; sc = "major"; prog = [0, 5, 1, 4, 3, 5, 1, 4]
    for b in range(16):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.22, 1500, attack=1.3, kind="sine"), 0, 0.75)
        T.add(t0, bass(mtof(deg(root - 24, sc, c)), T.bar * 0.9, 0.26), 0, 0.2)
        ns = chord(root, sc, c, 4)
        order = [0, 1, 2, 3, 2, 1, 2, 3]
        for i in range(8):                       # harpe
            T.add(t0 + i * T.spb / 2, pluck(mtof(ns[order[i]]), 0.5, 0.2, 0.45), 0.6 * np.sin(i * 0.8), 0.6)
        if b % 4 == 0:
            T.add(t0, bell(mtof(deg(root + 24, sc, c + 2)), 3, 0.2), -0.3, 0.85)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 16, T.spb, R_SLOW, density=0.95):
        T.add(t, piano(mtof(m), d, v * 0.55), 0.1, 0.55)
        if t >= 8 * T.bar:                       # reprise : doublée à l'octave
            T.add(t, musicbox(mtof(m + 12), d, v * 0.16), -0.2, 0.6)
    T.render(f"{OUT}/valse_des_lanternes.ogg", rev_time=4.5)

def paques():
    """Matin de printemps : flûte, cordes pincées et boîte à musique, vif et clair."""
    rng = np.random.default_rng(405); np.random.seed(405)
    T = Track(104, 16); root = 57; sc = "major"; prog = [0, 3, 4, 0, 5, 3, 1, 4]
    for b in range(16):
        c = prog[b % 8]; t0 = b * T.bar
        T.add(t0, pad([mtof(n) for n in chord(root - 12, sc, c, 4)], T.bar, 0.15, 2000, attack=0.5, kind="sine"), 0, 0.65)
        for beat in range(4):
            T.add(t0 + beat * T.spb, bass(mtof(deg(root - 24, sc, c + (0 if beat % 2 == 0 else 4))), T.spb * 0.55, 0.26), 0, 0.15)
        ns = chord(root + 12, sc, c, 4)
        for i in range(8):
            if rng.random() < 0.85:
                T.add(t0 + i * T.spb / 2, pluck(mtof(ns[rng.integers(4)]), 0.22, 0.2, 0.85), rng.uniform(-0.6, 0.6), 0.45)
        for i in (1, 3):                         # petits contretemps de boîte à musique
            T.add(t0 + (i + 0.5) * T.spb, musicbox(mtof(ns[(b + i) % 4] + 12), 0.3, 0.14), 0.4, 0.5)
        if b % 4 == 3:
            T.add(t0 + 3 * T.spb, bell(mtof(deg(root + 24, sc, c + 4)), 1, 0.2), 0.4, 0.7)
    for (t, d, m, v) in melody(rng, root + 12, sc, prog, 16, T.spb, R_MID, density=0.8):
        if t >= 2 * T.bar:
            T.add(t, flute(mtof(m + 12), d, v * 0.5), 0.15, 0.5)
    T.render(f"{OUT}/matin_de_printemps.ogg", rev_time=2.8)

jobs = {"noel": noel, "halloween": halloween, "valentin": valentin, "paques": paques}
for k in (sys.argv[2:] or jobs):
    jobs[k]()

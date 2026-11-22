# Liste des succès à saisir dans Steamworks (Stats & Achievements), dans les 4 langues.
# Usage : python3 tools/steam_achievements.py > docs/steam/achievements.md
import re, ast, os
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(root, "scripts/achievements.gd"), encoding="utf-8").read()
block = src[src.index("const LIST := ["):]
block = block[block.index("["):block.index("\n]\n") + 2]
items = ast.literal_eval(block.replace("\t", ""))
ns = {}
src_t = open(os.path.join(root, "tools/translations.py"), encoding="utf-8").read()
exec(src_t[:src_t.index("def gd(s):")], ns)
T = None
for k, v in ns.items():
    if isinstance(v, dict) and "Annuler" in v:
        T = v
def tr(s):
    t = T.get(s) if T else None
    return t if t else ("?", "?", "?")
print("# Succès Steam\n")
print("À créer dans Steamworks → Stats & Achievements, avec le **nom d'API** exact (le jeu les débloque via")
print("`scripts/steam_bridge.gd`). Tous sont visibles (pas cachés) et sans statistique liée.\n")
print("| Nom d'API | FR | EN | ES | DE |")
print("|---|---|---|---|---|")
for id, name, desc in items:
    n, d = tr(name), tr(desc)
    cells = [f"**{name}** — {desc}"] + [f"**{n[i]}** — {d[i]}" for i in range(3)]
    print(f"| `ACH_{id.upper()}` | " + " | ".join(c.replace("|", "/") for c in cells) + " |")

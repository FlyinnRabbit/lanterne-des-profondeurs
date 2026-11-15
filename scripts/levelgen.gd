extends RefCounted
# Générateur de niveaux façon « Dead Cells » : un niveau = suite de salles tirées au hasard
# selon le biome, assemblées de gauche à droite. Toutes les salles laissent un passage au
# niveau du sol (rangée F) à leurs bords, et respectent les capacités du héros :
# saut ≈ 4 cases de haut / 6 de long, Ruée ≈ 9-10 cases.

const H := 26        # hauteur de la carte (cases)
const CEIL := 3      # rangées 0..CEIL = plafond
const F := 20        # rangée du sol (surface)

var rng := RandomNumberGenerator.new()
var g := []          # grille [y][x] de caractères
var W := 0
var ground_spots := []
var air_spots := []
var item_spots := []

func _grid(w: int) -> void:
	W = w
	g = []
	for y in H:
		var row := []
		row.resize(w)
		row.fill(".")
		g.append(row)

func fill(x0: int, y0: int, x1: int, y1: int, c: String) -> void:
	for y in range(maxi(y0, 0), mini(y1, H - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, W - 1) + 1):
			g[y][x] = c

func put(x: int, y: int, c: String) -> void:
	if x >= 0 and x < W and y >= 0 and y < H:
		g[y][x] = c

func _pick(weights: Dictionary, avoid := "") -> String:
	var total := 0.0
	for k in weights:
		if k != avoid:
			total += float(weights[k])
	var r := rng.randf() * total
	for k in weights:
		if k == avoid:
			continue
		r -= float(weights[k])
		if r <= 0.0:
			return k
	return weights.keys()[0]

func _width(kind: String) -> int:
	match kind:
		"start": return 14
		"exit": return 10
		"shrine": return 16
		"boss": return 40
		"flat": return rng.randi_range(12, 18)
		"platforms": return rng.randi_range(17, 22)
		"pit": return rng.randi_range(10, 13)
		"wide_gap": return rng.randi_range(14, 15)
		"pillars": return rng.randi_range(15, 22)
		"hill": return rng.randi_range(16, 22)
		"wall": return 18
		"well": return rng.randi_range(12, 16)
		"corridor": return rng.randi_range(14, 22)
		"bridge": return rng.randi_range(16, 24)
		"arena": return rng.randi_range(22, 28)
		"rest": return 12
		"islands": return rng.randi_range(16, 24)
		"zigzag": return rng.randi_range(16, 18)
		"split": return rng.randi_range(20, 26)
		"moving": return rng.randi_range(17, 20)
		"crumble": return rng.randi_range(14, 20)
		"cave": return rng.randi_range(18, 26)
		"blades": return rng.randi_range(16, 22)
	return 12

# hauteur de sol minimale (rangée la plus haute) selon la salle, pour garder de la place au-dessus
func _fmin(kind: String) -> int:
	match kind:
		"wall", "zigzag": return 17
		"platforms", "split", "blades", "cave": return 16
		"hill": return 15
	return 14

# salles qui gardent la hauteur précédente et interdisent de monter juste après (plafond bas)
const LOW_CEIL := ["corridor", "arena", "cave"]

var f := F           # rangée du sol de la salle en cours (varie d'une salle à l'autre)
var trap_p := 0.3    # probabilité d'ajouter des pièges dans une salle

func _trap() -> bool:
	return rng.randf() < trap_p

# ---------------------------------------------------------------- salles
func _chunk(kind: String, x0: int, w: int, boss_char: String) -> void:
	var x1 := x0 + w - 1
	fill(x0, f, x1, H - 1, "#")
	match kind:
		"start":
			put(x0 + 3, f - 1, "P")
			put(x0 + 8, f - 1, "B")
		"rest":
			put(x0 + 6, f - 1, "B")
		"exit":
			put(x0 + 6, f - 1, "O")
		"shrine":
			put(x0 + 8, f - 1, "E")
		"flat":
			var bumps := rng.randi_range(0, 2)
			for i in bumps:
				var a := x0 + rng.randi_range(3, w - 7)
				fill(a, f - rng.randi_range(1, 3), a + rng.randi_range(1, 3), f - 1, "#")
			if _trap():
				# totem à fléchettes au bord : il faut s'accroupir ou parer
				var side := rng.randi_range(0, 1)
				put(x0 + 1 if side == 0 else x1 - 1, f - 1, "Z")
			ground_spots.append(Vector2i(x0 + w / 3, f - 1))
			ground_spots.append(Vector2i(x0 + 2 * w / 3, f - 1))
			air_spots.append(Vector2i(x0 + w / 2, f - 7))
		"platforms":
			# plateformes en escalier, hauteurs et longueurs tirées au hasard
			var px := x0 + 2
			var h := 0
			var n := 0
			while px < x1 - 4 and n < 4:
				h = clampi(h + rng.randi_range(2, 3) * (1 if (rng.randf() < 0.7 or h < 5) else -1), 3, mini(9, f - CEIL - 4))
				var pw := rng.randi_range(3, 5)
				fill(px, f - h, mini(px + pw - 1, x1 - 1), f - h, "#")
				if n == 1:
					item_spots.append(Vector2i(px + 1, f - h - 1))
				if rng.randf() < 0.5:
					ground_spots.append(Vector2i(px + 1, f - h - 1))
				px += pw + rng.randi_range(1, 2)
				n += 1
			ground_spots.append(Vector2i(x0 + w / 2, f - 1))
			air_spots.append(Vector2i(x0 + w - 4, f - 9))
		"pit":
			var gap := rng.randi_range(3, 6)
			var a := x0 + rng.randi_range(2, w - gap - 2)
			fill(a, f, a + gap - 1, f + 1, ".")
			fill(a, f + 2, a + gap - 1, f + 2, "^")
			if gap >= 5 and rng.randf() < 0.5:
				put(a + gap / 2, f - 2, "#")   # petit appui au milieu
			air_spots.append(Vector2i(a + gap / 2, f - 6))
			ground_spots.append(Vector2i(x1 - 1, f - 1))
		"wide_gap":
			var gap := rng.randi_range(7, 8)   # demande la Ruée
			var a := x0 + rng.randi_range(2, 4)
			fill(a, f, a + gap - 1, f + 1, ".")
			fill(a, f + 2, a + gap - 1, f + 2, "^")
			air_spots.append(Vector2i(a + gap / 2, f - 7))
		"pillars":
			fill(x0 + 2, f, x1 - 2, f + 1, ".")
			fill(x0 + 2, f + 2, x1 - 2, f + 2, "^")
			var px := x0 + 4
			var top := f
			while px + 1 <= x1 - 5:
				top = clampi(top + rng.randi_range(-2, 2), f - 3, f)
				var pw := rng.randi_range(1, 3)
				fill(px, top, px + pw - 1, f + 2, "#")
				if rng.randf() < 0.3:
					ground_spots.append(Vector2i(px, top - 1))
				px += pw + rng.randi_range(2, 4)
			air_spots.append(Vector2i(x0 + w / 2, f - 7))
		"hill":
			var steps := rng.randi_range(1, 3)
			var inset := 3
			for i in steps:
				if x0 + inset + 2 > x1 - inset - 2:
					break
				fill(x0 + inset, f - 3 * (i + 1), x1 - inset, f - 3 * i - 1, "#")
				inset += rng.randi_range(2, 4)
			ground_spots.append(Vector2i(x0 + w / 2, f - 3 * steps - 1))
			ground_spots.append(Vector2i(x0 + 4, f - 4))
			item_spots.append(Vector2i(x0 + w / 2 + 1, f - 3 * steps - 1))
			if _trap():
				put(x0 + w / 2, CEIL + 1, "V")
		"wall":
			var m := x0 + 9
			fill(m, f - 9, m + 1, f - 1, "#")
			fill(x0 + 1, f - 4, x0 + 3, f - 4, "#")
			fill(x0 + 5, f - 8, m - 1, f - 8, "#")
			item_spots.append(Vector2i(m, f - 10))
			ground_spots.append(Vector2i(x0 + 13, f - 1))
			air_spots.append(Vector2i(x0 + 13, f - 8))
		"well":
			var dep := rng.randi_range(2, 3)
			fill(x0 + 3, f, x1 - 3, f + dep, ".")
			fill(x1 - 5, f + dep - 1, x1 - 4, f + dep, "#")
			var sx := x0 + 3 + (w - 6) / 2
			fill(sx - 1, f + dep, sx, f + dep, "^")
			ground_spots.append(Vector2i(x0 + 4, f + dep))
			item_spots.append(Vector2i(x0 + 4, f + dep))
		"corridor":
			var ch := rng.randi_range(5, 6)
			fill(x0, CEIL + 1, x1, f - ch, "#")
			if _trap():
				for vx in range(x0 + 3, x1 - 2, rng.randi_range(4, 6)):
					put(vx, f - ch + 1, "V")
			air_spots.append(Vector2i(x0 + w / 3, f - 3))
			air_spots.append(Vector2i(x0 + 2 * w / 3, f - 3))
			ground_spots.append(Vector2i(x0 + w / 2, f - 1))
		"bridge":
			fill(x0 + 2, f, x1 - 2, f + 1, ".")
			fill(x0 + 2, f + 2, x1 - 2, f + 2, "^")
			var bx := x0 + 3
			while bx <= x1 - 4:
				var bw := rng.randi_range(2, 4)
				fill(bx, f - rng.randi_range(0, 1), mini(bx + bw - 1, x1 - 3), f - rng.randi_range(0, 1) * 0, "#")
				bx += bw + rng.randi_range(2, 3)
			air_spots.append(Vector2i(x0 + w / 2, f - 6))
			ground_spots.append(Vector2i(x0 + 4, f - 1))
		"arena":
			fill(x0 + 1, CEIL + 1, x1 - 1, f - 11, "#")
			if rng.randf() < 0.5:
				fill(x0 + w / 2 - 2, f - 4, x0 + w / 2 + 2, f - 4, "#")
			for i in 3:
				ground_spots.append(Vector2i(x0 + 5 + i * (w - 10) / 2, f - 1))
			air_spots.append(Vector2i(x0 + w / 2, f - 7))
		"islands":
			# îlots flottants au-dessus d'une fosse à pics
			fill(x0 + 2, f, x1 - 2, f + 1, ".")
			fill(x0 + 2, f + 2, x1 - 2, f + 2, "^")
			var ix := x0 + rng.randi_range(3, 4)
			var top := f
			while ix <= x1 - 5:
				top = clampi(top + rng.randi_range(-2, 2), f - 4, f)
				var iw := rng.randi_range(2, 3)
				fill(ix, top, ix + iw - 1, top, "#")
				if rng.randf() < 0.35:
					air_spots.append(Vector2i(ix + 1, top - 4))
				if rng.randf() < 0.2:
					item_spots.append(Vector2i(ix, top - 1))
				ix += iw + rng.randi_range(2, 4)
		"zigzag":
			# puits vertical : corniches en zigzag jusqu'à un trésor en hauteur
			var left := true
			var lvls := [4, 8, 11]
			for i in lvls.size():
				var ly: int = f - lvls[i]
				if left:
					fill(x0 + 2, ly, x0 + 7, ly, "#")
				else:
					fill(x1 - 7, ly, x1 - 2, ly, "#")
				left = not left
			item_spots.append(Vector2i(x0 + 4, f - 12))
			air_spots.append(Vector2i(x0 + w / 2, f - 6))
			ground_spots.append(Vector2i(x0 + w / 2, f - 1))
			if _trap():
				put(x0 + w / 2, CEIL + 1, "V")
		"split":
			# deux chemins : le haut (corniche, trésor) et le bas (fléchettes à hauteur de tête)
			fill(x0 + 5, f - 5, x1 - 4, f - 5, "#")
			fill(x0 + 1, f - 3, x0 + 2, f - 1, "#")
			put(x1 - 2, f - 1, "Z")
			item_spots.append(Vector2i(x1 - 6, f - 6))
			ground_spots.append(Vector2i(x0 + w / 2, f - 6))
			ground_spots.append(Vector2i(x0 + w / 2 + 3, f - 1))
		"moving":
			# grand gouffre : une plateforme mobile fait l'aller-retour
			var a := x0 + 2
			var b := x1 - 2
			fill(a, f, b, f + 1, ".")
			fill(a, f + 2, b, f + 2, "^")
			put(a, f, "H")
			air_spots.append(Vector2i(x0 + w / 2, f - 6))
		"crumble":
			# pont de blocs fragiles au-dessus des pics
			var a := x0 + 3
			var b := x1 - 3
			fill(a, f, b, f + 1, ".")
			fill(a, f + 2, b, f + 2, "^")
			fill(a, f, b, f, "C")
			air_spots.append(Vector2i(x0 + w / 2, f - 6))
		"cave":
			# grotte basse : stalactites qui tombent et totem à fléchettes
			fill(x0, CEIL + 1, x1, f - 7, "#")
			for vx in range(x0 + 3, x1 - 2, rng.randi_range(3, 5)):
				if rng.randf() < 0.7:
					put(vx, f - 6, "V")
			if rng.randf() < 0.6:
				put(x1 - 1, f - 1, "Z")
			ground_spots.append(Vector2i(x0 + w / 3, f - 1))
			air_spots.append(Vector2i(x0 + 2 * w / 3, f - 3))
		"blades":
			# lames-pendules suspendues à des colonnes : passer accroupi au point bas ou entre deux passages
			var bx := x0 + rng.randi_range(4, 5)
			while bx <= x1 - 4:
				fill(bx, CEIL + 1, bx, f - 7, "#")
				put(bx, f - 6, "U")
				bx += rng.randi_range(7, 9)
			ground_spots.append(Vector2i(x0 + 2, f - 1))
			air_spots.append(Vector2i(x0 + w / 2, f - 8))
		"boss":
			fill(x0 + 3, CEIL + 1, x1 - 3, f - 13, "#")
			for y in range(f - 12, f):
				put(x0 + 2, y, "Y")
				put(x1 - 2, y, "X")
			for sx2 in [x0 + 8, x0 + 16, x0 + 25, x0 + 32]:
				put(sx2, f - 12, "#")
			put(x0 + 30, f - 1, boss_char)

# mélange reproductible (même graine = même niveau)
func _shuffled(a: Array) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = b[i]
		b[i] = b[j]
		b[j] = tmp
	return b

# ---------------------------------------------------------------- génération
# Renvoie la carte (tableau de chaînes) d'un niveau.
#  depth : 1..N (difficulté)   boss : "" / "K" / "Q"   final : sanctuaire à la fin
func generate(biome: Dictionary, seed_value: int, depth: int, boss: String, final: bool, diff: Dictionary = {}) -> Array:
	rng.seed = seed_value
	ground_spots.clear()
	air_spots.clear()
	item_spots.clear()
	trap_p = clampf(0.25 + depth * 0.08, 0.25, 0.75)
	var kinds := ["start"]
	var n := mini(6 + depth, 11)
	# toutes les salles possibles un peu partout, celles du biome bien plus souvent
	var weights: Dictionary = {}
	for k in ["flat", "platforms", "pit", "hill", "pillars", "bridge", "islands", "zigzag", "split", "moving", "crumble", "cave", "blades"]:
		weights[k] = 0.35
	for k in biome["chunks"]:
		weights[k] = float(weights.get(k, 0.0)) + float(biome["chunks"][k])
	var recent := []
	for i in n:
		if i == n / 2:
			kinds.append("rest")   # banc à mi-parcours
		var wsel := weights.duplicate()
		for r in recent:
			wsel.erase(r)            # pas deux fois la même salle de suite (ni à une salle d'écart)
		var k := _pick(wsel)
		kinds.append(k)
		recent.append(k)
		if recent.size() > 2:
			recent.pop_front()
	if boss != "":
		kinds.append("boss")
	kinds.append("shrine" if final else "exit")
	var widths := []
	var total := 2
	for k in kinds:
		var w := _width(k)
		widths.append(w)
		total += w
	_grid(total)
	var x := 1
	f = F
	var no_rise := false
	for i in kinds.size():
		var k: String = kinds[i]
		var prev := f
		if k == "start":
			f = F
		elif k == "boss":
			f = F
		elif k in LOW_CEIL or k in ["exit", "shrine"]:
			pass
		else:
			# relief : le sol monte (≤ 3 cases, franchissable d'un saut) ou descend
			var d: int = [-3, -2, -1, 0, 0, 1, 2, 3][rng.randi_range(0, 7)]
			if no_rise and d < 0:
				d = -d
			f = clampi(prev + d, _fmin(k), 21)
		if no_rise and f < prev:
			f = prev
		if prev - f > 3:
			f = prev - 3
		no_rise = k in LOW_CEIL
		_chunk(k, x, widths[i], boss)
		x += widths[i]
	# plafond, murs, stalactites
	fill(0, 0, W - 1, CEIL, "#")
	fill(0, 0, 0, H - 1, "#")
	fill(W - 1, 0, W - 1, H - 1, "#")
	for xx in range(2, W - 2):
		if g[CEIL + 1][xx] == "." and g[CEIL + 2][xx] == "." and rng.randf() < 0.12:
			put(xx, CEIL + 1, "#")
	# ennemis (pas trop près du départ, ni dans l'arène)
	var count := int(round((4 + depth * 2) * float(diff.get("count", 1.0))))
	# ennemis du biome + sauteurs (h) et gardes à bouclier (g), plus fréquents en profondeur et en difficulté
	var ew: Dictionary = biome["enemies"].duplicate()
	var variety: float = float(diff.get("variety", 1.0)) * (0.4 + depth * 0.3)
	ew["h"] = variety
	ew["g"] = variety * 0.8
	# nouveaux ennemis : un peu partout, et beaucoup plus dans les biomes qui les mettent en avant
	var extras: Dictionary = biome.get("extras", {})
	for k in ["b", "w", "l", "r"]:
		ew[k] = variety * 0.5 + float(extras.get(k, 0.0))
	var ground := _shuffled(ground_spots.filter(func(p): return p.x > 18))
	var air := _shuffled(air_spots.filter(func(p): return p.x > 18))
	for i in count:
		var k := _pick(ew)
		if k in ["f", "w", "r"] and not air.is_empty():
			var p: Vector2i = air.pop_back()
			if g[p.y][p.x] == ".":
				put(p.x, p.y, k)
		elif not ground.is_empty():
			var p: Vector2i = ground.pop_back()
			if g[p.y][p.x] == "." and g[p.y + 1][p.x] == "#":
				put(p.x, p.y, k if k in ["s", "h", "g", "b", "l"] else "c")
	# emblèmes (« * ») et encoche
	item_spots = _shuffled(item_spots)
	var items := 2 if depth <= 3 else 1
	for i in mini(items, item_spots.size()):
		var p: Vector2i = item_spots[i]
		if g[p.y][p.x] == ".":
			put(p.x, p.y, "*")
	if item_spots.size() > items and rng.randf() < 0.45:
		var p: Vector2i = item_spots[items]
		if g[p.y][p.x] == ".":
			put(p.x, p.y, "N")
	var out := []
	for row in g:
		out.append("".join(PackedStringArray(row)))
	return out

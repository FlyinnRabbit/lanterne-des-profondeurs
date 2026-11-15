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
	return 12

# ---------------------------------------------------------------- salles
func _chunk(kind: String, x0: int, w: int, boss_char: String) -> void:
	var x1 := x0 + w - 1
	fill(x0, F, x1, H - 1, "#")
	match kind:
		"start":
			put(x0 + 3, F - 1, "P")
			put(x0 + 8, F - 1, "B")
		"rest":
			put(x0 + 6, F - 1, "B")
		"exit":
			put(x0 + 6, F - 1, "O")
		"shrine":
			put(x0 + 8, F - 1, "E")
		"flat":
			if rng.randf() < 0.6:
				var a := x0 + rng.randi_range(3, w - 7)
				fill(a, F - rng.randi_range(1, 2), a + 3, F - 1, "#")
			ground_spots.append(Vector2i(x0 + w / 3, F - 1))
			ground_spots.append(Vector2i(x0 + 2 * w / 3, F - 1))
			air_spots.append(Vector2i(x0 + w / 2, F - 7))
		"platforms":
			var p1 := x0 + 2
			fill(p1, F - 4, p1 + 4, F - 4, "#")
			fill(p1 + 6, F - 8, p1 + 10, F - 8, "#")
			fill(mini(p1 + 12, x1 - 4), F - 5, mini(p1 + 15, x1 - 1), F - 5, "#")
			item_spots.append(Vector2i(p1 + 8, F - 9))
			ground_spots.append(Vector2i(x0 + w / 2, F - 1))
			ground_spots.append(Vector2i(p1 + 2, F - 5))
			air_spots.append(Vector2i(p1 + 13, F - 10))
		"pit":
			var gap := rng.randi_range(3, 6)
			var a := x0 + (w - gap) / 2
			fill(a, F, a + gap - 1, F + 1, ".")
			fill(a, F + 2, a + gap - 1, F + 2, "^")
			air_spots.append(Vector2i(a + gap / 2, F - 6))
			ground_spots.append(Vector2i(x1 - 1, F - 1))
		"wide_gap":
			var gap := rng.randi_range(7, 8)   # demande la Ruée
			var a := x0 + 3
			fill(a, F, a + gap - 1, F + 1, ".")
			fill(a, F + 2, a + gap - 1, F + 2, "^")
			air_spots.append(Vector2i(a + gap / 2, F - 7))
		"pillars":
			fill(x0 + 2, F, x1 - 2, F + 1, ".")
			fill(x0 + 2, F + 2, x1 - 2, F + 2, "^")
			var px := x0 + 4
			while px + 1 <= x1 - 5:
				var top := F - rng.randi_range(0, 2)
				fill(px, top, px + 1, F + 2, "#")
				if rng.randf() < 0.3:
					ground_spots.append(Vector2i(px, top - 1))
				px += 5
			air_spots.append(Vector2i(x0 + w / 2, F - 7))
		"hill":
			fill(x0 + 3, F - 3, x1 - 3, F - 1, "#")
			fill(x0 + 6, F - 6, x1 - 6, F - 4, "#")
			ground_spots.append(Vector2i(x0 + w / 2, F - 7))
			ground_spots.append(Vector2i(x0 + 4, F - 4))
			item_spots.append(Vector2i(x0 + w / 2 + 1, F - 7))
		"wall":
			var m := x0 + 9
			fill(m, F - 9, m + 1, F - 1, "#")
			fill(x0 + 1, F - 4, x0 + 3, F - 4, "#")
			fill(x0 + 5, F - 8, m - 1, F - 8, "#")
			item_spots.append(Vector2i(m, F - 10))
			ground_spots.append(Vector2i(x0 + 13, F - 1))
			air_spots.append(Vector2i(x0 + 13, F - 8))
		"well":
			fill(x0 + 3, F, x1 - 3, F + 3, ".")
			fill(x1 - 5, F + 2, x1 - 4, F + 3, "#")
			var sx := x0 + 3 + (w - 6) / 2
			fill(sx - 1, F + 3, sx, F + 3, "^")
			ground_spots.append(Vector2i(x0 + 4, F + 3))
			item_spots.append(Vector2i(x0 + 4, F + 3))
		"corridor":
			fill(x0, CEIL + 1, x1, F - 6, "#")
			air_spots.append(Vector2i(x0 + w / 3, F - 3))
			air_spots.append(Vector2i(x0 + 2 * w / 3, F - 3))
			ground_spots.append(Vector2i(x0 + w / 2, F - 1))
		"bridge":
			fill(x0 + 2, F, x1 - 2, F + 1, ".")
			fill(x0 + 2, F + 2, x1 - 2, F + 2, "^")
			var bx := x0 + 3
			while bx <= x1 - 4:
				fill(bx, F, mini(bx + 2, x1 - 3), F, "#")
				bx += 5
			air_spots.append(Vector2i(x0 + w / 2, F - 6))
			ground_spots.append(Vector2i(x0 + 4, F - 1))
		"arena":
			fill(x0 + 1, CEIL + 1, x1 - 1, F - 11, "#")
			for i in 3:
				ground_spots.append(Vector2i(x0 + 5 + i * (w - 10) / 2, F - 1))
			air_spots.append(Vector2i(x0 + w / 2, F - 7))
		"boss":
			fill(x0 + 3, CEIL + 1, x1 - 3, F - 13, "#")
			for y in range(F - 12, F):
				put(x0 + 2, y, "Y")
				put(x1 - 2, y, "X")
			for sx2 in [x0 + 8, x0 + 16, x0 + 25, x0 + 32]:
				put(sx2, F - 12, "#")
			put(x0 + 30, F - 1, boss_char)

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
	var kinds := ["start"]
	var n := mini(6 + depth, 11)
	var last := ""
	for i in n:
		if i == n / 2:
			kinds.append("rest")   # banc à mi-parcours
		var k := _pick(biome["chunks"], last)
		kinds.append(k)
		last = k
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
	for i in kinds.size():
		_chunk(kinds[i], x, widths[i], boss)
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
	var ground := _shuffled(ground_spots.filter(func(p): return p.x > 18))
	var air := _shuffled(air_spots.filter(func(p): return p.x > 18))
	for i in count:
		var k := _pick(ew)
		if k == "f" and not air.is_empty():
			var p: Vector2i = air.pop_back()
			if g[p.y][p.x] == ".":
				put(p.x, p.y, "f")
		elif not ground.is_empty():
			var p: Vector2i = ground.pop_back()
			if g[p.y][p.x] == "." and g[p.y + 1][p.x] == "#":
				put(p.x, p.y, k if k in ["s", "h", "g"] else "c")
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

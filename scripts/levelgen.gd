extends RefCounted
# Générateur de niveaux façon « Dead Cells » : un niveau = suite de salles tirées au hasard
# selon le biome, assemblées de gauche à droite. Toutes les salles laissent un passage au
# niveau du sol (rangée F) à leurs bords, et respectent les capacités du héros :
# saut ≈ 4 cases de haut / 6 de long, Ruée ≈ 9-10 cases.

# hauteur d'une bande de niveau (cases) : 26 sans grottes, 40 avec les grottes sous le chemin
var H := 26
const BAND_H := 40
# biomes dont les niveaux descendent par strates (les autres : chemin horizontal + grottes)
const STRATA := ["profondeurs", "cristal", "glace", "forge"]
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
		"treasure": return rng.randi_range(14, 18)
		"challenge": return 12
		"altar": return rng.randi_range(22, 26)
		"grotto": return rng.randi_range(22, 26)
		"drop": return 12
		"landing": return 14
		"landing_rest": return 16
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
var challenge_x := -1
var biome_id := ""
var cave_spots := []     # ennemis garantis dans les grottes
var mark := {}           # repères d'une bande : trou de chute, point d'atterrissage
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
			if rng.randf() < 0.45:
				put(x0 + 10, f - 1, "M")   # marchand ambulant
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
				# totem à fléchettes au bord : il faut s'accroupir ou parer (et moins d'ennemis)
				var side := rng.randi_range(0, 1)
				put(x0 + 1 if side == 0 else x1 - 1, f - 1, "Z")
				ground_spots.append(Vector2i(x0 + w / 2, f - 1))
			else:
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
			else:
				ground_spots.append(Vector2i(x0 + w / 3, f - 1))
			air_spots.append(Vector2i(x0 + 2 * w / 3, f - 3))
		"blades":
			# lames-pendules suspendues à des colonnes : passer accroupi au point bas ou entre deux passages
			var bx := x0 + rng.randi_range(4, 5)
			while bx <= x1 - 4:
				fill(bx, CEIL + 1, bx, f - 7, "#")
				put(bx, f - 6, "U")
				bx += rng.randi_range(7, 9)
			air_spots.append(Vector2i(x0 + w / 2, f - 8))
		"treasure":
			# salle au trésor : cachette sous un sol fissuré (le casser à coups vers le bas)
			var a := x0 + w / 2 - 2
			fill(a, f, a + 4, f + 2, ".")
			fill(a, f, a + 4, f, "W")
			put(a + 2, f + 2, "$")
			ground_spots.append(Vector2i(x1 - 2, f - 1))
		"challenge":
			# défi chronométré : la stèle lance le compte à rebours, le drapeau est plus loin
			put(x0 + 4, f - 1, "S")
			challenge_x = x0 + 4
		"altar":
			# arène d'élites : l'autel invoque trois élites, récompense à la clé
			fill(x0 + 1, CEIL + 1, x1 - 1, f - 11, "#")
			put(x0 + w / 2, f - 1, "R")
		"grotto":
			_grotto(x0, x1)
		"drop":
			# fin de strate : un large puits s'ouvre dans le sol et mène à la strate du dessous
			var hx := x0 + 6
			fill(hx - 1, f, hx + 1, H - 1, ".")
			put(x0 + 3, f - 1, "u")          # point d'arrivée du treuil (côté d'où l'on vient)
			mark["drop_x"] = hx
			mark["drop_f"] = f
		"landing", "landing_rest":
			# arrivée d'une strate : on tombe du puits au centre de la salle
			mark["land_x"] = x0 + 6
			mark["land_f"] = f
			if kind == "landing_rest":
				put(x0 + 11, f - 1, "B")
				if rng.randf() < 0.45:
					put(x0 + 14, f - 1, "M")
		"boss":
			fill(x0 + 3, CEIL + 1, x1 - 3, f - 13, "#")
			for y in range(f - 12, f):
				put(x0 + 2, y, "Y")
				put(x1 - 2, y, "X")
			for sx2 in [x0 + 8, x0 + 16, x0 + 25, x0 + 32]:
				put(sx2, f - 12, "#")
			put(x0 + 30, f - 1, boss_char)

# Grotte sous le chemin : un puits de 2 cases descend vers une salle creusée dans la roche,
# aménagée selon le biome, avec un coffre, des ennemis, parfois un marchand ou un objet.
# Un treuil (« ~ » en bas, « u » en haut) remonte le héros au chemin.
func _grotto(x0: int, x1: int) -> void:
	var hx := x0 + 3
	var ct := f + 6           # plafond intérieur
	var cf := f + 16          # sol de la grotte (rangée pleine)
	fill(hx, f, hx + 1, ct - 1, ".")
	fill(x0 + 1, ct, x1 - 1, cf - 1, ".")
	put(hx, cf - 1, "~")
	put(x0 + 7, f - 1, "u")
	var a := x0 + 6           # zone aménageable (après le treuil)
	var b := x1 - 2
	var mid := (a + b) / 2
	match biome_id:
		"jardins":
			# champignons géants : pieds fins et chapeaux plats à hauteurs variées
			var mx := a + 1
			while mx <= b - 2:
				var top := cf - rng.randi_range(2, 4)
				fill(mx, top + 1, mx, cf - 1, "#")
				fill(mx - 1, top, mx + 1, top, "#")
				item_spots.append(Vector2i(mx, top - 1))
				mx += rng.randi_range(4, 6)
		"bibliotheque":
			# rayonnages : étagères sur deux niveaux, avec des trous pour sauter
			for row in [cf - 4, cf - 8]:
				var sx := a + rng.randi_range(0, 2)
				while sx <= b - 2:
					var sw := rng.randi_range(3, 5)
					fill(sx, row, mini(sx + sw - 1, b), row, "#")
					sx += sw + 2
			item_spots.append(Vector2i(mid, cf - 9))
		"ruche":
			# alvéoles : cloisons qui pendent du plafond et laissent passer en bas
			var cx := a + 4
			while cx <= b - 3:
				fill(cx, ct, cx, cf - 5, "#")
				fill(cx - 1, cf - 5, cx + 1, cf - 5, "#")
				cx += rng.randi_range(5, 6)
			item_spots.append(Vector2i(b - 1, cf - 1))
		"citadelle":
			# salle inondée : bassin de pics au milieu, îlots pour traverser
			fill(a + 2, cf - 1, b - 3, cf - 1, "^")
			var ix := a + 3
			while ix <= b - 4:
				fill(ix, cf - 3, ix + 1, cf - 3, "#")
				ix += rng.randi_range(3, 4)
			item_spots.append(Vector2i(mid, cf - 4))
		"ossuaire":
			# crypte : plafond bas soutenu par des piliers d'os, niches entre eux
			fill(x0 + 1, ct, x1 - 1, ct + 2, "#")
			fill(hx, ct, hx + 1, ct + 2, ".")
			var px := a + 3
			while px <= b - 2:
				fill(px, ct + 3, px, cf - 4, "#")
				px += rng.randi_range(4, 5)
			item_spots.append(Vector2i(a + 1, cf - 1))
		"cristal":
			# stalagmites de cristal de hauteurs variées
			var sx := a + 2
			while sx <= b - 2:
				var hgt := rng.randi_range(2, 4)
				fill(sx, cf - hgt, sx + rng.randi_range(0, 1), cf - 1, "#")
				sx += rng.randi_range(4, 6)
			item_spots.append(Vector2i(mid, cf - 6))
		"glace":
			# pont de glace fragile au-dessus d'une fosse
			fill(a + 2, cf - 1, b - 3, cf - 1, "^")
			fill(a + 2, cf - 3, b - 3, cf - 3, "C")
			item_spots.append(Vector2i(b - 1, cf - 1))
		"forge":
			# fosses de braises et passerelles
			for px in [a + 2, mid + 2]:
				fill(px, cf - 1, px + 2, cf - 1, "^")
				fill(px - 1, cf - 4, px + 3, cf - 4, "#")
			item_spots.append(Vector2i(mid, cf - 5))
		_:
			# puits secondaires et corniches
			fill(a + 3, cf - 1, a + 5, cf - 1, "^")
			fill(a + 2, cf - 4, a + 6, cf - 4, "#")
			fill(b - 6, cf - 6, b - 3, cf - 6, "#")
			item_spots.append(Vector2i(b - 4, cf - 7))
	# coffre au fond, marchand parfois, ennemis garantis
	put(b, cf - 1, "$")
	if rng.randf() < 0.3:
		put(x0 + 5, cf - 1, "M")
	cave_spots.append(Vector2i(mid, cf - 1))
	if rng.randf() < 0.6:
		cave_spots.append(Vector2i(b - 3, cf - 1))

# mélange reproductible (même graine = même niveau)
func _shuffled(a: Array) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = b[i]
		b[i] = b[j]
		b[j] = tmp
	return b

# Pose une suite de salles de gauche à droite dans une grille neuve (W x H).
func _build(kinds: Array, boss: String) -> void:
	mark = {}
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
	var boss_x0 := -1
	var boss_x1 := -1
	for i in kinds.size():
		var k: String = kinds[i]
		var prev := f
		if k in ["start", "boss", "landing", "landing_rest"]:
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
		if k == "boss":
			boss_x0 = x
			boss_x1 = x + widths[i]
		x += widths[i]
	# pas de totem à fléchettes près de l'arène du boss : ses tirs traversaient la salle du combat
	if boss_x0 >= 0:
		for gy in range(0, H):
			for gx in range(maxi(0, boss_x0 - 30), mini(W, boss_x1 + 30)):
				if g[gy][gx] == "Z":
					g[gy][gx] = "."

# Niveau en trois strates empilées : la 1re de gauche à droite, la 2e de droite à gauche
# (salles retournées), la 3e de nouveau vers la droite jusqu'à la sortie. Un large puits relie
# chaque strate à la suivante ; un treuil au pied du puits permet de remonter.
func _build_strata(chunks: Array, end_kinds: Array, boss: String) -> void:
	H = BAND_H
	var parts := [[], [], []]
	for i in chunks.size():
		parts[mini(i * 3 / maxi(chunks.size(), 1), 2)].append(chunks[i])
	# une grotte dans chacune des deux premières strates
	for bi in 2:
		parts[bi].insert(rng.randi_range(0, parts[bi].size()), "grotto")
	var band_kinds := [["start"] + parts[0] + ["drop"], ["landing_rest"] + parts[1] + ["drop"], ["landing"] + parts[2] + end_kinds]
	var bands := []
	for bi in 3:
		var kinds: Array = band_kinds[bi]
		# salles retournées dans la strate du milieu : pas de plateforme mobile (elle part vers la droite)
		if bi == 1:
			kinds = kinds.map(func(k): return "crumble" if k == "moving" else k)
		ground_spots.clear()
		air_spots.clear()
		cave_spots.clear()
		var items_before := item_spots.size()
		_build(kinds, boss if bi == 2 else "")
		var band := {"g": g, "w": W, "mark": mark.duplicate(), "ground": ground_spots.duplicate(),
			"air": air_spots.duplicate(), "items": item_spots.slice(items_before), "caves": cave_spots.duplicate(), "mirror": bi == 1}
		item_spots = item_spots.slice(0, items_before)
		bands.append(band)
	# retournement de la strate du milieu
	var mb: Dictionary = bands[1]
	var mw: int = mb["w"]
	for y in H:
		var row: Array = mb["g"][y]
		row.reverse()
	for key in ["ground", "air", "items", "caves"]:
		var arr: Array = mb[key]
		for i in arr.size():
			arr[i] = Vector2i(mw - 1 - arr[i].x, arr[i].y)
	for key in ["drop_x", "land_x"]:
		if mb["mark"].has(key):
			mb["mark"][key] = mw - 1 - int(mb["mark"][key])
	# alignement : chaque puits tombe au milieu de l'atterrissage de la strate suivante
	var ox := [0, 0, 0]
	ox[1] = int(bands[0]["mark"]["drop_x"]) - int(bands[1]["mark"]["land_x"])
	ox[2] = ox[1] + int(bands[1]["mark"]["drop_x"]) - int(bands[2]["mark"]["land_x"])
	var minx: int = mini(0, mini(ox[1], ox[2]))
	var maxx := 0
	for bi in 3:
		ox[bi] -= minx
		maxx = maxi(maxx, ox[bi] + int(bands[bi]["w"]))
	# grille finale : roche partout, puis on recopie les strates
	var total_h := H * 3
	var total_w := maxx
	var big := []
	for y in total_h:
		var row := []
		row.resize(total_w)
		row.fill("#")
		big.append(row)
	ground_spots.clear()
	air_spots.clear()
	cave_spots.clear()
	for bi in 3:
		var bd: Dictionary = bands[bi]
		var oy := bi * H
		for y in H:
			for x in int(bd["w"]):
				var c: String = bd["g"][y][x]
				# plafond de la strate et ses bords gauche/droit : roche
				big[oy + y][ox[bi] + x] = "#" if (y <= CEIL or x == 0 or x == int(bd["w"]) - 1) else c
		for key in ["ground", "air", "caves"]:
			for p in bd[key]:
				var q := Vector2i(p.x + ox[bi], p.y + oy)
				if key == "ground":
					ground_spots.append(q)
				elif key == "air":
					air_spots.append(q)
				else:
					cave_spots.append(q)
		for p in bd["items"]:
			item_spots.append(Vector2i(p.x + ox[bi], p.y + oy))
	# puits entre strates (à travers le plafond de la strate du dessous) et treuils
	for bi in 2:
		var hx: int = ox[bi] + int(bands[bi]["mark"]["drop_x"])
		var oy2 := (bi + 1) * H
		for y in range(oy2, oy2 + CEIL + 1):
			for dx in [-1, 0, 1]:
				big[y][hx + dx] = "."
		var lf: int = int(bands[bi + 1]["mark"]["land_f"])
		big[oy2 + lf - 1][hx] = "~"
	W = total_w
	H = total_h
	g = big

# ---------------------------------------------------------------- génération
# Renvoie la carte (tableau de chaînes) d'un niveau.
#  depth : 1..N (difficulté)   boss : "" / "K" / "Q"   final : sanctuaire à la fin
func generate(biome: Dictionary, seed_value: int, depth: int, boss: String, final: bool, diff: Dictionary = {}, rush := false) -> Array:
	rng.seed = seed_value
	challenge_x = -1
	ground_spots.clear()
	air_spots.clear()
	item_spots.clear()
	cave_spots.clear()
	biome_id = String(biome.get("id", ""))
	trap_p = clampf(0.2 + depth * 0.06, 0.2, 0.5)
	var n := 0 if rush else mini(6 + depth, 11)
	# toutes les salles possibles un peu partout, celles du biome bien plus souvent
	var weights: Dictionary = {}
	for k in ["flat", "platforms", "pit", "hill", "pillars", "bridge", "islands", "zigzag", "split", "moving", "crumble", "cave", "blades"]:
		weights[k] = 0.35
	for k in biome["chunks"]:
		weights[k] = float(weights.get(k, 0.0)) + float(biome["chunks"][k])
	weights["treasure"] = 0.45
	weights["challenge"] = 0.4
	weights["altar"] = 0.35
	var strata: bool = biome_id in STRATA and not rush
	if strata:
		weights.erase("challenge")    # le drapeau du défi se cherche vers la droite : pas en strates
	var chunks := []
	var recent := []
	for i in n:
		var wsel := weights.duplicate()
		for r in recent:
			wsel.erase(r)            # pas deux fois la même salle de suite (ni à une salle d'écart)
		var k := _pick(wsel)
		if k in ["treasure", "challenge", "altar"]:
			weights.erase(k)      # au plus une salle spéciale de chaque sorte
		chunks.append(k)
		recent.append(k)
		if recent.size() > 2:
			recent.pop_front()
	var end_kinds := []
	if boss != "":
		end_kinds.append("boss")
	end_kinds.append("shrine" if final else "exit")
	if rush:
		H = 26
		_build(["start"] + chunks + end_kinds, boss)
	elif not strata:
		# chemin horizontal, banc à mi-parcours, et 2-3 grottes sous le chemin
		H = BAND_H
		var kinds := ["start"]
		var caves := 2 if n < 9 else 3
		var cave_at := []
		for c in caves:
			cave_at.append(1 + (c * n) / caves + rng.randi_range(0, maxi(n / caves - 2, 0)))
		for i in n:
			if i == n / 2:
				kinds.append("rest")
			if i in cave_at:
				kinds.append("grotto")
			kinds.append(chunks[i])
		_build(kinds + end_kinds, boss)
	else:
		_build_strata(chunks, end_kinds, boss)
	# défi chronométré : drapeau d'arrivée ~45 cases plus loin, sur un sol (avant le boss)
	if challenge_x >= 0:
		var limit := W - 12 - (40 if boss != "" else 0)
		var placed := false
		for gx in range(challenge_x + 40, mini(challenge_x + 60, limit)):
			for gy in range(CEIL + 2, H - 1):
				if g[gy][gx] == "." and g[gy + 1][gx] == "#" and g[gy - 1][gx] == ".":
					put(gx, gy, "G")
					placed = true
					break
			if placed:
				break
		if not placed:
			for yy in H:
				for xx in W:
					if g[yy][xx] == "S":
						g[yy][xx] = "."
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
	# ennemis garantis dans les grottes (sur un sol sûr près du point prévu)
	var gtypes: Dictionary = {}
	for k in ew:
		if not k in ["f", "w", "r"]:
			gtypes[k] = ew[k]
	for p in cave_spots:
		for dx in [0, -1, 1, -2, 2, -3, 3, -4, 4, -5, 5]:
			var q := Vector2i(p.x + dx, p.y)
			if q.x > 0 and q.x < W - 1 and q.y + 1 < H and g[q.y][q.x] == "." and g[q.y + 1][q.x] == "#":
				var k := _pick(gtypes) if not gtypes.is_empty() else "c"
				put(q.x, q.y, k if k in ["s", "h", "g", "b", "l"] else "c")
				break
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
	if not rush:
		_ground_traps(depth)
	var out := []
	for row in g:
		out.append("".join(PackedStringArray(row)))
	return out

# Pièges au sol propres au biome : herse de pics partout, champignon à gaz (Jardins, Ruche),
# geyser de flammes (Forge) ou de glace (Abysses Gelés). Posés avec parcimonie et jamais
# près d'un autre danger (pas de piège sur piège), ni près du départ, de la sortie, d'un banc
# ou de l'arène du boss.
const HAZARDS := "^ZUVkqvyCXKxzaod"
const KEEP_CLEAR := "PEBOHLSGR*N$"
func _ground_traps(depth: int) -> void:
	var pool := {"k": 1.0}
	match biome_id:
		"jardins", "ruche": pool = {"q": 1.6, "k": 0.6}
		"forge": pool = {"v": 1.6, "k": 0.6}
		"glace": pool = {"y": 1.6, "k": 0.6}
		"profondeurs": pool = {"d": 1.4, "k": 0.6}
		"citadelle": pool = {"o": 1.4, "k": 0.6}
		"cristal": pool = {"x": 1.4, "k": 0.6}
		"bibliotheque": pool = {"z": 1.4, "k": 0.6}
		"ossuaire": pool = {"a": 1.4, "k": 0.6}
	var want := clampi(1 + depth / 2, 1, 4)
	var boss_x := -1000
	for y in H:
		var bx: int = g[y].find("K")
		if bx >= 0:
			boss_x = bx
	var cands := []
	for y in range(CEIL + 3, H - 1):
		for x in range(6, W - 6):
			# case libre, sol plein sous elle et sous ses voisines, trois cases d'air au-dessus
			if g[y][x] != "." or g[y + 1][x] != "#" or g[y + 1][x - 1] != "#" or g[y + 1][x + 1] != "#":
				continue
			if g[y - 1][x] != "." or g[y - 2][x] != "." or g[y][x - 1] != "." or g[y][x + 1] != ".":
				continue
			if absi(x - boss_x) < 34:
				continue
			cands.append(Vector2i(x, y))
	cands = _shuffled(cands)
	var placed := 0
	for c in cands:
		if placed >= want:
			break
		if _near(c, HAZARDS, 9, 5) or _near(c, KEEP_CLEAR, 6, 4):
			continue
		var kc := _pick(pool)
		if kc == "d":
			# la goutte acide a besoin d'un plafond pas trop haut au-dessus
			var cy: int = c.y
			while cy > 0 and g[cy - 1][c.x] != "#" and c.y - cy < 12:
				cy -= 1
			if cy <= 0 or g[cy - 1][c.x] != "#":
				kc = "k"
		put(c.x, c.y, kc)
		placed += 1

func _near(c: Vector2i, chars: String, rx: int, ry: int) -> bool:
	for y in range(maxi(c.y - ry, 0), mini(c.y + ry + 1, H)):
		for x in range(maxi(c.x - rx, 0), mini(c.x + rx + 1, W)):
			if chars.contains(String(g[y][x])):
				return true
	return false

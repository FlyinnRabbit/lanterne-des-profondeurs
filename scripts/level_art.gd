extends Node2D
# Terrain peint : matière de la roche (shader), profondeur, arêtes éclairées,
# herbe et décor propre à chaque biome, pics ombrés.

const DU = preload("res://scripts/draw_util.gd")
const RockShader = preload("res://shaders/rock.gdshader")
const STYLE := {"profondeurs": 0, "jardins": 7, "citadelle": 1, "cristal": 2, "forge": 3,
	"bibliotheque": 1, "glace": 4, "ruche": 5, "ossuaire": 6, "hub": 1}
# quantité d'herbe sur les sols
const GRASS := {"profondeurs": 0.7, "jardins": 1.0, "hub": 0.8, "citadelle": 0.35, "cristal": 0.25,
	"bibliotheque": 0.2, "ruche": 0.3, "ossuaire": 0.35, "forge": 0.0, "glace": 0.0}

var main
var depth := {}
var biome := "profondeurs"
var fill: Node2D
# Le décor est découpé en tranches verticales : Godot ne dessine que celles qui sont à l'écran.
const CHUNK := 10          # largeur d'une tranche, en cases
var is_chunk := false
var cells: Array = []      # cases de roche de cette tranche
var spike_list: Array = [] # pics de cette tranche
var chunks: Array = []
var _mesh: ArrayMesh

class RockFill extends Node2D:
	var art
	func _draw() -> void:
		art.draw_fill(self)

func _ready() -> void:
	if is_chunk:
		fill = RockFill.new()
		fill.art = self
		fill.show_behind_parent = true
		fill.material = material
		material = null
		add_child(fill)
		return
	biome = String(main.pal.get("id", "profondeurs"))
	_compute_depth()
	var m := ShaderMaterial.new()
	m.shader = RockShader
	m.set_shader_parameter("style", STYLE.get(biome, 0))
	m.set_shader_parameter("accent", main.pal["moss"])
	var groups := {}
	for c in main.solid.keys():
		var k: int = int(floor(float(c.x) / CHUNK))
		if not groups.has(k):
			groups[k] = [[], []]
		groups[k][0].append(c)
	for sp in main.spikes:
		var k2: int = int(floor(sp.position.x / (CHUNK * main.TILE)))
		if not groups.has(k2):
			groups[k2] = [[], []]
		groups[k2][1].append(sp)
	for k in groups:
		var ch := Node2D.new()
		ch.set_script(get_script())
		ch.is_chunk = true
		ch.main = main
		ch.depth = depth
		ch.biome = biome
		ch.cells = groups[k][0]
		ch.spike_list = groups[k][1]
		ch.material = m
		add_child(ch)
		chunks.append(ch)

func redraw_all() -> void:
	for ch in chunks:
		ch.queue_redraw()

func _cell(x: int, y: int) -> bool:
	return main.solid.has(Vector2i(x, y))

func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func _compute_depth() -> void:
	var q: Array[Vector2i] = []
	var w: int = main.map_size.x
	var h: int = main.map_size.y
	for c in main.solid.keys():
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if not main.solid.has(n):
				depth[c] = 0
				q.append(c)
				break
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		var dc: int = depth[c]
		if dc >= 6:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if main.solid.has(n) and not depth.has(n):
				depth[n] = dc + 1
				q.append(n)

func _depth_at(x: int, y: int) -> float:
	return float(depth.get(Vector2i(x, y), 7))

# Couleur à un coin de tuile : moyenne des 4 tuiles voisines (dégradé continu)
func _corner(x: int, y: int, rock: Color, deep: Color) -> Color:
	var s := 0.0
	var n := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var c := Vector2i(x + d.x, y + d.y)
		if main.solid.has(c):
			s += _depth_at(c.x, c.y)
			n += 1
	var k := clampf((s / maxf(n, 1)) / 6.0, 0.0, 1.0)
	return rock.lightened(0.1).lerp(deep, k)

func draw_fill(ci: CanvasItem) -> void:
	# toute la roche de la tranche en un seul maillage (un seul appel de dessin)
	if cells.is_empty():
		return
	var T: int = main.TILE
	var rock: Color = main.pal["rock"]
	var deep := rock.darkened(0.62)
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		var p := Vector2(x * T, y * T)
		var n := verts.size()
		verts.append_array(PackedVector2Array([p, p + Vector2(T, 0), p + Vector2(T, T), p + Vector2(0, T)]))
		cols.append_array(PackedColorArray([_corner(x, y, rock, deep), _corner(x + 1, y, rock, deep), _corner(x + 1, y + 1, rock, deep), _corner(x, y + 1, rock, deep)]))
		idx.append_array(PackedInt32Array([n, n + 1, n + 2, n, n + 2, n + 3]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	_mesh = ArrayMesh.new()   # gardé en mémoire : le rendu en a besoin après _draw
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ci.draw_mesh(_mesh, null)

func _draw() -> void:
	if not is_chunk:
		return
	var T: int = main.TILE
	var rock: Color = main.pal["rock"]
	var rock_hi: Color = main.pal["rock_hi"]
	var moss: Color = main.pal["moss"]
	var grass: float = GRASS.get(biome, 0.5)
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		var r := Rect2(x * T, y * T, T, T)
		var h := _hash(x, y)
		var up := not _cell(x, y - 1)
		var down := not _cell(x, y + 1)
		var left := not _cell(x - 1, y)
		var right := not _cell(x + 1, y)
		var clear := Color(rock_hi, 0.0)
		if left:
			draw_polygon(PackedVector2Array([r.position, r.position + Vector2(5, 0), r.position + Vector2(5, T), r.position + Vector2(0, T)]),
				PackedColorArray([Color(rock_hi, 0.9), clear, clear, Color(rock_hi, 0.9)]))
		if right:
			var e := Color(rock.darkened(0.5), 0.0)
			draw_polygon(PackedVector2Array([r.position + Vector2(T - 5, 0), r.position + Vector2(T, 0), r.position + Vector2(T, T), r.position + Vector2(T - 5, T)]),
				PackedColorArray([e, Color(rock_hi, 0.55), Color(rock_hi, 0.55), e]))
		if down:
			DU.vgrad(self, Rect2(r.position + Vector2(0, T - 7), Vector2(T, 7)), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))
			draw_line(Vector2(r.position.x, r.end.y - 1), Vector2(r.end.x, r.end.y - 1), rock_hi.darkened(0.2), 2.0)
			_hang(r, h, x, y)
		if up:
			_top(r, h, x, y, grass)
	_spikes()

# ---------------------------------------------------------------- dessus des sols
func _top(r: Rect2, h: float, x: int, y: int, grass: float) -> void:
	var T: int = main.TILE
	var moss: Color = main.pal["moss"]
	var rock_hi: Color = main.pal["rock_hi"]
	var lip := moss.darkened(0.55) if grass > 0.0 else rock_hi
	if biome == "glace":
		lip = Color(0.82, 0.92, 1.0)
	elif biome == "forge":
		lip = Color(0.22, 0.1, 0.07)
	DU.vgrad(self, Rect2(r.position, Vector2(T, 9)), lip, Color(lip, 0.0))
	draw_line(r.position + Vector2(0, 0.8), r.position + Vector2(T, 0.8), lip.lightened(0.35), 1.6)
	if biome == "glace":
		# corniche de neige arrondie
		var pts := PackedVector2Array()
		for i in 9:
			var k := i / 8.0
			pts.append(r.position + Vector2(k * T, -2.0 - sin(k * PI) * (2.0 + h * 2.5)))
		pts.append(r.position + Vector2(T, 4))
		pts.append(r.position + Vector2(0, 4))
		DU.flat(self, pts, Color(0.9, 0.96, 1.0))
	if biome == "forge":
		if h > 0.45:
			var ex := r.position.x + 4 + h * 20
			draw_line(Vector2(ex, r.position.y + 2), Vector2(ex + 6, r.position.y + 6), Color(1.0, 0.55, 0.15), 1.6)
			draw_circle(Vector2(ex + 3, r.position.y + 3), 5.0, Color(1.0, 0.5, 0.1, 0.18))
	# herbe : brins courbes de plusieurs teintes
	var n := int(round(grass * 8.0))
	for i in n:
		var a := _hash(x * 7 + i, y * 3 - i)
		var b := _hash(x + i * 13, y + 5)
		var bx := r.position.x + (i + a * 0.9) * (T / float(maxi(n, 1)))
		var hh := (3.0 + a * 9.0 + b * 4.0) * (0.6 + grass * 0.5)
		var lean := (b - 0.5) * 6.0
		var col := moss.darkened(0.45).lerp(moss.lightened(0.15), a)
		var base := Vector2(bx, r.position.y + 1.5)
		draw_polyline(PackedVector2Array([base, base + Vector2(lean * 0.3, -hh * 0.55), base + Vector2(lean, -hh)]), col, 1.3)
	_decor(r, h, x, y)

func _decor(r: Rect2, h: float, x: int, y: int) -> void:
	var T: int = main.TILE
	var moss: Color = main.pal["moss"]
	var g := r.position + Vector2(6 + h * (T - 12), 0)
	var h2 := _hash(x + 31, y - 17)
	if h2 > 0.78:
		return   # pas de décor sur ce bloc la plupart du temps
	if h2 > 0.5:
		match biome:
			"profondeurs", "hub":
				for i in 2:
					var c := g + Vector2(i * 6 - 3, -1)
					draw_circle(c, 2.4 - i * 0.6, main.pal["rock_hi"].lightened(0.15))
			"jardins":
				_mushroom(g, 5.0 + h * 7.0, Color(0.78, 0.32, 0.28) if h > 0.5 else Color(0.35, 0.75, 0.7))
			"cristal":
				_crystals(g, 6.0 + h * 10.0, moss)
			"ossuaire":
				_bones(g, h)
			"ruche":
				DU.poly(self, DU.ellipse(g + Vector2(0, -3), Vector2(6, 4)), Color(0.85, 0.6, 0.2))
			"bibliotheque":
				_books(g, h)
			"citadelle":
				_candle(g, h)
			"glace":
				_crystals(g, 5.0 + h * 7.0, Color(0.75, 0.9, 1.0))
		return
	if h2 > 0.36:
		match biome:
			"profondeurs":
				_glowcap(g, Color(0.5, 0.8, 1.0))
			"jardins":
				_glowcap(g, Color(0.6, 1.0, 0.55))
			"hub":
				_flower(g, h)
			"ossuaire":
				_skull(g)
			"forge":
				DU.poly(self, PackedVector2Array([g + Vector2(-7, 0), g + Vector2(-2, -5), g + Vector2(4, -4), g + Vector2(8, 0)]), Color(0.18, 0.12, 0.1))

func _mushroom(g: Vector2, s: float, cap: Color) -> void:
	DU.poly(self, PackedVector2Array([g + Vector2(-s * 0.18, 0), g + Vector2(-s * 0.12, -s), g + Vector2(s * 0.12, -s), g + Vector2(s * 0.18, 0)]), Color(0.85, 0.82, 0.7), false)
	DU.poly(self, DU.ellipse(g + Vector2(0, -s), Vector2(s * 0.7, s * 0.45), 16, PI, TAU), cap)
	for i in 3:
		draw_circle(g + Vector2((i - 1) * s * 0.3, -s - s * 0.2 + absf(i - 1) * s * 0.1), s * 0.07 + 0.5, Color(1, 0.95, 0.85))

func _glowcap(g: Vector2, col: Color) -> void:
	draw_circle(g + Vector2(0, -6), 9.0, Color(col, 0.16))
	draw_line(g, g + Vector2(0.5, -5), Color(0.8, 0.85, 0.9), 1.2)
	DU.flat(self, DU.ellipse(g + Vector2(0.5, -5.5), Vector2(3.5, 2.4), 12, PI, TAU), col)
	draw_line(g + Vector2(4, 0), g + Vector2(4.5, -3), Color(0.8, 0.85, 0.9), 1.0)
	DU.flat(self, DU.ellipse(g + Vector2(4.5, -3.2), Vector2(2.2, 1.6), 10, PI, TAU), col.lightened(0.2))

func _crystals(g: Vector2, s: float, col: Color) -> void:
	for i in 3:
		var a := (i - 1) * 0.45
		var hh := s * (1.0 - absf(i - 1) * 0.35)
		var base := g + Vector2((i - 1) * 4.0, 0)
		var dir := Vector2.from_angle(-PI / 2.0 + a)
		var side := dir.orthogonal() * 2.6
		var pts := PackedVector2Array([base - side, base - side + dir * hh * 0.8, base + dir * hh, base + side + dir * hh * 0.8, base + side])
		DU.poly(self, pts, col.darkened(0.15))
		draw_line(base + dir * hh * 0.15, base + dir * hh * 0.9, Color(1, 1, 1, 0.6), 1.0)
	draw_circle(g + Vector2(0, -s * 0.5), s * 0.9, Color(col, 0.12))

func _bones(g: Vector2, h: float) -> void:
	var c := Color(0.85, 0.82, 0.72)
	var a := g + Vector2(-8, -2)
	var b := g + Vector2(8, -2 - h * 3)
	draw_line(a, b, c, 2.4)
	for e in [a, b]:
		draw_circle(e + Vector2(0, -1.2), 1.8, c)
		draw_circle(e + Vector2(0, 1.2), 1.8, c)

func _skull(g: Vector2) -> void:
	var c := Color(0.86, 0.83, 0.74)
	DU.poly(self, DU.ellipse(g + Vector2(0, -6), Vector2(6, 5.5)), c, false)
	draw_rect(Rect2(g + Vector2(-3.5, -2), Vector2(7, 3)), c)
	draw_circle(g + Vector2(-2.2, -6), 1.6, Color(0.08, 0.07, 0.06))
	draw_circle(g + Vector2(2.2, -6), 1.6, Color(0.08, 0.07, 0.06))

func _books(g: Vector2, h: float) -> void:
	var cols := [Color(0.5, 0.2, 0.18), Color(0.25, 0.32, 0.45), Color(0.35, 0.42, 0.25), Color(0.55, 0.45, 0.25)]
	var yy := 0.0
	for i in 2 + int(h * 2.0):
		var w := 13.0 - i * 1.5
		var off := (_hash(int(g.x) + i, i) - 0.5) * 3.0
		draw_rect(Rect2(g + Vector2(-w / 2.0 + off, -yy - 3.0), Vector2(w, 3.0)), cols[i % cols.size()])
		draw_line(g + Vector2(-w / 2.0 + off, -yy - 1.5), g + Vector2(w / 2.0 + off - 1, -yy - 1.5), Color(0.9, 0.85, 0.7, 0.6), 0.8)
		yy += 3.0

func _candle(g: Vector2, h: float) -> void:
	var hh := 5.0 + h * 6.0
	draw_rect(Rect2(g + Vector2(-1.8, -hh), Vector2(3.6, hh)), Color(0.85, 0.8, 0.65))
	draw_circle(g + Vector2(0, -hh - 2.5), 6.0, Color(1.0, 0.8, 0.4, 0.2))
	DU.flat(self, DU.ellipse(g + Vector2(0, -hh - 2.5), Vector2(1.4, 2.6)), Color(1.0, 0.85, 0.45))

func _flower(g: Vector2, h: float) -> void:
	draw_line(g, g + Vector2(1, -7), Color(0.4, 0.55, 0.3), 1.2)
	var c := Color(0.95, 0.85, 0.5) if h > 0.5 else Color(0.85, 0.6, 0.75)
	for i in 5:
		draw_circle(g + Vector2(1, -8) + Vector2.from_angle(i * TAU / 5.0) * 1.8, 1.4, c)
	draw_circle(g + Vector2(1, -8), 1.0, Color(0.95, 0.7, 0.3))

# ---------------------------------------------------------------- dessous des plafonds
func _hang(r: Rect2, h: float, x: int, y: int) -> void:
	var T: int = main.TILE
	var rock_hi: Color = main.pal["rock_hi"]
	var bot := r.end.y
	match biome:
		"glace":
			if h > 0.25:
				var sx := r.position.x + 5 + h * 20
				var l := 8.0 + h * 22.0
				DU.poly(self, PackedVector2Array([Vector2(sx - 4, bot), Vector2(sx + 4, bot), Vector2(sx, bot + l)]), Color(0.7, 0.85, 0.95), false)
				draw_line(Vector2(sx - 1.5, bot + 1), Vector2(sx - 0.3, bot + l * 0.7), Color(1, 1, 1, 0.7), 1.0)
		"ruche":
			if h > 0.45:
				var sx := r.position.x + 6 + h * 18
				var l := 5.0 + h * 12.0
				draw_line(Vector2(sx, bot), Vector2(sx, bot + l), Color(0.95, 0.65, 0.15), 2.4)
				draw_circle(Vector2(sx, bot + l + 1.5), 2.6, Color(1.0, 0.72, 0.2))
		"jardins", "profondeurs", "hub":
			if h > 0.55:
				var sx := r.position.x + 4 + h * 22
				var l := 14.0 + h * 30.0
				var col: Color = main.pal["moss"].darkened(0.45)
				var pts := PackedVector2Array()
				for i in 6:
					var k := i / 5.0
					pts.append(Vector2(sx + sin(k * 5.0 + h * 9.0) * 3.0, bot + k * l))
				draw_polyline(pts, col, 1.5)
				if biome == "jardins":
					for i in 3:
						draw_circle(pts[i * 2 + 1] + Vector2(2, 0), 1.8, main.pal["moss"].darkened(0.2))
			elif h > 0.35:
				_stalactite(r, h, rock_hi)
		_:
			if h > 0.45:
				_stalactite(r, h, rock_hi)

func _stalactite(r: Rect2, h: float, col: Color) -> void:
	var sx := r.position.x + 6 + h * 18
	var l := 8.0 + h * 14.0
	DU.poly(self, PackedVector2Array([Vector2(sx - 5, r.end.y), Vector2(sx + 5, r.end.y), Vector2(sx + 1, r.end.y + l * 0.6), Vector2(sx, r.end.y + l)]), col.darkened(0.1), false)

# ---------------------------------------------------------------- pics
func _spikes() -> void:
	var spike_col: Color = main.pal["spike"]
	if Settings.colorblind:
		spike_col = Color(1.0, 0.1, 0.85)
	for s in spike_list:
		if Settings.colorblind:
			draw_rect(Rect2(s.position.x - 2, s.end.y - 3, s.size.x + 4, 3), Color(1, 1, 1))
		var n := 3
		var w: float = s.size.x / n
		for i in n:
			var bx: float = s.position.x + i * w
			var tip := Vector2(bx + w / 2.0, s.position.y - 2.0)
			var l := Vector2(bx, s.end.y)
			var rr := Vector2(bx + w, s.end.y)
			draw_polygon(PackedVector2Array([l, tip, Vector2(bx + w / 2.0, s.end.y)]), PackedColorArray([spike_col.darkened(0.2), spike_col.lightened(0.3), spike_col.darkened(0.1)]))
			draw_polygon(PackedVector2Array([Vector2(bx + w / 2.0, s.end.y), tip, rr]), PackedColorArray([spike_col.darkened(0.45), spike_col.darkened(0.15), spike_col.darkened(0.6)]))

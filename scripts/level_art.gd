extends Node2D
# Terrain peint : matière de la roche (shader), profondeur, arêtes éclairées,
# herbe et décor propre à chaque biome, pics ombrés.

const DU = preload("res://scripts/draw_util.gd")
const RockShader = preload("res://shaders/rock.gdshader")
const STYLE := {"profondeurs": 0, "jardins": 7, "citadelle": 1, "cristal": 2, "forge": 3,
	"bibliotheque": 1, "glace": 4, "ruche": 5, "ossuaire": 6, "hub": 1, "jungle": 7, "desert": 0, "antique": 1}
# quantité d'herbe sur les sols
const GRASS := {"profondeurs": 0.7, "jardins": 1.0, "hub": 0.8, "citadelle": 0.35, "cristal": 0.25,
	"bibliotheque": 0.2, "ruche": 0.3, "ossuaire": 0.35, "forge": 0.0, "glace": 0.0, "jungle": 1.0, "desert": 0.08, "antique": 0.3}

var main
var depth := {}
var biome := "profondeurs"
var fill: Node2D
# Le décor est découpé en blocs de cases : Godot ne dessine que ceux qui sont à l'écran.
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

# Premier plan : silhouettes sombres (herbes hautes, fougères, rochers, cristaux, os…) dessinées
# PAR-DESSUS le héros et les ennemis, qui passent derrière.
class Foreground extends Node2D:
	var art
	func _draw() -> void:
		art.draw_front(self)

func _ready() -> void:
	if is_chunk:
		fill = RockFill.new()
		fill.art = self
		fill.show_behind_parent = true
		fill.material = material
		material = null
		add_child(fill)
		if biome != "hub" and true:
			var fg := Foreground.new()
			fg.art = self
			fg.z_index = 40
			add_child(fg)
		if int(Settings.gfx_quality) <= 1:
			_decor_lights()
		return
	biome = String(main.pal.get("id", "profondeurs"))
	_compute_depth()
	var m := ShaderMaterial.new()
	m.shader = RockShader
	m.set_shader_parameter("style", STYLE.get(biome, 0))
	m.set_shader_parameter("accent", main.pal["moss"])
	var groups := {}
	# blocs de CHUNK x CHUNK cases : sur les niveaux en strates (120 rangées), seuls les blocs
	# visibles sont dessinés, et plus toute la hauteur de la tranche
	for c in main.solid.keys():
		var k := Vector2i(int(floor(float(c.x) / CHUNK)), int(floor(float(c.y) / CHUNK)))
		if not groups.has(k):
			groups[k] = [[], []]
		groups[k][0].append(c)
	for sp in main.spikes:
		var k2 := Vector2i(int(floor(sp.position.x / (CHUNK * main.TILE))), int(floor(sp.position.y / (CHUNK * main.TILE))))
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
		for k in ch.get_children():
			if k is CanvasItem:
				k.queue_redraw()

func _cell(x: int, y: int) -> bool:
	var c := Vector2i(x, y)
	return main.solid.has(c) or main.veiled.has(c)

func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func _compute_depth() -> void:
	var q: Array[Vector2i] = []
	var w: int = main.map_size.x
	var h: int = main.map_size.y
	for c in main.solid.keys() + main.veiled.keys():
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if not main.solid.has(n) and not main.veiled.has(n):
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
			if (main.solid.has(n) or main.veiled.has(n)) and not depth.has(n):
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
		if main.solid.has(c) or main.veiled.has(c):
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
		# bords cassés : la roche déborde en éclats irréguliers sur les faces à l'air libre
		var edge := rock.lightened(0.1)
		if not _cell(x, y + 1):
			_jag(verts, cols, idx, p + Vector2(T, T), p + Vector2(0, T), Vector2(0, 1), JAG_CEIL, edge)
		if not _cell(x - 1, y):
			_jag(verts, cols, idx, p + Vector2(0, T), p, Vector2(-1, 0), JAG_WALL, edge)
		if not _cell(x + 1, y):
			_jag(verts, cols, idx, p + Vector2(T, 0), p + Vector2(T, T), Vector2(1, 0), JAG_WALL, edge)
		if not _cell(x, y - 1):
			_jag(verts, cols, idx, p, p + Vector2(T, 0), Vector2(0, -1), 1.6, edge)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	_mesh = ArrayMesh.new()   # gardé en mémoire : le rendu en a besoin après _draw
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ci.draw_mesh(_mesh, null)


# Bande d'éclats le long d'une face : points de la nouvelle arête, décalés vers l'extérieur d'une
# quantité tirée de la position dans le monde (deux tuiles voisines se raccordent aux coins).
const JAG_K := 5
const JAG_WALL := 9.0
const JAG_CEIL := 10.0
func _jag_pts(a: Vector2, b: Vector2, out: Vector2, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in JAG_K + 1:
		var q := a.lerp(b, float(i) / JAG_K)
		var o := 0.0
		if i > 0 and i < JAG_K:
			var r1 := _hash(int(q.x * 1.7 + out.y * 31.0), int(q.y * 1.3 + out.x * 17.0))
			var r2 := _hash(int(q.x) + 91, int(q.y) - 57)
			o = amp * (0.1 + 0.7 * r1 * r1)
			if r2 > 0.8:
				o += amp * 0.8          # gros éclat qui dépasse
			elif r2 < 0.18:
				o *= 0.05              # entaille
			q += (b - a).normalized() * (r2 - 0.5) * 3.0
		pts.append(q + out * o)
	return pts

func _jag(verts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array, a: Vector2, b: Vector2, out: Vector2, amp: float, col: Color) -> void:
	var outer := _jag_pts(a, b, out, amp)
	var base := verts.size()
	for i in JAG_K + 1:
		verts.append(a.lerp(b, float(i) / JAG_K))
		verts.append(outer[i])
		cols.append(col)
		cols.append(col)
	for i in JAG_K:
		var j := base + i * 2
		idx.append_array(PackedInt32Array([j, j + 2, j + 3, j, j + 3, j + 1]))

# contour des arêtes cassées : trait sombre, et reflet sur les faces tournées vers la lumière
func _jag_outline(a: Vector2, b: Vector2, out: Vector2, amp: float, lit: bool) -> void:
	var pts := _jag_pts(a, b, out, amp)
	draw_polyline(pts, Color(0, 0, 0, 0.28), 1.4)
	if lit:
		var hl := PackedVector2Array()
		for q in pts:
			hl.append(q - out * 1.2)
		draw_polyline(hl, Color(main.pal["rock_hi"], 0.55), 1.0)

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
				PackedColorArray([Color(rock_hi, 0.35), clear, clear, Color(rock_hi, 0.35)]))
		if right:
			var e := Color(rock.darkened(0.5), 0.0)
			draw_polygon(PackedVector2Array([r.position + Vector2(T - 5, 0), r.position + Vector2(T, 0), r.position + Vector2(T, T), r.position + Vector2(T - 5, T)]),
				PackedColorArray([e, Color(rock_hi, 0.2), Color(rock_hi, 0.2), e]))
		if down:
			DU.vgrad(self, Rect2(r.position + Vector2(0, T - 7), Vector2(T, 7)), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))
			_hang(r, h, x, y)
		if up:
			_top(r, h, x, y, grass)
		var p0 := r.position
		if left:
			_jag_outline(p0 + Vector2(0, T), p0, Vector2(-1, 0), JAG_WALL, true)
		if right:
			_jag_outline(p0 + Vector2(T, 0), p0 + Vector2(T, T), Vector2(1, 0), JAG_WALL, false)
		if down:
			_jag_outline(p0 + Vector2(T, T), p0 + Vector2(0, T), Vector2(0, 1), JAG_CEIL, false)
		_wear(r, h, x, y, up, down, left, right)
	_spikes()

# ---------------------------------------------------------------- lumières du décor
# Ce qui brille dans le décor éclaire vraiment autour de lui : champignons lumineux, bougies,
# cristaux, braises, gros cristaux de premier plan. Mêmes tirages que le dessin (même case,
# même hasard), au plus quelques lumières par tranche.
func _decor_lights() -> void:
	var T: int = main.TILE
	var n := 0
	for c in cells:
		if n >= 4:
			break
		var x: int = c.x
		var y: int = c.y
		if _cell(x, y - 1):
			continue
		var h := _hash(x, y)
		var h2 := _hash(x + 31, y - 17)
		var g := Vector2(x * T + 6 + h * (T - 12), y * T)
		var col := Color(0, 0, 0, 0)
		var sc := 0.45
		if h2 > 0.36 and h2 <= 0.5 and biome in ["profondeurs", "jardins"]:
			col = Color(0.5, 0.8, 1.0) if biome == "profondeurs" else Color(0.6, 1.0, 0.55)
		elif h2 > 0.5 and h2 <= 0.78 and biome == "citadelle":
			col = Color(1.0, 0.75, 0.4)
		elif h2 > 0.5 and h2 <= 0.78 and biome in ["cristal", "glace"]:
			col = main.pal["moss"] if biome == "cristal" else Color(0.6, 0.85, 1.0)
		elif h2 > 0.36 and h2 <= 0.5 and biome == "forge" and h > 0.45:
			col = Color(1.0, 0.5, 0.15)
		# gros cristaux et scories du premier plan
		var hf := _hash(x * 3 + 11, y * 5 - 3)
		if biome == "profondeurs" and hf > 0.8 and x >= 18 and not _cell(x, y - 2) and _hash(x + 5, y - 9) > 0.4 and _hash(x + 5, y - 9) <= 0.72:
			col = Color(0.5, 0.82, 1.0)
			g = Vector2(x * T + 6 + _hash(x, y + 77) * (T - 12), y * T - 14)
			sc = 0.7
		if hf > 0.86 and x >= 18 and biome in ["cristal", "forge"] and not _cell(x, y - 2):
			col = main.pal["moss"] if biome == "cristal" else Color(1.0, 0.45, 0.12)
			g = Vector2(x * T + 6 + _hash(x, y + 77) * (T - 12), y * T - 18)
			sc = 0.8
		if col.a == 0.0:
			continue
		var l: PointLight2D = main.make_light(col, sc, 0.55, g + Vector2(0, -8))
		add_child(l)
		n += 1

# ---------------------------------------------------------------- usure : fissures, coins ébréchés, éboulis
func _wear(r: Rect2, h: float, x: int, y: int, up: bool, down: bool, left: bool, right: bool) -> void:
	var T: int = main.TILE
	var rock: Color = main.pal["rock"]
	var rock_hi: Color = main.pal["rock_hi"]
	var dark := Color(0, 0, 0, 0.32)
	var lit := Color(rock_hi, 0.45)
	var h3 := _hash(x - 7, y + 29)
	# fissures qui partent des faces verticales et du plafond
	for side in [[left, Vector2(0, 0), Vector2(1, 0)], [right, Vector2(T, 0), Vector2(-1, 0)], [down, Vector2(0, T), Vector2(0, -1)]]:
		if not side[0] or h3 < 0.45:
			continue
		var dir: Vector2 = side[2]
		var along := Vector2(dir.y, dir.x).abs()
		var start: Vector2 = r.position + side[1] + along * (6.0 + h3 * (T - 12))
		var pts := PackedVector2Array([start])
		var cur := start
		var n := 3 + int(h * 3)
		for i in n:
			cur += dir * (3.0 + _hash(x + i, y * 3) * 4.0) + along * ((_hash(x * 5 + i, y - i) - 0.5) * 7.0)
			pts.append(cur)
		draw_polyline(pts, dark, 1.4)
		var hl := PackedVector2Array()
		for q in pts:
			hl.append(q + Vector2(0.9, 0.9))
		draw_polyline(hl, lit, 0.8)
	# coins saillants ébréchés : une facette sombre en biais
	var corners := [[up and left, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)], [up and right, Vector2(T, 0), Vector2(-1, 0), Vector2(0, 1)],
		[down and left, Vector2(0, T), Vector2(1, 0), Vector2(0, -1)], [down and right, Vector2(T, T), Vector2(-1, 0), Vector2(0, -1)]]
	for c in corners:
		if not c[0]:
			continue
		var o: Vector2 = r.position + c[1]
		var a := 4.0 + h * 6.0
		var b := 4.0 + h3 * 7.0
		draw_colored_polygon(PackedVector2Array([o, o + c[2] * a, o + c[2] * a * 0.4 + c[3] * b * 0.5, o + c[3] * b]), Color(0, 0, 0, 0.2))
		draw_line(o + c[2] * a, o + c[3] * b, Color(rock_hi, 0.55), 1.0)
	# éboulis au pied des murs et au bord des à-pics
	if up:
		var wall_l := _cell(x - 1, y - 1)
		var wall_r := _cell(x + 1, y - 1)
		var drop_l := left
		var drop_r := right
		for side2 in [[wall_l or drop_l, 0.0, 1.0], [wall_r or drop_r, float(T), -1.0]]:
			if not side2[0]:
				continue
			var bx: float = r.position.x + side2[1]
			for i in 3 + int(h * 3):
				var k := _hash(x * 3 + i, y + i * 7)
				var px: float = bx + side2[2] * (2.0 + k * 13.0)
				var rad := 1.4 + _hash(x + i * 5, y) * 2.6
				var c2 := Vector2(px, r.position.y - rad * 0.6)
				DU.poly(self, DU.ellipse(c2, Vector2(rad * 1.25, rad), 7), rock.lerp(rock_hi, 0.35 + k * 0.3), false)
				draw_arc(c2, rad, PI * 1.1, PI * 1.7, 4, Color(rock_hi.lightened(0.2), 0.6), 0.8)
	# bord d'à-pic : quelques éclats suspendus sous la lèvre
	if up and (left or right) and h > 0.3:
		var ex: float = r.position.x if left else r.end.x
		var sgn := -1.0 if left else 1.0
		for i in 2:
			var py: float = r.position.y + 8.0 + i * 9.0 + h * 4.0
			var w2 := 3.0 + _hash(x + i, y - i) * 3.0
			DU.poly(self, PackedVector2Array([Vector2(ex, py), Vector2(ex + sgn * w2, py + 2.0), Vector2(ex + sgn * w2 * 0.4, py + 5.0), Vector2(ex, py + 4.0)]), rock.lerp(rock_hi, 0.25), false)

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
			"jungle":
				_fern(g, h)
			"desert":
				_cactus(g, h)
			"antique":
				_ruin(g, h)
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
			"jungle":
				_flower(g, h)
			"desert":
				DU.poly(self, DU.ellipse(g + Vector2(0, -1), Vector2(8, 3), 12, PI, TAU), main.pal["rock_hi"].lightened(0.1))
			"antique":
				_amphora(g, h)
			"forge":
				DU.poly(self, PackedVector2Array([g + Vector2(-7, 0), g + Vector2(-2, -5), g + Vector2(4, -4), g + Vector2(8, 0)]), Color(0.18, 0.12, 0.1))

# fougère : frondes arquées de part et d'autre
func _fern(g: Vector2, h: float) -> void:
	var col := Color(0.3, 0.62, 0.28).lerp(Color(0.45, 0.75, 0.3), h)
	for k in 5:
		var a := -PI / 2.0 + (k - 2) * 0.42
		var tip := g + Vector2.from_angle(a) * (10.0 + h * 6.0 - absf(k - 2) * 1.5)
		var mid := (g + tip) * 0.5 + Vector2.from_angle(a + PI / 2.0) * 2.0
		draw_polyline(PackedVector2Array([g, mid, tip]), col, 1.4)
		for j in 3:
			var q := g.lerp(tip, 0.35 + j * 0.2)
			draw_line(q, q + Vector2.from_angle(a - 0.9) * 3.0, col.lightened(0.15), 1.0)
			draw_line(q, q + Vector2.from_angle(a + 0.9) * 3.0, col.lightened(0.15), 1.0)

# cactus à bras
func _cactus(g: Vector2, h: float) -> void:
	var c := Color(0.36, 0.55, 0.32)
	var hh := 10.0 + h * 8.0
	draw_line(g, g + Vector2(0, -hh), c.darkened(0.3), 6.0)
	draw_line(g, g + Vector2(0, -hh), c, 4.0)
	draw_circle(g + Vector2(0, -hh), 2.0, c)
	var s := 1.0 if h > 0.5 else -1.0
	draw_polyline(PackedVector2Array([g + Vector2(0, -hh * 0.45), g + Vector2(s * 5, -hh * 0.45), g + Vector2(s * 5, -hh * 0.75)]), c, 3.0)
	for k in 3:
		draw_line(g + Vector2(-2.5, -hh * (0.3 + k * 0.22)), g + Vector2(-4, -hh * (0.3 + k * 0.22) - 1), Color(0.95, 0.9, 0.75), 0.7)

# tronçon de colonne brisée
func _ruin(g: Vector2, h: float) -> void:
	var m := Color(0.72, 0.7, 0.66)
	var hh := 8.0 + h * 10.0
	DU.box(self, Rect2(g + Vector2(-6, -hh), Vector2(12, hh)), m)
	for k in 3:
		draw_line(g + Vector2(-3 + k * 3, -hh + 1), g + Vector2(-3 + k * 3, -1), m.darkened(0.25), 1.0)
	DU.flat(self, PackedVector2Array([g + Vector2(-6, -hh), g + Vector2(-2, -hh - 3), g + Vector2(3, -hh - 1), g + Vector2(6, -hh - 4), g + Vector2(6, -hh)]), m.lightened(0.1))
	DU.box(self, Rect2(g + Vector2(-8, -2), Vector2(16, 2)), m.darkened(0.15))

# amphore
func _amphora(g: Vector2, h: float) -> void:
	var c := Color(0.62, 0.36, 0.22) if h > 0.5 else Color(0.5, 0.42, 0.34)
	DU.poly(self, DU.ellipse(g + Vector2(0, -6), Vector2(4.5, 6)), c)
	DU.box(self, Rect2(g + Vector2(-1.5, -14), Vector2(3, 3)), c)
	draw_arc(g + Vector2(-3, -10), 2.0, PI * 0.5, PI * 1.5, 6, c.darkened(0.2), 1.0)
	draw_arc(g + Vector2(3, -10), 2.0, -PI * 0.5, PI * 0.5, 6, c.darkened(0.2), 1.0)
	draw_line(g + Vector2(-4, -6), g + Vector2(4, -6), Color(0.15, 0.1, 0.08, 0.6), 1.2)

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

# petit décor au sol de la Bibliothèque : encrier et plume, bougie usée ou sablier
func _books(g: Vector2, h: float) -> void:
	if h < 0.33:
		# encrier et plume
		draw_colored_polygon(DU.ellipse(g + Vector2(0, -3), Vector2(4, 3.5), 10), Color(0.12, 0.1, 0.16))
		draw_rect(Rect2(g + Vector2(-2, -8), Vector2(4, 2.5)), Color(0.2, 0.17, 0.22))
		draw_line(g + Vector2(1, -8), g + Vector2(7, -18), Color(0.92, 0.9, 0.85), 1.6)
		draw_line(g + Vector2(3, -11), g + Vector2(7, -17), Color(0.95, 0.93, 0.9), 2.4)
	elif h < 0.66:
		_candle(g, h * 0.6)
	else:
		# sablier
		var gl := Color(0.75, 0.85, 0.9, 0.7)
		var wd := Color(0.45, 0.3, 0.18)
		draw_rect(Rect2(g + Vector2(-5, -2), Vector2(10, 2)), wd)
		draw_rect(Rect2(g + Vector2(-5, -16), Vector2(10, 2)), wd)
		draw_colored_polygon(PackedVector2Array([g + Vector2(-4, -14), g + Vector2(4, -14), g + Vector2(0.7, -8), g + Vector2(4, -2), g + Vector2(-4, -2), g + Vector2(-0.7, -8)]), gl)
		draw_colored_polygon(PackedVector2Array([g + Vector2(-3.5, -2), g + Vector2(3.5, -2), g + Vector2(0, -5.5)]), Color(0.95, 0.8, 0.45))

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

# ---------------------------------------------------------------- premier plan
# Peu dense (environ un sol sur huit), jamais près du départ, devant des pics ni sur une petite
# plateforme. Chaque objet est planté DANS le sol : ombre de contact, puis l'objet, puis une butte
# de la matière du sol (terre et herbe, sable, neige, cendre, gravats) qui recouvre sa base.
func draw_front(ci: CanvasItem) -> void:
	var T: int = main.TILE
	var spiky := {}
	for sp in main.spikes:
		for xx in range(int(floor(sp.position.x / T)) - 1, int(ceil(sp.end.x / T)) + 1):
			spiky[Vector2i(xx, int(floor(sp.position.y / T)))] = true
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		if x < 18:
			continue
		var up := not _cell(x, y - 1) and not _cell(x, y - 2) and not _cell(x, y - 3) and not spiky.has(Vector2i(x, y - 1)) \
			and _cell(x - 1, y) and _cell(x + 1, y) and _cell(x - 2, y) and _cell(x + 2, y)
		var down := not _cell(x, y + 1) and not _cell(x, y + 2)
		var h := _hash(x * 3 + 11, y * 5 - 3)
		var k := _hash(x + 5, y - 9)
		var g := Vector2(x * T + 6 + _hash(x, y + 77) * (T - 12), y * T + 1)
		# les Profondeurs, très sombres, ont un premier plan plus fourni
		var th := 0.8 if biome == "profondeurs" else 0.86
		if up and h > th:
			_front_object(ci, g, 0.86 + (h - th) * 0.14 / (1.0 - th), k)
		elif down and h < (0.16 if biome == "profondeurs" else 0.1) and biome in ["jungle", "jardins", "profondeurs", "ruche", "glace", "cristal"]:
			var top := Vector2(x * T + 16, (y + 1) * T)
			if biome in ["glace", "cristal"]:
				_fg_icicle(ci, top, 22.0 + k * 24.0)
			else:
				_fg_vine(ci, top, 36.0 + k * 34.0)

func _front_object(ci: CanvasItem, g: Vector2, h: float, k: float) -> void:
	var s := 0.8 + (h - 0.86) * 3.0     # 0.8 → 1.2
	match biome:
		"profondeurs":
			# champignons bleus lumineux, bouquets de lucioles-champignons, fougères pâles
			if k > 0.72:
				_fg_shroom_tree(ci, g, s)
			elif k > 0.4:
				_fg_glowcaps(ci, g, s)
			elif k > 0.2:
				_fg_fern(ci, g, s)
			else:
				_fg_bush(ci, g, s)
		"jungle", "jardins":
			if k > 0.72:
				if biome == "jungle":
					_fg_tree(ci, g, s)
				else:
					_fg_shroom_tree(ci, g, s)
			elif k > 0.3:
				_fg_bush(ci, g, s)
			elif k > 0.15:
				_fg_fern(ci, g, s)
			else:
				_fg_grass(ci, g, s)
		"glace", "cristal":
			_fg_shards(ci, g, s)
		"ossuaire":
			if k > 0.6:
				_fg_giant_skull(ci, g, s)
			elif k > 0.3:
				_fg_giant_ribs(ci, g, s)
			else:
				_fg_tusk(ci, g, s)
		"ruche":
			_fg_comb(ci, g, s)
		"desert":
			if k > 0.5:
				_fg_cactus(ci, g, s)
			else:
				_fg_sandstone(ci, g, s)
		"forge":
			_fg_slag(ci, g, s)
		"antique", "citadelle":
			_fg_pillar(ci, g, s, biome == "citadelle")
		"bibliotheque":
			if k > 0.55:
				_fg_shelf(ci, g, s)
			else:
				_fg_books(ci, g, s)
		_:
			_fg_boulder(ci, g, s)

# ---- sol commun
func _ground_col() -> Color:
	match biome:
		"glace":
			return Color(0.86, 0.93, 1.0)
		"desert":
			return main.pal["rock_hi"].lightened(0.12)
		"forge":
			return Color(0.17, 0.09, 0.07)
		"ruche":
			return Color(0.72, 0.5, 0.2)
	if GRASS.get(biome, 0.5) >= 0.5:
		return main.pal["moss"].darkened(0.55)
	return main.pal["rock_hi"].darkened(0.05)

func _contact(ci: CanvasItem, g: Vector2, w: float) -> void:
	ci.draw_colored_polygon(DU.ellipse(g + Vector2(0, 1), Vector2(w * 0.6, 3.5), 14), Color(0, 0, 0, 0.3))

# butte qui recouvre la base de l'objet, avec cailloux ou herbe selon le biome
func _mound(ci: CanvasItem, g: Vector2, w: float, hgt := 6.0) -> void:
	var col := _ground_col()
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var bump := sin(t * PI) * hgt * (0.85 + 0.3 * _hash(int(g.x) + i, int(g.y)))
		pts.append(g + Vector2((t - 0.5) * w, 2.0 - bump))
	pts.append(g + Vector2(w * 0.5, 3))
	pts.append(g + Vector2(-w * 0.5, 3))
	var cols := PackedColorArray()
	for q in pts:
		cols.append(col.lightened(0.08) if q.y < g.y - hgt * 0.5 else col.darkened(0.12))
	ci.draw_polygon(pts, cols)
	ci.draw_polyline(pts.slice(1, 12), Color(col.lightened(0.3), 0.7), 1.0)
	if GRASS.get(biome, 0.5) >= 0.5 and not biome in ["glace", "desert", "ruche"]:
		var moss: Color = main.pal["moss"]
		for i in int(w / 4.0):
			var bx := g.x - w * 0.45 + i * 4.0 + _hash(i, int(g.x)) * 2.0
			var t2 := (bx - g.x) / w + 0.5
			var by := g.y + 2.0 - sin(t2 * PI) * hgt
			var hh := 4.0 + _hash(int(bx), i) * 7.0
			ci.draw_line(Vector2(bx, by), Vector2(bx + (_hash(i, 3) - 0.5) * 4.0, by - hh), moss.darkened(0.35).lerp(moss, _hash(i, 9)), 1.2)
	elif biome == "forge":
		for i in 3:
			ci.draw_circle(g + Vector2((i - 1) * w * 0.25, -1.5), 1.2, Color(1.0, 0.5, 0.15, 0.85))
	else:
		for i in 4:
			var px := g.x + (_hash(int(g.x) + i, 7) - 0.5) * w * 1.1
			ci.draw_colored_polygon(DU.ellipse(Vector2(px, g.y + 1), Vector2(2.6, 1.8), 6), col.darkened(0.25))

# polygone ombré : clair en haut, sombre en bas
func _shade_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, top_y: float, bot_y: float) -> void:
	var cols := PackedColorArray()
	for q in pts:
		var t := clampf((q.y - top_y) / maxf(bot_y - top_y, 1.0), 0.0, 1.0)
		cols.append(col.lightened(0.14 * (1.0 - t)).darkened(0.3 * t))
	ci.draw_polygon(pts, cols)

# grappe de feuillage : disques superposés, ombre en bas, reflets en haut à gauche
func _foliage(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, seed: int) -> void:
	var blobs := []
	for i in 9:
		var a := _hash(seed + i, 3) * TAU
		var d := _hash(seed, i + 11)
		blobs.append([c + Vector2(cos(a) * rx * 0.6 * d, sin(a) * ry * 0.5 * d), (0.45 + 0.35 * _hash(i, seed)) * minf(rx, ry * 1.4)])
	for b in blobs:
		ci.draw_circle(b[0] + Vector2(1.5, 2.5), b[1], col.darkened(0.35))
	for b in blobs:
		ci.draw_circle(b[0], b[1], col)
	for b in blobs:
		ci.draw_circle(b[0] + Vector2(-b[1] * 0.3, -b[1] * 0.35), b[1] * 0.45, col.lightened(0.09))
	for i in 5:
		var p := c + Vector2((_hash(seed + i, 21) - 0.5) * rx * 1.4, (_hash(seed, i + 31) - 0.6) * ry * 1.1)
		ci.draw_circle(p, 1.3, col.lightened(0.2))

func _leaf_col() -> Color:
	var moss: Color = main.pal["moss"]
	return moss.darkened(0.58).lerp(Color(0.14, 0.3, 0.14), 0.3)

# ---- végétation
func _fg_bush(ci: CanvasItem, g: Vector2, s: float) -> void:
	var w := 34.0 * s
	_contact(ci, g, w)
	_foliage(ci, g + Vector2(0, -12.0 * s), w * 0.55, 13.0 * s, _leaf_col(), int(g.x))
	if biome == "jardins":
		for i in 3:
			var p := g + Vector2((i - 1) * 9.0 * s, -18.0 * s - (i % 2) * 6.0)
			ci.draw_circle(p, 2.4, Color(0.95, 0.45, 0.4) if i != 1 else Color(0.5, 0.9, 0.85))
	elif biome == "jungle":
		for sd in [-1.0, 1.0]:
			var b0: Vector2 = g + Vector2(sd * w * 0.35, -6.0)
			ci.draw_colored_polygon(PackedVector2Array([b0, b0 + Vector2(sd * 16.0, -10.0), b0 + Vector2(sd * 22.0, -4.0), b0 + Vector2(sd * 12.0, 2.0)]), _leaf_col().lightened(0.08))
	_mound(ci, g, w * 0.9, 4.0)

func _fg_tree(ci: CanvasItem, g: Vector2, s: float) -> void:
	# arbre de la jungle : tronc qui s'évase en racines, couronne de feuillage
	var hgt := 78.0 * s
	var bark := Color(0.24, 0.18, 0.12).lerp(main.pal["rock"], 0.3)
	_contact(ci, g, 40.0 * s)
	var trunk := PackedVector2Array([g + Vector2(-9 * s, 2), g + Vector2(-4 * s, -8), g + Vector2(-3 * s, -hgt * 0.7), g + Vector2(-1, -hgt),
		g + Vector2(2 * s, -hgt), g + Vector2(4 * s, -hgt * 0.7), g + Vector2(5 * s, -8), g + Vector2(11 * s, 2)])
	_shade_poly(ci, trunk, bark.lightened(0.1), g.y - hgt, g.y)
	ci.draw_line(g + Vector2(-2 * s, -10), g + Vector2(-1.5 * s, -hgt * 0.65), Color(0, 0, 0, 0.25), 1.2)
	ci.draw_line(g + Vector2(-3.5 * s, -10), g + Vector2(-2.5 * s, -hgt * 0.6), Color(1, 1, 1, 0.12), 1.0)
	for sd in [-1.0, 1.0]:
		var r0: Vector2 = g + Vector2(sd * 4.0 * s, -4)
		ci.draw_polyline(PackedVector2Array([r0, r0 + Vector2(sd * 8.0 * s, 2), r0 + Vector2(sd * 14.0 * s, 6)]), bark, 3.0)
	var br: Vector2 = g + Vector2(2, -hgt * 0.62)
	ci.draw_line(br, br + Vector2(14 * s, -10 * s), bark, 3.0)
	_foliage(ci, g + Vector2(0, -hgt - 4), 30.0 * s, 20.0 * s, _leaf_col(), int(g.x) + 3)
	_foliage(ci, g + Vector2(16 * s, -hgt * 0.72), 14.0 * s, 9.0 * s, _leaf_col().darkened(0.05), int(g.x) + 7)
	_mound(ci, g, 34.0 * s, 5.0)

func _fg_shroom_tree(ci: CanvasItem, g: Vector2, s: float) -> void:
	# champignon géant des jardins / des profondeurs, chapeau tacheté et lamelles lumineuses
	var hgt := 62.0 * s
	var stem := Color(0.82, 0.78, 0.68)
	var cap := Color(0.72, 0.28, 0.25) if biome == "jardins" else Color(0.25, 0.45, 0.6)
	_contact(ci, g, 30.0 * s)
	var st := PackedVector2Array([g + Vector2(-8 * s, 2), g + Vector2(-5 * s, -hgt * 0.5), g + Vector2(-4 * s, -hgt), g + Vector2(4 * s, -hgt), g + Vector2(5 * s, -hgt * 0.5), g + Vector2(8 * s, 2)])
	_shade_poly(ci, st, stem, g.y - hgt, g.y)
	var cc := g + Vector2(0, -hgt)
	var capp := DU.ellipse(cc, Vector2(28 * s, 18 * s), 20, PI, TAU)
	capp.append(cc + Vector2(28 * s, 0))
	_shade_poly(ci, capp, cap, cc.y - 18 * s, cc.y)
	ci.draw_line(cc + Vector2(-27 * s, 0), cc + Vector2(27 * s, 0), main.pal["moss"].lightened(0.2), 2.0)
	for i in 5:
		var p := cc + Vector2((_hash(int(g.x), i) - 0.5) * 36 * s, -4 - _hash(i, int(g.y)) * 11 * s)
		ci.draw_circle(p, 2.2 + _hash(i, 5) * 2.0, Color(1, 0.95, 0.85, 0.85))
	ci.draw_arc(cc, 26 * s, PI * 1.15, PI * 1.45, 6, Color(1, 1, 1, 0.3), 1.5)
	_mound(ci, g, 26.0 * s, 5.0)

func _fg_fern(ci: CanvasItem, g: Vector2, s: float) -> void:
	var col := _leaf_col().lightened(0.05)
	var span := 34.0 * s
	_contact(ci, g, span)
	for sd in [-1.0, 1.0]:
		for j in 2:
			var sp := span * (1.0 - j * 0.3)
			var pts := PackedVector2Array()
			for i in 9:
				var t := i / 8.0
				pts.append(g + Vector2(sd * t * sp * 0.9, -sin(t * PI * 0.8) * sp * 0.9 - 3.0))
			for i in range(1, 8):
				var a := pts[i]
				var leaf: float = (1.0 - absf(i / 8.0 - 0.45)) * 7.0
				ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(sd * 3.0, -leaf), a + Vector2(sd * 6.0, -leaf * 0.3), a + Vector2(sd * 2.0, leaf * 0.6)]), col if j == 0 else col.darkened(0.15))
			ci.draw_polyline(pts, col.darkened(0.2), 1.8)
	_mound(ci, g, 22.0 * s, 4.0)

func _fg_grass(ci: CanvasItem, g: Vector2, s: float) -> void:
	var col := _leaf_col()
	_contact(ci, g, 30.0 * s)
	for i in 11:
		var t := i / 10.0
		var bx := g.x + (t - 0.5) * 28.0 * s
		var hh := 30.0 * s * (0.5 + 0.5 * sin(t * PI)) * (0.75 + _hash(int(bx), int(g.y)) * 0.5)
		var lean := (t - 0.5) * 16.0 + sin(i * 2.3) * 4.0
		var b0 := Vector2(bx, g.y)
		var c2 := col.lerp(col.lightened(0.25), _hash(i, int(g.x)))
		ci.draw_colored_polygon(PackedVector2Array([b0 + Vector2(-2, 0), b0 + Vector2(lean * 0.4 - 1, -hh * 0.55), b0 + Vector2(lean, -hh), b0 + Vector2(lean * 0.4 + 1, -hh * 0.55), b0 + Vector2(2, 0)]), c2)
	_mound(ci, g, 26.0 * s, 3.5)

# bouquet de petits champignons bioluminescents (Profondeurs)
func _fg_glowcaps(ci: CanvasItem, g: Vector2, s: float) -> void:
	_contact(ci, g, 36.0 * s)
	var glow := Color(0.55, 0.85, 1.0)
	var n := 4 + int(_hash(int(g.x), 3) * 3.0)
	for i in n:
		var ox := (i - (n - 1) / 2.0) * 8.0 * s + (_hash(i, int(g.x)) - 0.5) * 6.0
		var hh := (10.0 + _hash(int(g.y), i) * 22.0) * s
		var b := g + Vector2(ox, 1)
		var tip := b + Vector2((_hash(i, 9) - 0.5) * 6.0, -hh)
		ci.draw_line(b, tip, Color(0.78, 0.82, 0.9), 2.4 * s)
		var r := (4.0 + _hash(i, int(g.x) + 1) * 4.0) * s
		ci.draw_circle(tip, r * 2.4, Color(glow, 0.12))
		var cap := DU.ellipse(tip, Vector2(r * 1.3, r), 14, PI, TAU)
		cap.append(tip + Vector2(r * 1.3, 0))
		ci.draw_colored_polygon(cap, Color(0.3, 0.55, 0.75).lerp(glow, 0.35))
		ci.draw_line(tip + Vector2(-r * 1.2, 0), tip + Vector2(r * 1.2, 0), glow.lightened(0.3), 1.5)
		ci.draw_circle(tip + Vector2(-r * 0.3, -r * 0.45), r * 0.25, Color(1, 1, 1, 0.7))
	_mound(ci, g, 30.0 * s, 4.0)

func _fg_vine(ci: CanvasItem, top: Vector2, l: float) -> void:
	if biome == "profondeurs":
		_fg_glowworm(ci, top, l)
		return
	var col := _leaf_col()
	var pts := PackedVector2Array()
	for i in 10:
		var t := i / 9.0
		pts.append(top + Vector2(sin(t * 4.0 + top.x) * 5.0, t * l))
	ci.draw_polyline(pts, Color(0.22, 0.17, 0.1).lerp(col, 0.3), 2.2)
	for i in range(1, 10):
		var a := pts[i]
		var sd := 1.0 if i % 2 == 0 else -1.0
		ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(sd * 8.0, 1.0), a + Vector2(sd * 5.0, 6.0), a + Vector2(sd * 1.0, 4.0)]), col.lerp(col.lightened(0.2), _hash(i, int(top.x))))
	# racines et terre au point d'accroche
	ci.draw_colored_polygon(DU.ellipse(top + Vector2(0, 1), Vector2(8, 3), 10), main.pal["rock"].lightened(0.15))

# fils de vers luisants qui pendent du plafond (Profondeurs) : perles de lumière bleue
func _fg_glowworm(ci: CanvasItem, top: Vector2, l: float) -> void:
	for j in 3:
		var x0 := top + Vector2((j - 1) * 7.0 + (_hash(j, int(top.x)) - 0.5) * 4.0, 0)
		var ll := l * (0.55 + _hash(int(top.x), j) * 0.6)
		ci.draw_line(x0, x0 + Vector2(0, ll), Color(0.7, 0.85, 1.0, 0.35), 1.0)
		var beads := int(ll / 9.0)
		for i in beads:
			var p := x0 + Vector2(0, 6.0 + i * 9.0 + _hash(i, j) * 3.0)
			var r := 1.3 + _hash(i + 3, j) * 1.2
			ci.draw_circle(p, r * 2.6, Color(0.5, 0.8, 1.0, 0.13))
			ci.draw_circle(p, r, Color(0.75, 0.92, 1.0, 0.95))
	ci.draw_colored_polygon(DU.ellipse(top + Vector2(0, 1), Vector2(9, 3), 10), main.pal["rock"].lightened(0.15))

# ---- glace et cristal : amas qui perce une dalle soulevée
func _fg_shards(ci: CanvasItem, g: Vector2, s: float) -> void:
	var crys: Color = Color(0.72, 0.88, 1.0) if biome == "glace" else main.pal["moss"]
	_contact(ci, g, 40.0 * s)
	# dalle de roche soulevée par les cristaux
	var rock: Color = main.pal["rock_hi"]
	var slab := PackedVector2Array([g + Vector2(-20 * s, 2), g + Vector2(-16 * s, -7 * s), g + Vector2(-4 * s, -10 * s), g + Vector2(2 * s, -5 * s), g + Vector2(-2 * s, 2)])
	_shade_poly(ci, slab, rock, g.y - 10 * s, g.y)
	var angs := [-0.45, -0.12, 0.2, 0.5]
	var lens := [26.0, 44.0, 34.0, 20.0]
	for i in 4:
		var a: float = angs[i]
		var l: float = lens[i] * s
		var dir := Vector2(sin(a), -cos(a))
		var nrm := Vector2(dir.y, -dir.x)
		var w := 5.5 * s
		var b0 := g + Vector2((i - 1.5) * 7.0 * s, 0)
		var body := PackedVector2Array([b0 - nrm * w, b0 + dir * l * 0.78 - nrm * w * 0.9, b0 + dir * l, b0 + dir * l * 0.78 + nrm * w * 0.9, b0 + nrm * w])
		var c2 := crys.darkened(0.1 + 0.1 * (i % 2))
		c2.a = 0.9
		ci.draw_colored_polygon(body, c2)
		# facette claire et arête
		ci.draw_colored_polygon(PackedVector2Array([b0 - nrm * w, b0 + dir * l * 0.78 - nrm * w * 0.9, b0 + dir * l, b0]), Color(crys.lightened(0.35), 0.55))
		ci.draw_line(b0, b0 + dir * l, Color(1, 1, 1, 0.5), 1.0)
	if biome == "cristal":
		DU.glow(ci, g + Vector2(0, -22 * s), 26.0 * s, crys, 0.18)
	_mound(ci, g, 40.0 * s, 4.0)

func _fg_icicle(ci: CanvasItem, top: Vector2, l: float) -> void:
	var crys: Color = Color(0.75, 0.9, 1.0, 0.88) if biome == "glace" else Color(main.pal["moss"], 0.85)
	for i in 3:
		var x0 := top.x + (i - 1) * 6.0
		var li := l * (1.0 if i == 1 else 0.55)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 - 3.5, top.y), Vector2(x0 + 3.5, top.y), Vector2(x0 + 0.8, top.y + li * 0.7), Vector2(x0, top.y + li)]), crys)
		ci.draw_line(Vector2(x0 - 1.5, top.y + 1), Vector2(x0 - 0.2, top.y + li * 0.8), Color(1, 1, 1, 0.6), 1.0)

# ---- ossuaire : os de monstres géants d'autrefois, à demi enterrés
func _bone_col() -> Color:
	return Color(0.72, 0.67, 0.56)

func _fg_giant_skull(ci: CanvasItem, g: Vector2, s: float) -> void:
	var bone := _bone_col()
	var w := 60.0 * s
	_contact(ci, g, w)
	# crâne allongé de bête, enfoncé dans le sol, la mâchoire disparaît sous la terre
	var cr := g + Vector2(-4 * s, -14 * s)
	var head := PackedVector2Array([g + Vector2(-30 * s, 2), cr + Vector2(-26 * s, -8 * s), cr + Vector2(-14 * s, -20 * s), cr + Vector2(4 * s, -22 * s),
		cr + Vector2(20 * s, -14 * s), cr + Vector2(34 * s, -6 * s), cr + Vector2(36 * s, 4 * s), g + Vector2(30 * s, 2)])
	_shade_poly(ci, head, bone, cr.y - 22 * s, g.y)
	# orbite, narine, fêlures
	ci.draw_colored_polygon(DU.ellipse(cr + Vector2(-6 * s, -8 * s), Vector2(7 * s, 6 * s), 12), Color(0.12, 0.09, 0.07))
	ci.draw_colored_polygon(DU.ellipse(cr + Vector2(24 * s, -2 * s), Vector2(3 * s, 2 * s), 8), Color(0.15, 0.11, 0.08))
	ci.draw_polyline(PackedVector2Array([cr + Vector2(8 * s, -20 * s), cr + Vector2(10 * s, -12 * s), cr + Vector2(6 * s, -6 * s)]), Color(0.3, 0.25, 0.2, 0.7), 1.0)
	# corne recourbée
	var hpts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		hpts.append(cr + Vector2(-16 * s - t * 16 * s, -16 * s - sin(t * 2.0) * 22 * s))
	ci.draw_polyline(hpts, bone.darkened(0.12), 6.0 * s)
	ci.draw_polyline(hpts.slice(0, 6), bone.darkened(0.12), 8.0 * s)
	# dents qui sortent du sol
	for i in 4:
		var tx := g.x + (6 + i * 6) * s
		ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2.5 * s, g.y), Vector2(tx + 2.5 * s, g.y), Vector2(tx, g.y - (7 - i) * s)]), bone.lightened(0.05))
	ci.draw_polyline(PackedVector2Array([head[1], head[2], head[3], head[4]]), Color(1, 1, 1, 0.35), 1.2)
	_mound(ci, g, w * 1.05, 6.0)

func _fg_giant_ribs(ci: CanvasItem, g: Vector2, s: float) -> void:
	# côtes d'une carcasse colossale qui jaillissent du sol en arcs
	var bone := _bone_col()
	_contact(ci, g, 60.0 * s)
	for i in 3:
		var bx := g.x + (i - 1) * 16.0 * s
		var hgt := (58.0 - i * 9.0) * s
		var pts := PackedVector2Array()
		for j in 10:
			var t := j / 9.0
			pts.append(Vector2(bx + sin(t * PI * 0.62) * 22.0 * s, g.y + 2 - sin(t * PI * 0.95) * hgt))
		var wdt := (6.0 - i) * s
		ci.draw_polyline(pts, bone.darkened(0.25), wdt + 2.0)
		ci.draw_polyline(pts, bone.darkened(0.05 * i), wdt)
		ci.draw_polyline(pts.slice(1, 6), Color(1, 1, 1, 0.3), 1.0)
	# vertèbre d'où partent les côtes
	for i in 3:
		ci.draw_colored_polygon(DU.ellipse(g + Vector2((i - 1) * 16.0 * s - 2, -2), Vector2(6 * s, 4 * s), 10), bone.darkened(0.15))
	_mound(ci, g, 64.0 * s, 6.0)

func _fg_tusk(ci: CanvasItem, g: Vector2, s: float) -> void:
	var bone := _bone_col()
	_contact(ci, g, 36.0 * s)
	var pts := PackedVector2Array()
	var pts2 := PackedVector2Array()
	for i in 10:
		var t := i / 9.0
		var c := g + Vector2(-8 * s + t * 26 * s * t, -t * 56 * s)
		var w := (8.0 - t * 7.5) * s
		pts.append(c + Vector2(-w, 0))
		pts2.insert(0, c + Vector2(w, 0))
	pts.append_array(pts2)
	_shade_poly(ci, pts, bone, g.y - 56 * s, g.y)
	for i in 3:
		var yy := g.y - (12 + i * 12) * s
		ci.draw_line(Vector2(g.x - 8 * s + i * 2, yy), Vector2(g.x - 1 * s + i * 3, yy - 2), Color(0.35, 0.3, 0.24, 0.6), 1.0)
	_mound(ci, g, 30.0 * s, 6.0)

# ---- ruche
func _fg_comb(ci: CanvasItem, g: Vector2, s: float) -> void:
	var wax := Color(0.86, 0.6, 0.22)
	_contact(ci, g, 40.0 * s)
	var hgt := 34.0 * s
	var pts := PackedVector2Array()
	for i in 7:
		var a := PI + i * PI / 6.0
		pts.append(g + Vector2(cos(a) * 20 * s, sin(a) * hgt))
	_shade_poly(ci, pts, wax, g.y - hgt, g.y)
	for row in 3:
		for col in 3:
			var c := g + Vector2((col - 1) * 9 * s + (row % 2) * 4.5 * s, -8 * s - row * 8 * s)
			if c.distance_to(g) < 19 * s:
				ci.draw_polyline(DU.ellipse(c, Vector2(4.2 * s, 4.2 * s), 6), Color(0.5, 0.3, 0.08, 0.8), 1.0)
				ci.draw_circle(c, 2.0 * s, Color(1.0, 0.75, 0.25, 0.8))
	ci.draw_line(g + Vector2(6 * s, -hgt * 0.4), g + Vector2(7 * s, 0), Color(1.0, 0.72, 0.2, 0.9), 2.4)
	_mound(ci, g, 40.0 * s, 4.0)

# ---- désert
func _fg_cactus(ci: CanvasItem, g: Vector2, s: float) -> void:
	var col := Color(0.38, 0.52, 0.28)
	var hgt := 50.0 * s
	var w := 7.0 * s
	_contact(ci, g, 30.0 * s)
	_shade_poly(ci, PackedVector2Array([g + Vector2(-w, 2), g + Vector2(-w, -hgt + w), g + Vector2(-w * 0.5, -hgt), g + Vector2(w * 0.5, -hgt), g + Vector2(w, -hgt + w), g + Vector2(w, 2)]), col, g.y - hgt, g.y)
	for sd in [-1.0, 1.0]:
		var ay: float = g.y - hgt * (0.45 if sd < 0 else 0.62)
		var ax: float = g.x + sd * w
		var arm := PackedVector2Array([Vector2(ax, ay), Vector2(ax + sd * 9 * s, ay), Vector2(ax + sd * 9 * s, ay - hgt * 0.3), Vector2(ax + sd * 14 * s, ay - hgt * 0.3), Vector2(ax + sd * 14 * s, ay + 5), Vector2(ax, ay + 5)])
		_shade_poly(ci, arm, col, ay - hgt * 0.3, ay + 5)
	for i in 3:
		var lx := g.x - w * 0.5 + i * w * 0.5
		ci.draw_line(Vector2(lx, g.y - hgt + 6), Vector2(lx, g.y), Color(0, 0, 0, 0.18), 1.0)
	ci.draw_line(g + Vector2(-w + 1, -hgt + w), g + Vector2(-w + 1, 0), Color(1, 1, 0.8, 0.3), 1.0)
	ci.draw_circle(g + Vector2(0, -hgt - 1), 2.5, Color(0.95, 0.5, 0.6))
	_mound(ci, g, 34.0 * s, 6.0)

func _fg_sandstone(ci: CanvasItem, g: Vector2, s: float) -> void:
	# rocher de grès strié, à moitié ensablé
	var sand: Color = main.pal["rock_hi"]
	var hgt := 30.0 * s
	var w := 34.0 * s
	_contact(ci, g, w)
	var pts := PackedVector2Array([g + Vector2(-w * 0.55, 2), g + Vector2(-w * 0.45, -hgt * 0.7), g + Vector2(-w * 0.1, -hgt), g + Vector2(w * 0.35, -hgt * 0.85), g + Vector2(w * 0.55, 2)])
	_shade_poly(ci, pts, sand.darkened(0.05), g.y - hgt, g.y)
	for i in 3:
		var yy := g.y - hgt * (0.25 + i * 0.22)
		ci.draw_line(Vector2(g.x - w * 0.45, yy), Vector2(g.x + w * 0.45, yy - 3), Color(sand.darkened(0.4), 0.6), 1.2)
	ci.draw_polyline(PackedVector2Array([pts[1], pts[2], pts[3]]), Color(1, 0.95, 0.8, 0.35), 1.2)
	_mound(ci, g, w * 1.3, 8.0)

# ---- forge
func _fg_slag(ci: CanvasItem, g: Vector2, s: float) -> void:
	var hgt := 30.0 * s
	var w := 30.0 * s
	_contact(ci, g, w)
	var pts := PackedVector2Array([g + Vector2(-w * 0.6, 2), g + Vector2(-w * 0.5, -hgt * 0.5), g + Vector2(-w * 0.15, -hgt), g + Vector2(w * 0.25, -hgt * 0.75), g + Vector2(w * 0.55, -hgt * 0.35), g + Vector2(w * 0.6, 2)])
	_shade_poly(ci, pts, Color(0.24, 0.13, 0.09), g.y - hgt, g.y)
	var ember := Color(1.0, 0.5, 0.15, 0.9)
	ci.draw_polyline(PackedVector2Array([g + Vector2(-w * 0.15, -hgt * 0.85), g + Vector2(-w * 0.05, -hgt * 0.5), g + Vector2(-w * 0.2, -hgt * 0.25), g + Vector2(-w * 0.1, 0)]), ember, 1.6)
	ci.draw_polyline(PackedVector2Array([g + Vector2(w * 0.3, -hgt * 0.5), g + Vector2(w * 0.1, -hgt * 0.3)]), ember, 1.2)
	DU.glow(ci, g + Vector2(-w * 0.05, -hgt * 0.5), 12.0, Color(1.0, 0.45, 0.1), 0.2)
	ci.draw_polyline(PackedVector2Array([pts[1], pts[2], pts[3]]), Color(1.0, 0.6, 0.3, 0.4), 1.0)
	_mound(ci, g, w * 1.2, 5.0)

# ---- temple et citadelle : colonne brisée dont la base est prise dans les gravats
func _fg_pillar(ci: CanvasItem, g: Vector2, s: float, bricks := false) -> void:
	bricks = bricks or biome == "citadelle"
	var st: Color = main.pal["rock_hi"].lightened(0.12 if bricks else 0.02)
	var hgt := 58.0 * s
	var w := 9.0 * s
	var cut := hgt * 0.18
	_contact(ci, g, 34.0 * s)
	var shaft := PackedVector2Array([g + Vector2(-w, 0), g + Vector2(-w, -hgt + cut), g + Vector2(-w * 0.3, -hgt + cut * 0.3), g + Vector2(w * 0.2, -hgt), g + Vector2(w, -hgt + cut * 0.6), g + Vector2(w, 0)])
	_shade_poly(ci, shaft, st, g.y - hgt, g.y)
	if bricks:
		var yy := g.y - 9.0
		var row := 0
		while yy > g.y - hgt + cut:
			ci.draw_line(Vector2(g.x - w, yy), Vector2(g.x + w, yy), Color(0, 0, 0, 0.3), 1.0)
			var mx := g.x + (-2.0 if row % 2 == 0 else 3.0)
			ci.draw_line(Vector2(mx, yy), Vector2(mx, yy + 9), Color(0, 0, 0, 0.25), 1.0)
			yy -= 9.0
			row += 1
	else:
		for i in 3:
			var fx := g.x - w * 0.55 + i * w * 0.55
			ci.draw_line(Vector2(fx, g.y - 4), Vector2(fx, g.y - hgt + cut + 3), Color(0, 0, 0, 0.22), 1.4)
	ci.draw_line(g + Vector2(-w + 1, -4), g + Vector2(-w + 1, -hgt + cut), Color(1, 1, 1, 0.25), 1.0)
	# tambour tombé à côté
	var dr := g + Vector2(20 * s, -5 * s)
	ci.draw_colored_polygon(DU.ellipse(dr, Vector2(8 * s, 6 * s), 12), st.darkened(0.1))
	ci.draw_arc(dr, 6 * s, PI, TAU, 8, Color(0, 0, 0, 0.25), 1.0)
	_mound(ci, g, 46.0 * s, 6.0)

# ---- bibliothèque : pupitre de lecture, grand chandelier, globe terrestre
func _fg_books(ci: CanvasItem, g: Vector2, s: float) -> void:
	# pupitre en bois sur pied, parchemin déroulé
	var wood := Color(0.4, 0.26, 0.15)
	var hgt := 40.0 * s
	_contact(ci, g, 30.0 * s)
	ci.draw_colored_polygon(PackedVector2Array([g + Vector2(-12 * s, 2), g + Vector2(12 * s, 2), g + Vector2(5 * s, -5 * s), g + Vector2(-5 * s, -5 * s)]), wood.darkened(0.2))
	_shade_poly(ci, PackedVector2Array([g + Vector2(-3 * s, -4 * s), g + Vector2(3 * s, -4 * s), g + Vector2(3 * s, -hgt), g + Vector2(-3 * s, -hgt)]), wood, g.y - hgt, g.y)
	var top := PackedVector2Array([g + Vector2(-16 * s, -hgt + 2), g + Vector2(14 * s, -hgt - 9 * s), g + Vector2(16 * s, -hgt - 5 * s), g + Vector2(-14 * s, -hgt + 6)])
	ci.draw_colored_polygon(top, wood.lightened(0.15))
	var scroll := PackedVector2Array([g + Vector2(-12 * s, -hgt - 1), g + Vector2(11 * s, -hgt - 10 * s), g + Vector2(12 * s, -hgt - 7 * s), g + Vector2(-11 * s, -hgt + 2)])
	ci.draw_colored_polygon(scroll, Color(0.92, 0.86, 0.7))
	for i in 3:
		var a := g + Vector2(-8 * s + i * 2, -hgt - 1.5 - i * 2.4 * s)
		ci.draw_line(a, a + Vector2(14 * s, -6 * s), Color(0.35, 0.3, 0.3, 0.6), 0.8)
	ci.draw_circle(g + Vector2(-12 * s, -hgt + 0.5), 2.2 * s, Color(0.85, 0.78, 0.6))
	ci.draw_circle(g + Vector2(12 * s, -hgt - 8.5 * s), 2.2 * s, Color(0.85, 0.78, 0.6))
	_mound(ci, g, 24.0 * s, 3.0)

func _fg_shelf(ci: CanvasItem, g: Vector2, s: float) -> void:
	# grand chandelier de laiton à trois branches, ou globe terrestre sur son pied
	var brass := Color(0.78, 0.6, 0.3)
	_contact(ci, g, 26.0 * s)
	if _hash(int(g.x), 41) > 0.5:
		var hgt := 64.0 * s
		ci.draw_colored_polygon(PackedVector2Array([g + Vector2(-10 * s, 2), g + Vector2(10 * s, 2), g + Vector2(3 * s, -6 * s), g + Vector2(-3 * s, -6 * s)]), brass.darkened(0.3))
		ci.draw_line(g + Vector2(0, -4 * s), g + Vector2(0, -hgt), brass, 3.0 * s)
		for k in [0.3, 0.6]:
			ci.draw_circle(g + Vector2(0, -hgt * k), 2.6 * s, brass.lightened(0.2))
		for sd in [-1.0, 0.0, 1.0]:
			var tip := g + Vector2(sd * 14.0 * s, -hgt - (0.0 if sd == 0.0 else -6.0 * s))
			if sd != 0.0:
				ci.draw_polyline(PackedVector2Array([g + Vector2(0, -hgt + 12 * s), g + Vector2(sd * 12 * s, -hgt + 10 * s), tip]), brass, 2.0 * s)
			ci.draw_rect(Rect2(tip + Vector2(-2 * s, -9 * s), Vector2(4 * s, 9 * s)), Color(0.93, 0.9, 0.8))
			ci.draw_circle(tip + Vector2(0, -12 * s), 6.0 * s, Color(1.0, 0.75, 0.4, 0.25))
			DU.flat(ci, DU.ellipse(tip + Vector2(0, -12 * s), Vector2(1.6 * s, 3.0 * s)), Color(1.0, 0.85, 0.45))
	else:
		var hgt := 44.0 * s
		var c := g + Vector2(0, -hgt)
		ci.draw_line(g + Vector2(-9 * s, 2), g + Vector2(0, -12 * s), Color(0.36, 0.24, 0.14), 2.5 * s)
		ci.draw_line(g + Vector2(9 * s, 2), g + Vector2(0, -12 * s), Color(0.36, 0.24, 0.14), 2.5 * s)
		ci.draw_line(g + Vector2(0, -12 * s), c + Vector2(0, 13 * s), Color(0.36, 0.24, 0.14), 2.5 * s)
		ci.draw_circle(c, 12.0 * s, Color(0.3, 0.45, 0.55))
		for i in 3:
			var p := c + Vector2((_hash(int(g.x), i) - 0.5) * 14 * s, (_hash(i, int(g.y)) - 0.5) * 14 * s)
			ci.draw_colored_polygon(DU.ellipse(p, Vector2(4 * s, 3 * s), 8), Color(0.75, 0.65, 0.4))
		ci.draw_arc(c, 14.0 * s, -PI * 0.6, PI * 0.9, 16, brass, 2.0)
		ci.draw_arc(c, 10.0 * s, PI * 1.1, PI * 1.4, 6, Color(1, 1, 1, 0.3), 1.5)
	_mound(ci, g, 22.0 * s, 3.0)

func _fg_boulder(ci: CanvasItem, g: Vector2, s: float) -> void:
	var st: Color = main.pal["rock_hi"]
	var hgt := 26.0 * s
	var w := 34.0 * s
	_contact(ci, g, w)
	var pts := DU.ellipse(g + Vector2(0, 2), Vector2(w * 0.5, hgt), 14, PI, TAU)
	_shade_poly(ci, pts, st, g.y - hgt, g.y)
	ci.draw_polyline(PackedVector2Array([g + Vector2(-4, -hgt * 0.8), g + Vector2(0, -hgt * 0.4), g + Vector2(-3, -2)]), Color(0, 0, 0, 0.25), 1.2)
	ci.draw_arc(g + Vector2(0, 2), w * 0.45, PI * 1.15, PI * 1.5, 6, Color(1, 1, 1, 0.25), 1.2)
	_mound(ci, g, w * 1.2, 5.0)

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

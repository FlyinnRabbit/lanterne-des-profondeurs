extends CanvasLayer
# Carte du niveau (touche Carte) : cases déjà vues, banc, sortie, ombre, objets, joueur.
# main.explored garde les cases découvertes (la Plume du cartographe révèle tout).
var main
var view: Control

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_map)
	add_child(view)
	visible = false

func toggle() -> void:
	if visible:
		visible = false
		get_tree().paused = false
	elif not get_tree().paused:
		visible = true
		get_tree().paused = true
		view.queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if main.menu.visible or (main.inventory and main.inventory.visible) or main.hub_ui.visible:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and (event.is_action_pressed("pause_menu") or event.is_action_pressed("inventory") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		toggle()
		get_viewport().set_input_as_handled()

# Carte façon parchemin : la roche est tracée à l'encre sépia, le vide laisse voir le papier
const INK := Color(0.33, 0.22, 0.13)
const PAPER := Color(0.86, 0.78, 0.6)

static func cell_color(ch: String, pal: Dictionary) -> Color:
	match ch:
		"#": return Color(0.52, 0.4, 0.27)
		"^": return Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.7, 0.15, 0.12)
		"C": return Color(0.62, 0.48, 0.32)
		"H": return Color(0.3, 0.45, 0.6)
	return Color(0, 0, 0, 0)

# feuille de parchemin : bords irréguliers, taches, bords brûlés
static func draw_paper(ci: CanvasItem, r: Rect2, seed_v: int, alpha: float = 1.0) -> void:
	# carte perdue : bords déchirés, coin arraché, plis, taches, brûlures
	var pts := PackedVector2Array()
	var n := 128
	var corner := Vector2(r.position.x, r.end.y)
	for i in n:
		var u := float(i) / n
		var j: float = sin(i * 12.9898 + seed_v) * 3.5 + sin(i * 1.7 + seed_v * 0.3) * 4.0
		if fposmod(sin(i * 91.7 + seed_v) * 43758.5, 1.0) > 0.9:
			j -= 9.0   # petite encoche
		var q: Vector2
		if u < 0.25:
			q = Vector2(r.position.x + r.size.x * u * 4.0, r.position.y - j)
		elif u < 0.5:
			q = Vector2(r.end.x + j, r.position.y + r.size.y * (u - 0.25) * 4.0)
		elif u < 0.75:
			q = Vector2(r.end.x - r.size.x * (u - 0.5) * 4.0, r.end.y + j)
		else:
			q = Vector2(r.position.x - j, r.end.y - r.size.y * (u - 0.75) * 4.0)
		# coin bas-gauche arraché
		var dsum: float = (q.x - corner.x) + (corner.y - q.y)
		var lim: float = 86.0 + sin(i * 2.3) * 7.0
		if dsum < lim:
			var push := (lim - dsum) / 2.0
			q += Vector2(push, -push)
		pts.append(q)
	var c := r.get_center()
	var cols := PackedColorArray()
	for q in pts:
		var k := clampf((q - c).length() / (r.size.length() * 0.5), 0.0, 1.0)
		cols.append(Color(PAPER.lerp(Color(0.45, 0.32, 0.18), k * k), alpha))
	ci.draw_polygon(pts, cols)
	var edge := pts.duplicate()
	edge.append(pts[0])
	ci.draw_polyline(edge, Color(0.2, 0.11, 0.05, 0.22), 14.0)
	ci.draw_polyline(edge, Color(0.16, 0.09, 0.04, 0.4), 7.0)
	ci.draw_polyline(edge, Color(0.1, 0.06, 0.03, minf(1.0, alpha + 0.15)), 2.5)
	# plis
	for fx: float in [0.333, 0.667]:
		var x: float = r.position.x + r.size.x * fx
		ci.draw_line(Vector2(x, r.position.y + 6), Vector2(x, r.end.y - 6), Color(0.3, 0.2, 0.1, 0.22), 2.0)
		ci.draw_line(Vector2(x + 2, r.position.y + 6), Vector2(x + 2, r.end.y - 6), Color(1.0, 0.95, 0.8, 0.14), 1.5)
	var fy: float = r.position.y + r.size.y * 0.5
	ci.draw_line(Vector2(r.position.x + 6, fy), Vector2(r.end.x - 6, fy), Color(0.3, 0.2, 0.1, 0.22), 2.0)
	ci.draw_line(Vector2(r.position.x + 6, fy + 2), Vector2(r.end.x - 6, fy + 2), Color(1.0, 0.95, 0.8, 0.14), 1.5)
	# taches d'humidité
	for i in 9:
		var sp := r.position + Vector2(40.0 + fposmod(sin(i * 7.1 + seed_v) * 999.0, r.size.x - 80.0), 40.0 + fposmod(cos(i * 3.7 + seed_v) * 999.0, r.size.y - 80.0))
		var rad: float = 8.0 + fposmod(i * 13.0, 22.0)
		ci.draw_circle(sp, rad, Color(0.5, 0.36, 0.2, 0.09))
		ci.draw_arc(sp, rad, 0.0, TAU, 24, Color(0.4, 0.27, 0.14, 0.12), 1.5)
	# trous de brûlure
	for i in 2:
		var bp := Vector2(r.end.x - 70.0 - fposmod(sin(i * 5.3 + seed_v) * 777.0, 120.0), r.position.y + 36.0 + i * (r.size.y * 0.45) + fposmod(cos(i * 9.1 + seed_v) * 555.0, 40.0))
		var br: float = 9.0 + i * 4.0
		ci.draw_circle(bp, br + 7.0, Color(0.25, 0.14, 0.06, 0.3))
		ci.draw_circle(bp, br + 3.0, Color(0.12, 0.07, 0.03, 0.6))
		ci.draw_circle(bp, br, Color(0.02, 0.02, 0.04, 0.8))

func _draw_map() -> void:
	var sz := view.size
	var font := ThemeDB.fallback_font
	view.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.03, 0.45))
	# parchemin plus petit, centré à l'écran
	var psz := Vector2(sz.x * 0.66, sz.y * 0.66)
	var pr := Rect2((sz - psz) / 2.0, psz)
	var mid := pr.position.x + psz.x / 2.0
	var piv := pr.get_center()
	view.draw_set_transform(piv - piv.rotated(-0.025), -0.025)
	draw_paper(view, pr, int(main.level.get("seed", 0)), 0.78)
	var title := tr("Carte") + " — " + tr(main.level["name"])
	view.draw_string(font, Vector2(pr.position.x, pr.position.y + 38), title, HORIZONTAL_ALIGNMENT_CENTER, psz.x, 24, INK)
	view.draw_line(Vector2(mid - 150, pr.position.y + 47), Vector2(mid + 150, pr.position.y + 47), Color(INK, 0.6), 1.5)
	# rose des vents
	var rc := pr.end - Vector2(50, 50)
	view.draw_arc(rc, 18.0, 0.0, TAU, 24, Color(INK, 0.7), 1.5)
	for k in 4:
		var a := k * PI / 2.0 - PI / 2.0
		view.draw_colored_polygon(PackedVector2Array([rc + Vector2.from_angle(a) * 23.0, rc + Vector2.from_angle(a + 0.35) * 6.0, rc, rc + Vector2.from_angle(a - 0.35) * 6.0]), Color(INK, 0.85) if k == 0 else Color(INK, 0.5))
	view.draw_string(font, rc + Vector2(-4, -26), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	var ms: Vector2i = main.map_size
	var top := pr.position.y + 60.0
	var area := Vector2(psz.x - 70.0, psz.y - 100.0)
	var c := floorf(minf(area.x / ms.x, area.y / ms.y))
	c = maxf(c, 2.0)
	# centre le dessin sur la partie explorée
	var x0: int = ms.x
	var x1: int = -1
	var y0: int = ms.y
	var y1: int = -1
	for y in ms.y:
		for x in ms.x:
			if main.explored[y * ms.x + x] == 1:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:
		x0 = 0
		y0 = 0
		x1 = ms.x - 1
		y1 = ms.y - 1
	var origin := Vector2(mid - (x0 + x1 + 1) * c / 2.0, top + area.y / 2.0 - (y0 + y1 + 1) * c / 2.0)
	draw_cells(view, main, origin, c, Rect2i(Vector2i.ZERO, ms))
	var kinds := draw_markers(view, main, origin, c, Rect2i(Vector2i.ZERO, ms), true)
	draw_legend(view, font, kinds, pr.position + Vector2(118.0, psz.y - 22.0 - minf(kinds.size(), 4) * 20.0), 80.0)
	view.draw_set_transform(Vector2.ZERO, 0.0)
	Glyphs.draw_rich(view, font, 0, sz.x, pr.end.y + 34, "{map|1} / {pause|1} : fermer", 16, Color(0.85, 0.8, 0.7))

# Cases (utilisé aussi par la mini-carte du HUD)
static func draw_cells(ci: CanvasItem, m, origin: Vector2, c: float, r: Rect2i) -> void:
	for y in range(maxi(r.position.y, 0), mini(r.end.y, m.map_size.y)):
		var row: String = m.MAP[y]
		for x in range(maxi(r.position.x, 0), mini(r.end.x, m.map_size.x)):
			if not m.is_explored(x, y):
				continue
			var p := origin + Vector2(x - r.position.x, y - r.position.y) * c
			var ch: String = row[x] if x < row.length() else "."
			var col := cell_color(ch, m.pal)
			if col.a > 0.0:
				ci.draw_rect(Rect2(p, Vector2(c, c)), Color(col, 0.85))
				if ch == "#":
					# trait d'encre sur les bords qui donnent sur le vide
					for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						var nx: int = x + d.x
						var ny: int = y + d.y
						if nx < 0 or ny < 0 or nx >= m.map_size.x or ny >= m.map_size.y:
							continue
						var nrow: String = m.MAP[ny]
						var nch: String = nrow[nx] if nx < nrow.length() else "."
						if nch != "#" and m.is_explored(nx, ny):
							var a := p + Vector2(c, c) * 0.5 + Vector2(d) * c * 0.5
							var side := Vector2(-d.y, d.x) * c * 0.5
							ci.draw_line(a - side, a + side, INK, maxf(1.0, c * 0.22))
			else:
				ci.draw_rect(Rect2(p, Vector2(c, c)), Color(1.0, 0.95, 0.8, 0.18))

# Nom affiché dans la légende pour chaque type de repère.
const LEGEND := {
	"player": "Vous", "bench": "Banc", "exit": "Sortie", "shrine": "Lanterne", "boss": "Boss", "shade": "Ombre",
	"charm": "Emblème", "notch": "Encoche", "geo": "Coffre", "merchant": "Marchand", "smith": "Forgeronne",
	"cartographer": "Cartographe", "elder": "Ancien", "arsenal": "Arsenal", "elevator": "Ascenseur",
	"altar": "Autel d'élites", "challenge": "Défi chronométré", "flag": "Arrivée du défi",
}
const LEGEND_ORDER := ["player", "exit", "bench", "shrine", "boss", "shade", "merchant", "smith", "cartographer", "elder",
	"arsenal", "elevator", "geo", "charm", "notch", "altar", "challenge", "flag"]

# Petit pictogramme à l'encre pour un repère de la carte (s = demi-taille).
static func draw_icon(ci: CanvasItem, kind: String, p: Vector2, s: float) -> void:
	var ink := INK
	var gold := Color(0.8, 0.55, 0.1)
	match kind:
		"player":
			var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
			ci.draw_circle(p, s + 2.0, Color(0.85, 0.2, 0.15, blink))
			ci.draw_circle(p, maxf(1.0, s - 0.5), Color(0.2, 0.1, 0.06))
		"bench":
			ci.draw_rect(Rect2(p + Vector2(-s, -s * 0.5), Vector2(s * 2.0, s * 0.6)), Color(0.6, 0.38, 0.12))
			ci.draw_line(p + Vector2(-s * 0.7, 0), p + Vector2(-s * 0.7, s * 0.8), ink, maxf(1.0, s * 0.3))
			ci.draw_line(p + Vector2(s * 0.7, 0), p + Vector2(s * 0.7, s * 0.8), ink, maxf(1.0, s * 0.3))
		"exit":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s), p + Vector2(-s, -s * 0.4), p + Vector2(0, -s * 1.3), p + Vector2(s, -s * 0.4), p + Vector2(s, s)]), Color(0.15, 0.35, 0.6))
			ci.draw_polyline(PackedVector2Array([p + Vector2(-s, s), p + Vector2(-s, -s * 0.4), p + Vector2(0, -s * 1.3), p + Vector2(s, -s * 0.4), p + Vector2(s, s)]), ink, 1.0)
		"shrine":
			ci.draw_circle(p, s + 1.0, Color(1.0, 0.8, 0.35))
			ci.draw_arc(p, s + 1.0, 0.0, TAU, 12, ink, 1.0)
		"boss":
			ci.draw_circle(p, s + 2.5, Color(0.8, 0.15, 0.12))
			ci.draw_arc(p, s + 2.5, 0.0, TAU, 14, ink, 1.2)
			ci.draw_circle(p + Vector2(-s * 0.45, -s * 0.2), maxf(1.0, s * 0.3), ink)
			ci.draw_circle(p + Vector2(s * 0.45, -s * 0.2), maxf(1.0, s * 0.3), ink)
		"shade":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s), p + Vector2(-s, -s * 0.3), p + Vector2(0, -s * 1.2), p + Vector2(s, -s * 0.3), p + Vector2(s, s), p + Vector2(0, s * 0.4)]), Color(0.5, 0.3, 0.8))
		"charm":
			ci.draw_colored_polygon(DUtil.diamond(p, Vector2(s, s * 1.3)), gold)
			ci.draw_polyline(DUtil.diamond(p, Vector2(s, s * 1.3)) + PackedVector2Array([p + Vector2(0, -s * 1.3)]), ink, 1.0)
		"notch":
			ci.draw_arc(p, s, 0.0, TAU, 12, gold, maxf(1.5, s * 0.5))
		"geo":
			ci.draw_rect(Rect2(p + Vector2(-s, -s * 0.6), Vector2(s * 2.0, s * 1.4)), Color(0.5, 0.3, 0.12))
			ci.draw_rect(Rect2(p + Vector2(-s, -s * 0.6), Vector2(s * 2.0, s * 1.4)), ink, false, 1.0)
			ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), gold, maxf(1.0, s * 0.35))
		"merchant", "smith", "cartographer", "elder":
			var col: Color = {"merchant": Color(0.75, 0.5, 0.1), "smith": Color(0.7, 0.25, 0.15), "cartographer": Color(0.2, 0.45, 0.55), "elder": Color(0.45, 0.3, 0.6)}[kind]
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s), p + Vector2(0, -s * 0.5), p + Vector2(s, s)]), col)
			ci.draw_circle(p + Vector2(0, -s * 0.8), maxf(1.5, s * 0.55), col)
			ci.draw_arc(p + Vector2(0, -s * 0.8), maxf(1.5, s * 0.55), 0.0, TAU, 10, ink, 1.0)
		"arsenal":
			ci.draw_line(p + Vector2(-s, -s), p + Vector2(s, s), ink, maxf(1.5, s * 0.4))
			ci.draw_line(p + Vector2(s, -s), p + Vector2(-s, s), ink, maxf(1.5, s * 0.4))
		"elevator":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, -s * 0.2), p + Vector2(0, -s * 1.3), p + Vector2(s, -s * 0.2)]), Color(0.2, 0.4, 0.6))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s * 0.2), p + Vector2(0, s * 1.3), p + Vector2(s, s * 0.2)]), Color(0.2, 0.4, 0.6))
		"altar":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s), p + Vector2(-s * 0.6, -s * 0.4), p + Vector2(0, s * 0.1), p + Vector2(s * 0.6, -s * 0.4), p + Vector2(s, s)]), Color(0.75, 0.15, 0.12))
			ci.draw_circle(p + Vector2(0, -s * 0.9), maxf(1.0, s * 0.4), Color(0.75, 0.15, 0.12))
		"challenge":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, -s), p + Vector2(s, -s), p]), Color(0.75, 0.5, 0.15))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s), p + Vector2(s, s), p]), Color(0.75, 0.5, 0.15))
		"flag":
			ci.draw_line(p + Vector2(-s * 0.6, s), p + Vector2(-s * 0.6, -s * 1.2), ink, maxf(1.0, s * 0.3))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.6, -s * 1.2), p + Vector2(s, -s * 0.6), p + Vector2(-s * 0.6, 0)]), Color(0.75, 0.5, 0.15))

# Dessine les repères découverts et renvoie la liste des types affichés (pour la légende).
static func draw_markers(ci: CanvasItem, m, origin: Vector2, c: float, r: Rect2i, big: bool) -> Array:
	var T: float = m.TILE
	var rs := 6.0 if big else 3.0
	var off := Vector2(r.position) * c
	var shown := {}
	var _pt := func(world: Vector2) -> Vector2:
		return origin + world / T * c - off
	var inside := func(world: Vector2) -> bool:
		var cell := Vector2i(floori(world.x / T), floori(world.y / T))
		return r.has_point(cell) and m.is_explored(cell.x, cell.y)
	var mark := func(kind: String, world: Vector2, need_explored: bool) -> void:
		if need_explored and not inside.call(world):
			return
		if not r.has_point(Vector2i(floori(world.x / T), floori(world.y / T))):
			return
		draw_icon(ci, kind, _pt.call(world), rs)
		shown[kind] = true
	for b in m.benches:
		mark.call("bench", b, true)
	if m.exit_door and is_instance_valid(m.exit_door):
		mark.call("exit", m.exit_door.position + Vector2(0, -16), true)
	if m.shrine and is_instance_valid(m.shrine):
		mark.call("shrine", m.shrine.position + Vector2(0, -16), true)
	for pk in m.pickups:
		if is_instance_valid(pk[0]):
			mark.call(String(pk[1]), pk[0].position + (Vector2(0, -12) if pk[1] == "geo" else Vector2.ZERO), true)
	for it in m.interactables:
		if is_instance_valid(it[0]):
			mark.call(String(it[1]), it[0].position + Vector2(0, -16), true)
	if m.challenge_start != null and is_instance_valid(m.challenge_start) and not m.challenge_done:
		mark.call("challenge", m.challenge_start.position + Vector2(0, -16), true)
	if m.challenge_goal != null and is_instance_valid(m.challenge_goal) and not m.challenge_done:
		mark.call("flag", m.challenge_goal.position + Vector2(0, -16), true)
	if m.shade_node and is_instance_valid(m.shade_node) and not m.shade_node.dead:
		mark.call("shade", m.shade_node.global_position, false)
	if m.boss and is_instance_valid(m.boss) and not m.boss_dead:
		mark.call("boss", m.boss.global_position, true)
	mark.call("player", m.player.global_position, false)
	var out := []
	for k in LEGEND_ORDER:
		if shown.has(k):
			out.append(k)
	return out

# Légende : uniquement ce qui est visible sur la carte.
static func draw_legend(ci: CanvasItem, font: Font, kinds: Array, at: Vector2, max_h: float) -> void:
	if kinds.is_empty():
		return
	var cols := int(ceil(kinds.size() * 20.0 / max_h))
	ci.draw_rect(Rect2(at - Vector2(6, 4), Vector2(cols * 150.0 + 6.0, minf(kinds.size() * 20.0, max_h) + 8.0)), Color(PAPER, 0.75))
	var y := 0.0
	var x := 0.0
	for k in kinds:
		if y + 20.0 > max_h:
			y = 0.0
			x += 150.0
		draw_icon(ci, k, at + Vector2(x + 8.0, y + 8.0), 5.0)
		ci.draw_string(font, at + Vector2(x + 24.0, y + 13.0), TranslationServer.translate(LEGEND[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
		y += 20.0

const Glyphs = preload("res://scripts/glyphs.gd")
const DUtil = preload("res://scripts/draw_util.gd")

extends CanvasLayer
const DU = preload("res://scripts/draw_util.gd")
# Animation de fin : après un boss final, la Lanterne des Profondeurs se rallume.
# La lumière remonte palier par palier jusqu'au Sanctuaire puis à la surface, puis le générique.
# Passer : maintenir Saut / Frapper / Entrée (après 3 s). Le jeu continue ensuite (paliers sans fin).

var main
var boss_id := "ombre"
var t := 0.0
var view: Control
var skip_hold := 0.0
var choice: Control = null    # choix final : retourner au Sanctuaire ou terminer la partie
const TOTAL := 66.0

const BOSS_LINE := {
	"ombre": "L'Ombre de la Lanterne se dissipe comme une fumée froide.",
	"cerbere": "Le Cerbère des Profondeurs s'effondre. Ses trois têtes se taisent enfin.",
	"centaure": "Le Centaure Archer pose son arc. Sa dernière flèche s'éteint dans le noir.",
	"oeil": "L'Œil d'en Dessous se referme. Ses tentacules retournent dans l'abîme.",
}
# Paliers qui se rallument en remontant (du plus profond au plus proche)
const TIERS := [
	["Le Chevalier Spectral", "se souvient de son serment, et range son épée.", Color(0.55, 0.7, 1.0)],
	["Le Ver des Profondeurs", "se rendort, repu de lumière.", Color(0.75, 0.55, 0.35)],
	["Le Colosse d'Os", "laisse reposer les os de ceux qui sont descendus.", Color(0.85, 0.82, 0.7)],
	["La Reine Essaim", "trouve enfin sa fleur : la flamme.", Color(1.0, 0.8, 0.3)],
	["L'Abbesse Engloutie", "entend sa prière exaucée sous l'eau.", Color(0.5, 0.85, 0.9)],
	["Le Gardien du Puits", "se rappelle pourquoi il garde.", Color(0.7, 0.85, 0.6)],
]
const CREDITS := [
	"Lanterne des Profondeurs",
	"",
	"Conception et code — FlyinnRabbit et Claude",
	"Musique et sons — composés pour le jeu par synthèse",
	"Moteur — Godot 4",
	"",
	"Merci d'avoir joué !",
]

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.draw.connect(_paint)
	add_child(view)
	get_tree().paused = true
	Audio.play_boss("res://music/fin_lanterne_rallumee.ogg")

func _process(delta: float) -> void:
	if choice:
		return
	t += delta
	if t > 3.0 and (Input.is_action_pressed("jump") or Input.is_action_pressed("attack") or Input.is_action_pressed("ui_accept")):
		skip_hold += delta
	else:
		skip_hold = 0.0
	if t >= TOTAL or skip_hold > 0.8:
		_show_choice()
		return
	view.queue_redraw()

# Après le générique : continuer (les paliers sans fin, jusqu'au palier 28 et au-delà) ou finir la partie
func _show_choice() -> void:
	t = TOTAL - 0.01
	view.queue_redraw()
	choice = CenterContainer.new()
	choice.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice.theme = main.menu._make_theme()
	add_child(choice)
	var panel := PanelContainer.new()
	choice.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var title := Label.new()
	title.text = "La Lanterne brille à nouveau."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.6))
	v.add_child(title)
	var info := Label.new()
	info.text = "Le palier est terminé. Tu peux continuer à descendre (d'autres boss finaux t'attendent aux paliers 14, 21, 28…) ou terminer ta partie ici."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(560, 0)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.8, 0.84, 0.95))
	v.add_child(info)
	var b1: Button = main.menu._button("Retourner au Sanctuaire et continuer", _continue)
	b1.custom_minimum_size = Vector2(520, 46)
	v.add_child(b1)
	var b2: Button = main.menu._button("Terminer la partie (retour à l'écran titre)", _end_game)
	b2.custom_minimum_size = Vector2(520, 46)
	v.add_child(b2)
	b1.grab_focus()

func _continue() -> void:
	get_tree().paused = false
	GameState.finish_final(main.player, false)

func _end_game() -> void:
	get_tree().paused = false
	GameState.finish_final(main.player, true)

# fondu d'un segment [a, b]
func _k(a: float, b: float, f := 1.0) -> float:
	return clampf(minf((t - a) / f, (b - t) / f), 0.0, 1.0)

func _text(y: float, s: String, size: int, col: Color, a: float) -> void:
	if a <= 0.0:
		return
	var font := ThemeDB.fallback_font
	var w := view.size.x
	view.draw_string(font, Vector2(2, y + 2), tr(s), HORIZONTAL_ALIGNMENT_CENTER, w, size, Color(0, 0, 0, 0.7 * a))
	view.draw_string(font, Vector2(0, y), tr(s), HORIZONTAL_ALIGNMENT_CENTER, w, size, Color(col, a))

func _lantern(c: Vector2, s: float, flame: float) -> void:
	var metal := Color(0.3, 0.27, 0.33)
	var brass := Color(0.62, 0.48, 0.24)
	if flame > 0.0:
		DU.glow(view, c, 220.0 * s * flame, Color(1.0, 0.8, 0.4), 0.45 * flame)
		DU.glow(view, c, 70.0 * s * flame, Color(1.0, 0.9, 0.6), 0.6 * flame)
	# anneau, toit à pans, fleuron
	view.draw_arc(c + Vector2(0, -72) * s, 10.0 * s, PI, TAU, 14, brass, 3.5 * s)
	DU.poly(view, PackedVector2Array([c + Vector2(-32, -40) * s, c + Vector2(-20, -54) * s, c + Vector2(0, -66) * s, c + Vector2(20, -54) * s, c + Vector2(32, -40) * s]), metal)
	DU.box(view, Rect2(c + Vector2(-33, -43) * s, Vector2(66, 5) * s), brass)
	# verre et flamme
	view.draw_rect(Rect2(c + Vector2(-26, -40) * s, Vector2(52, 72) * s), Color(0.06, 0.04, 0.05))
	if flame > 0.0:
		DU.vgrad(view, Rect2(c + Vector2(-26, -40) * s, Vector2(52, 72) * s), Color(1.0, 0.8, 0.4, 0.15 * flame), Color(1.0, 0.7, 0.3, 0.45 * flame))
		var fl := 1.0 + 0.15 * sin(t * 11.0)
		for layer in 3:
			var sc := 1.0 - layer * 0.3
			var pts := PackedVector2Array()
			for k in 16:
				var ang := k * TAU / 16.0
				var tongue := 1.0 + (0.5 + 0.3 * sin(t * 11.0 + k)) * maxf(0.0, -sin(ang))
				pts.append(c + Vector2(cos(ang) * 13.0 * sc, sin(ang) * 20.0 * sc * tongue) * s * fl * flame + Vector2(0, 6) * s)
			DU.flat(view, pts, Color(1.0, 0.7, 0.28).lerp(Color(1.0, 0.98, 0.88), layer * 0.45))
	# barreaux et socle
	for i in 5:
		var x := -26.0 + i * 13.0
		view.draw_line(c + Vector2(x, -40) * s, c + Vector2(x, 32) * s, metal.darkened(0.3), 3.6 * s)
		view.draw_line(c + Vector2(x - 0.8, -40) * s, c + Vector2(x - 0.8, 32) * s, DU.lit(metal, 1.6, 0.06), 1.2 * s)
	DU.box(view, Rect2(c + Vector2(-34, 30) * s, Vector2(68, 9) * s), brass)
	for k in [-1.0, 1.0]:
		DU.poly(view, PackedVector2Array([c + Vector2(k * 24, 39) * s, c + Vector2(k * 32, 39) * s, c + Vector2(k * 36, 48) * s]), metal)

func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		p.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return p

# le petit veilleur, de profil (tourné vers la droite) ; col.a sert de fondu
func _watcher(c: Vector2, s: float, col: Color) -> void:
	var a := col.a
	var cloak := Color(0.1, 0.085, 0.16, a)
	var sway := sin(t * 2.0) * 1.5
	var scarf := PackedVector2Array([c + Vector2(-4, -26) * s, c + Vector2(-12, -24 + sway * 0.5) * s, c + Vector2(-20, -26 + sway) * s, c + Vector2(-27, -22 + sway * 1.4) * s])
	view.draw_polyline(scarf, Color(0.22, 0.5, 0.55, a), 4.2 * s)
	view.draw_polyline(scarf, Color(0.5, 0.85, 0.86, a), 2.2 * s)
	var cape := PackedVector2Array([c + Vector2(-8, -27) * s, c + Vector2(8, -27) * s, c + Vector2(12, -3) * s, c + Vector2(8, 0) * s, c + Vector2(4, -4) * s, c + Vector2(0, 0) * s, c + Vector2(-4, -4) * s, c + Vector2(-8, 0) * s, c + Vector2(-13, -3) * s])
	if a > 0.95:
		DU.poly(view, cape, cloak, false)
	else:
		DU.flat(view, cape, cloak)
	var hy := -27.0
	var hood := PackedVector2Array([c + Vector2(-10, hy + 4) * s, c + Vector2(11, hy + 4) * s, c + Vector2(12, hy - 8) * s, c + Vector2(6, hy - 16) * s, c + Vector2(-4, hy - 18) * s, c + Vector2(-14, hy - 22) * s, c + Vector2(-11, hy - 8) * s])
	if a > 0.95:
		DU.poly(view, hood, Color(cloak.lightened(0.04), a))
	else:
		DU.flat(view, hood, cloak)
	DU.flat(view, _ellipse(c + Vector2(3, hy - 6) * s, Vector2(6.5, 6.0) * s), Color(0, 0, 0.02, a))
	DU.glow(view, c + Vector2(5, hy - 6) * s, 8.0 * s, Color(1.0, 0.7, 0.3), 0.4 * a)
	DU.flat(view, _ellipse(c + Vector2(5, hy - 6) * s, Vector2(2.4, 2.6) * s), Color(1.0, 0.82, 0.42, a))

# voûte de caverne : dégradé et stalactites peintes
func _cave(sz: Vector2, top: Color, bottom: Color, a: float) -> void:
	DU.vgrad(view, Rect2(Vector2.ZERO, sz), Color(top, a), Color(bottom, a))
	for layer in 2:
		var col := Color(top.darkened(0.4 + layer * 0.3), a)
		for k in 14:
			var x := (k + layer * 0.5) * sz.x / 12.0 - 40.0
			var l := 60.0 + fposmod(sin(k * 3.7 + layer) * 997.0, 1.0) * (120.0 + layer * 80.0)
			var w := 26.0 + layer * 14.0
			DU.flat(view, PackedVector2Array([Vector2(x - w, -2), Vector2(x + w, -2), Vector2(x + w * 0.25, l * 0.6), Vector2(x, l)]), col)
			DU.flat(view, PackedVector2Array([Vector2(x + 50 - w, sz.y + 2), Vector2(x + 50 + w, sz.y + 2), Vector2(x + 50, sz.y - l * 0.7)]), col)

# silhouettes des habitants du Sanctuaire
func _folk(kind: int, p: Vector2, a: float) -> void:
	var dark := Color(0.08, 0.06, 0.07, a)
	match kind:
		0:   # marchand : papillon de nuit, sac
			DU.flat(view, _ellipse(p + Vector2(16, -24), Vector2(14, 16)), dark)
			DU.flat(view, PackedVector2Array([p + Vector2(-16, 0), p + Vector2(16, 0), p + Vector2(10, -36), p + Vector2(-10, -36)]), dark)
			DU.flat(view, _ellipse(p + Vector2(0, -44), Vector2(13, 11)), dark)
			for k in [-1.0, 1.0]:
				view.draw_line(p + Vector2(k * 5, -53), p + Vector2(k * 14, -68), dark, 2.4)
		1:   # forgeronne : scarabée trapu, marteau
			DU.flat(view, _ellipse(p + Vector2(0, -24), Vector2(18, 24)), dark)
			DU.flat(view, _ellipse(p + Vector2(0, -54), Vector2(12, 11)), dark)
			for k in [-1.0, 1.0]:
				view.draw_line(p + Vector2(k * 4, -62), p + Vector2(k * 10, -78), dark, 3.0)
			view.draw_line(p + Vector2(14, -38), p + Vector2(26, -62), dark, 3.0)
			view.draw_rect(Rect2(p + Vector2(19, -70), Vector2(14, 10)), dark)
		2:   # cartographe : mite à lunettes, plume
			DU.flat(view, _ellipse(p + Vector2(0, -18), Vector2(13, 19)), dark)
			DU.flat(view, _ellipse(p + Vector2(0, -42), Vector2(11, 10)), dark)
			for k in [-1.0, 1.0]:
				view.draw_line(p + Vector2(k * 3, -51), p + Vector2(k * 10, -63), dark, 2.0)
			view.draw_line(p + Vector2(-12, -26), p + Vector2(-20, -46), dark, 2.0)
		3:   # ancien : escargot encapuchonné, canne
			DU.flat(view, _ellipse(p + Vector2(-18, -22), Vector2(21, 19)), dark)
			DU.flat(view, PackedVector2Array([p + Vector2(-2, 0), p + Vector2(20, 0), p + Vector2(15, -40), p + Vector2(4, -46), p + Vector2(0, -30)]), dark)
			view.draw_line(p + Vector2(24, 0), p + Vector2(20, -52), dark, 3.0)
	# yeux qui reflètent la lumière, tournés vers la colonne de lumière
	var ex := 4.0 if p.x < view.size.x / 2.0 else -4.0
	var ey: float = [-44.0, -54.0, -42.0, -38.0][kind]
	view.draw_circle(p + Vector2(ex, ey), 2.2, Color(1.0, 0.9, 0.6, a))

func _paint() -> void:
	var sz := view.size
	var cx := sz.x / 2.0
	view.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.02))
	# 1. le boss tombe — 2. la Lanterne se rallume (0–14 s)
	if t < 15.0:
		var flame := clampf((t - 6.0) / 3.0, 0.0, 1.0)
		var a := _k(0.0, 15.0, 1.0)
		view.modulate = Color(1, 1, 1, 1)
		_cave(sz, Color(0.05, 0.04, 0.09).lerp(Color(0.2, 0.13, 0.08), flame), Color(0.02, 0.02, 0.04), a)
		# sol de pierre
		DU.vgrad(view, Rect2(0, sz.y * 0.48 + 80, sz.x, sz.y), Color(0.12, 0.1, 0.12, a), Color(0.02, 0.02, 0.03, a))
		view.draw_line(Vector2(0, sz.y * 0.48 + 80), Vector2(sz.x, sz.y * 0.48 + 80), Color(1.0, 0.8, 0.5, 0.35 * flame * a), 2.0)
		if flame > 0.0:
			for i in 12:
				var ang := i * TAU / 12.0 + t * 0.1
				view.draw_line(Vector2(cx, sz.y * 0.48) + Vector2.from_angle(ang) * 90.0, Vector2(cx, sz.y * 0.48) + Vector2.from_angle(ang) * (90.0 + 400.0 * flame), Color(1.0, 0.85, 0.5, 0.06 * flame * a), 10.0)
			for k in 10:
				var u := fposmod(t * 0.25 + k * 0.1, 1.0)
				view.draw_circle(Vector2(cx + sin(k * 2.3 + t) * 140.0, sz.y * 0.48 + 60 - u * 300.0), 2.0 * (1.0 - u), Color(1.0, 0.85, 0.5, (1.0 - u) * flame * a))
		_lantern(Vector2(cx, sz.y * 0.48), 2.0, flame * a)
		_watcher(Vector2(cx - 110, sz.y * 0.48 + 80), 2.0, Color(0.12, 0.1, 0.16, a))
		_text(sz.y * 0.16, BOSS_LINE.get(boss_id, BOSS_LINE["ombre"]), 26, Color(0.9, 0.9, 1.0), _k(0.5, 6.5))
		_text(sz.y * 0.16, "Le petit veilleur pose la main sur la Lanterne. La flamme reprend.", 26, Color(1.0, 0.9, 0.65), _k(7.0, 14.5))
	# 3. la lumière remonte, palier par palier (15–31 s)
	elif t < 31.0:
		var u := (t - 15.0) / 16.0
		var band_h := sz.y * 0.55
		var scroll := u * band_h * TIERS.size()
		for i in TIERS.size():
			var y := sz.y * 0.75 - i * band_h + scroll - band_h
			if y > sz.y + 40 or y + band_h < -40:
				continue
			var tier: Array = TIERS[i]
			var lit := clampf((scroll - i * band_h) / (band_h * 0.6), 0.0, 1.0)
			var col: Color = tier[2]
			var deep := col.darkened(0.88).lerp(col.darkened(0.55), lit)
			DU.vgrad(view, Rect2(0, y, sz.x, band_h), deep.darkened(0.3), deep)
			# halo de lumière qui se répand dans le palier
			if lit > 0.0:
				DU.glow(view, Vector2(cx, y + band_h * 0.5), sz.x * 0.45, col, 0.35 * lit)
			# plafond rocheux et stalactites ombrées
			DU.vgrad(view, Rect2(0, y + band_h - 14, sz.x, 14), col.darkened(0.55), col.darkened(0.8))
			for k in 11:
				var sx := k * sz.x / 10.0 - 20.0
				var l := 40.0 + 24.0 * ((k + i) % 3)
				var pts := PackedVector2Array([Vector2(sx - 30, y), Vector2(sx + 30, y), Vector2(sx + 6, y + l * 0.6), Vector2(sx, y + l)])
				view.draw_polygon(pts, PackedColorArray([col.darkened(0.7), col.darkened(0.7), col.darkened(0.8), col.darkened(0.85)]))
				view.draw_line(Vector2(sx - 30, y), Vector2(sx, y + l), Color(col, 0.25 * lit), 1.5)
			_text(y + band_h * 0.45, tier[0], 30, col.lightened(0.3), lit)
			_text(y + band_h * 0.45 + 40, tier[1], 20, Color(0.9, 0.9, 0.95), lit)
		DU.glow(view, Vector2(cx, sz.y * 0.5), 60.0, Color(1.0, 0.85, 0.45), 0.2)
		view.draw_rect(Rect2(cx - 18, 0, 36, sz.y), Color(1.0, 0.85, 0.45, 0.16))
		view.draw_rect(Rect2(cx - 8, 0, 16, sz.y), Color(1.0, 0.9, 0.6, 0.25))
		view.draw_rect(Rect2(cx - 3, 0, 6, sz.y), Color(1.0, 0.97, 0.85, 0.6))
		for k in 12:
			var uu := fposmod(t * 0.6 + k / 12.0, 1.0)
			view.draw_circle(Vector2(cx + sin(k * 1.7 + t * 2.0) * 26.0, sz.y * (1.0 - uu)), 2.0, Color(1.0, 0.9, 0.6, 0.8))
	# 4. le Sanctuaire (31–40 s)
	elif t < 40.0:
		var a2 := _k(31.0, 40.0, 1.0)
		var floor_y := sz.y * 0.72
		_cave(sz, Color(0.16, 0.11, 0.07), Color(0.08, 0.06, 0.05), 1.0)
		# arches de pierre au fond
		for k in 4:
			var axc := cx + (k - 1.5) * sz.x * 0.28
			view.draw_arc(Vector2(axc, floor_y - 120), 110.0, PI, TAU, 24, Color(0.2, 0.14, 0.1), 22.0)
			DU.vgrad(view, Rect2(axc - 121, floor_y - 120, 22, 120), Color(0.2, 0.14, 0.1), Color(0.14, 0.1, 0.07))
		DU.vgrad(view, Rect2(0, floor_y, sz.x, sz.y - floor_y), Color(0.3, 0.22, 0.14), Color(0.1, 0.07, 0.05))
		for k in 30:
			var gx := k * sz.x / 29.0
			view.draw_line(Vector2(gx, floor_y), Vector2(gx + 3, floor_y - 6 - (k % 3) * 3), Color(0.9, 0.75, 0.45, 0.8), 1.5)
		# colonne de lumière qui monte du sol
		DU.glow(view, Vector2(cx, floor_y), 260.0, Color(1.0, 0.8, 0.4), 0.45 * a2)
		view.draw_rect(Rect2(cx - 26, 0, 52, floor_y), Color(1.0, 0.85, 0.45, 0.18 * a2))
		view.draw_rect(Rect2(cx - 9, 0, 18, floor_y), Color(1.0, 0.95, 0.75, 0.35 * a2))
		# banc et habitants qui lèvent les yeux
		DU.box(view, Rect2(cx - 380, floor_y - 18, 60, 5), Color(0.38, 0.28, 0.22))
		DU.box(view, Rect2(cx - 380, floor_y - 34, 60, 4), Color(0.38, 0.28, 0.22))
		var xs: Array[float] = [-260.0, -150.0, 150.0, 280.0]
		for k in 4:
			_folk(k, Vector2(cx + xs[k], floor_y), 1.0)
		_lantern(Vector2(cx, floor_y - 45), 0.9, a2)
		_text(sz.y * 0.18, "Au Sanctuaire, tous lèvent les yeux : la lumière remonte jusqu'à eux.", 24, Color(1.0, 0.9, 0.7), _k(31.5, 39.5))
	# 5. la surface, à l'aube (40–49 s)
	elif t < 49.0:
		var a3 := clampf((t - 40.0) / 4.0, 0.0, 1.0)
		DU.vgrad(view, Rect2(0, 0, sz.x, sz.y * 0.5), Color(0.06, 0.05, 0.16).lerp(Color(0.35, 0.3, 0.55), a3), Color(0.12, 0.08, 0.2).lerp(Color(1.0, 0.62, 0.42), a3))
		DU.vgrad(view, Rect2(0, sz.y * 0.5, sz.x, sz.y * 0.5), Color(0.12, 0.08, 0.2).lerp(Color(1.0, 0.62, 0.42), a3), Color(0.1, 0.06, 0.12).lerp(Color(1.0, 0.78, 0.5), a3))
		for k in 30:
			var sp := Vector2(fposmod(k * 137.0, sz.x), fposmod(k * 71.0, sz.y * 0.45))
			view.draw_circle(sp, 1.2, Color(1, 1, 1, 0.7 * (1.0 - a3)))
		var sun := Vector2(cx, sz.y * 0.78 - a3 * 60.0)
		DU.glow(view, sun, 320.0, Color(1.0, 0.75, 0.45), 0.6 * a3)
		for i in 10:
			var ang := -PI + i * PI / 9.0
			view.draw_line(sun, sun + Vector2.from_angle(ang) * 700.0, Color(1.0, 0.9, 0.6, 0.06 * a3), 18.0)
		view.draw_circle(sun, 70.0, Color(1.0, 0.88, 0.55, a3))
		view.draw_circle(sun, 56.0, Color(1.0, 0.95, 0.75, a3))
		# trois chaînes de collines, de la plus lointaine (brumeuse) à la plus proche (sombre)
		for layer in 3:
			var base := sz.y * (0.7 + layer * 0.06)
			var c := Color(0.45, 0.32, 0.45).lerp(Color(0.06, 0.05, 0.08), layer / 2.0)
			c = c.lerp(Color(0.06, 0.05, 0.08), 1.0 - a3)
			var pts := PackedVector2Array([Vector2(0, sz.y)])
			for k in 13:
				var x := k * sz.x / 12.0
				pts.append(Vector2(x, base - 40.0 * absf(sin(k * 1.3 + layer * 2.1)) - (30.0 if layer == 2 and absf(x - cx) < 200.0 else 0.0)))
			pts.append(Vector2(sz.x, sz.y))
			DU.flat(view, pts, c)
		var hill := sz.y * 0.73
		for k in 40:
			var gx := cx - 300.0 + k * 15.0
			view.draw_line(Vector2(gx, hill + 10), Vector2(gx + 2, hill + 2 - (k % 3) * 3), Color(0.05, 0.04, 0.06), 2.0)
		_watcher(Vector2(cx - 40, hill), 1.6, Color(0.05, 0.04, 0.07))
		_lantern(Vector2(cx + 10, hill - 16), 0.5, 1.0)
		_text(sz.y * 0.2, "Pour la première fois depuis des siècles, la lumière touche la surface.", 26, Color(1.0, 0.95, 0.85), _k(41.0, 48.5))
	# 6. générique (49–66 s)
	else:
		var u2 := (t - 49.0) / (TOTAL - 49.0)
		DU.vgrad(view, Rect2(Vector2.ZERO, sz), Color(0.02, 0.02, 0.05), Color(0.08, 0.05, 0.04))
		for k in 24:
			var uu := fposmod(t * 0.08 + k / 24.0, 1.0)
			view.draw_circle(Vector2(fposmod(k * 157.0, sz.x) + sin(t + k) * 10.0, sz.y * (1.0 - uu)), 1.6, Color(1.0, 0.8, 0.45, 0.6 * sin(uu * PI)))
		_lantern(Vector2(sz.x - 90, sz.y - 80), 0.6, 1.0)
		for i in CREDITS.size():
			var y := sz.y + 40 - u2 * (sz.y + CREDITS.size() * 50.0) + i * 50.0
			var big := i == 0 or i == CREDITS.size() - 1
			_text(y, CREDITS[i], 36 if big else 22, Color(1.0, 0.88, 0.6) if big else Color(0.85, 0.88, 0.95), 1.0)
	if t > 3.0 and choice == null:
		var font := ThemeDB.fallback_font
		view.draw_string(font, Vector2(0, sz.y - 18), tr("Maintenir Saut ou Frapper : passer"), HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 20, 14, Color(0.6, 0.62, 0.7, 0.7))

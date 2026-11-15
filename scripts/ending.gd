extends CanvasLayer
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
	var metal := Color(0.3, 0.27, 0.32)
	if flame > 0.0:
		view.draw_circle(c, 160.0 * s * flame, Color(1.0, 0.8, 0.4, 0.12 * flame))
		view.draw_circle(c, 80.0 * s * flame, Color(1.0, 0.85, 0.5, 0.2 * flame))
	view.draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -40) * s, c + Vector2(30, -40) * s, c + Vector2(0, -66) * s]), metal)
	view.draw_rect(Rect2(c + Vector2(-26, -40) * s, Vector2(52, 72) * s), Color(0.06, 0.04, 0.05))
	if flame > 0.0:
		var fl := 1.0 + 0.15 * sin(t * 11.0)
		view.draw_colored_polygon(_ellipse(c + Vector2(0, 0) * s, Vector2(13, 22) * s * fl * flame), Color(1.0, 0.75, 0.3))
		view.draw_colored_polygon(_ellipse(c + Vector2(0, 6) * s, Vector2(6, 11) * s * flame), Color(1.0, 0.97, 0.85))
	for i in 5:
		view.draw_line(c + Vector2(-26 + i * 13, -40) * s, c + Vector2(-26 + i * 13, 32) * s, metal, 3.0 * s)
	view.draw_rect(Rect2(c + Vector2(-32, 30) * s, Vector2(64, 9) * s), metal)
	view.draw_arc(c + Vector2(0, -70) * s, 10.0 * s, PI, TAU, 12, metal, 3.0 * s)

func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		p.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return p

func _watcher(c: Vector2, s: float, col: Color) -> void:
	view.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 0) * s, c + Vector2(10, 0) * s, c + Vector2(7, -26) * s, c + Vector2(-7, -26) * s]), col)
	view.draw_colored_polygon(_ellipse(c + Vector2(0, -32) * s, Vector2(9, 9) * s), col)
	view.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -38) * s, c + Vector2(8, -38) * s, c + Vector2(0, -52) * s]), col)
	view.draw_circle(c + Vector2(3, -32) * s, 2.0 * s, Color(1.0, 0.85, 0.4))

func _paint() -> void:
	var sz := view.size
	var cx := sz.x / 2.0
	view.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.02))
	# 1. le boss tombe — 2. la Lanterne se rallume (0–14 s)
	if t < 15.0:
		var flame := clampf((t - 6.0) / 3.0, 0.0, 1.0)
		var a := _k(0.0, 15.0, 1.0)
		view.modulate = Color(1, 1, 1, 1)
		if flame > 0.0:
			for i in 12:
				var ang := i * TAU / 12.0 + t * 0.1
				view.draw_line(Vector2(cx, sz.y * 0.48) + Vector2.from_angle(ang) * 90.0, Vector2(cx, sz.y * 0.48) + Vector2.from_angle(ang) * (90.0 + 400.0 * flame), Color(1.0, 0.85, 0.5, 0.08 * flame * a), 6.0)
		_lantern(Vector2(cx, sz.y * 0.48), 2.0, flame * a)
		_watcher(Vector2(cx - 110, sz.y * 0.48 + 78), 2.0, Color(0.12, 0.1, 0.16, a))
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
			view.draw_rect(Rect2(0, y, sz.x, band_h), Color(col.darkened(0.85).lerp(col.darkened(0.55), lit), 1.0))
			view.draw_rect(Rect2(0, y + band_h - 12, sz.x, 12), col.darkened(0.6))
			# silhouette de stalactites et lumière qui monte au centre
			for k in 9:
				var sx := k * sz.x / 8.0
				view.draw_colored_polygon(PackedVector2Array([Vector2(sx - 30, y), Vector2(sx + 30, y), Vector2(sx, y + 40 + 20 * ((k + i) % 3))]), col.darkened(0.75))
			_text(y + band_h * 0.45, tier[0], 30, col.lightened(0.3), lit)
			_text(y + band_h * 0.45 + 40, tier[1], 20, Color(0.9, 0.9, 0.95), lit)
		view.draw_rect(Rect2(cx - 14, 0, 28, sz.y), Color(1.0, 0.85, 0.45, 0.25))
		view.draw_rect(Rect2(cx - 4, 0, 8, sz.y), Color(1.0, 0.95, 0.8, 0.5))
	# 4. le Sanctuaire (31–40 s)
	elif t < 40.0:
		var a2 := _k(31.0, 40.0, 1.0)
		view.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(0.12, 0.09, 0.07))
		view.draw_rect(Rect2(0, sz.y * 0.72, sz.x, sz.y * 0.28), Color(0.25, 0.18, 0.12))
		view.draw_rect(Rect2(cx - 20, 0, 40, sz.y * 0.72), Color(1.0, 0.85, 0.45, 0.3 * a2))
		var folks := [[-260, Color(0.45, 0.33, 0.22)], [-150, Color(0.25, 0.3, 0.42)], [150, Color(0.35, 0.3, 0.38)], [260, Color(0.5, 0.4, 0.32)]]
		for f in folks:
			var fp := Vector2(cx + float(f[0]), sz.y * 0.72)
			view.draw_colored_polygon(_ellipse(fp + Vector2(0, -26), Vector2(16, 26)), f[1])
			view.draw_colored_polygon(_ellipse(fp + Vector2(0, -60), Vector2(11, 10)), (f[1] as Color).lightened(0.2))
			view.draw_circle(fp + Vector2(3 if f[0] < 0 else -3, -62), 2.5, Color(1.0, 0.9, 0.6))
		_lantern(Vector2(cx, sz.y * 0.72 - 45), 0.9, a2)
		_text(sz.y * 0.18, "Au Sanctuaire, tous lèvent les yeux : la lumière remonte jusqu'à eux.", 24, Color(1.0, 0.9, 0.7), _k(31.5, 39.5))
	# 5. la surface, à l'aube (40–49 s)
	elif t < 49.0:
		var a3 := clampf((t - 40.0) / 4.0, 0.0, 1.0)
		for i in 20:
			var yy := i * sz.y / 20.0
			var c := Color(0.08, 0.06, 0.18).lerp(Color(1.0, 0.6, 0.4), (float(i) / 20.0) * a3)
			view.draw_rect(Rect2(0, yy, sz.x, sz.y / 20.0 + 1), c)
		view.draw_circle(Vector2(cx, sz.y * 0.78 - a3 * 60.0), 70.0, Color(1.0, 0.85, 0.5, a3))
		view.draw_colored_polygon(PackedVector2Array([Vector2(0, sz.y), Vector2(0, sz.y * 0.8), Vector2(cx - 120, sz.y * 0.72), Vector2(cx + 160, sz.y * 0.76), Vector2(sz.x, sz.y * 0.82), Vector2(sz.x, sz.y)]), Color(0.06, 0.05, 0.08))
		_watcher(Vector2(cx - 40, sz.y * 0.73), 1.6, Color(0.05, 0.04, 0.07))
		_lantern(Vector2(cx + 10, sz.y * 0.73 - 16), 0.5, 1.0)
		_text(sz.y * 0.2, "Pour la première fois depuis des siècles, la lumière touche la surface.", 26, Color(1.0, 0.95, 0.85), _k(41.0, 48.5))
	# 6. générique (49–66 s)
	else:
		var u2 := (t - 49.0) / (TOTAL - 49.0)
		view.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(0.02, 0.02, 0.05))
		_lantern(Vector2(sz.x - 90, sz.y - 80), 0.6, 1.0)
		for i in CREDITS.size():
			var y := sz.y + 40 - u2 * (sz.y + CREDITS.size() * 50.0) + i * 50.0
			var big := i == 0 or i == CREDITS.size() - 1
			_text(y, CREDITS[i], 36 if big else 22, Color(1.0, 0.88, 0.6) if big else Color(0.85, 0.88, 0.95), 1.0)
	if t > 3.0 and choice == null:
		var font := ThemeDB.fallback_font
		view.draw_string(font, Vector2(0, sz.y - 18), tr("Maintenir Saut ou Frapper : passer"), HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 20, 14, Color(0.6, 0.62, 0.7, 0.7))

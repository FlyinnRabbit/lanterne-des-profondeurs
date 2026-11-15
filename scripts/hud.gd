extends Control
# Interface : réceptacle d'âme, fragments de vie, éclats (monnaie), barre du boss, messages.

const DU = preload("res://scripts/draw_util.gd")
const G = preload("res://scripts/glyphs.gd")

var main
var message := ""
var message_t := 0.0
var shown_soul := 0.0
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	message_t -= delta
	if main and main.player:
		shown_soul = lerpf(shown_soul, float(main.player.soul), minf(delta * 10.0, 1.0))
	queue_redraw()

func _draw() -> void:
	if main == null or main.player == null:
		return
	var p = main.player
	var font := ThemeDB.fallback_font
	# Taille du HUD (Options) : tout est dessiné dans un repère agrandi/réduit
	var hs: float = Settings.hud_scale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(hs, hs))
	var sz := size / hs
	# Réceptacle d'âme
	var c := Vector2(72, 72)
	var r := 36.0
	draw_circle(c, r + 4, Color(0.02, 0.02, 0.05, 0.8))
	var frac := shown_soul / float(p.SOUL_MAX)
	if frac > 0.01:
		if frac >= 0.99:
			draw_circle(c, r, Color(0.92, 0.95, 1.0))
		else:
			var hl := clampf(1.0 - 2.0 * frac, -1.0, 1.0)  # hauteur du niveau, en unités de rayon
			hl += sin(t * 4.0) * 0.03
			var a0 := asin(clampf(hl, -1.0, 1.0))
			draw_colored_polygon(DU.ellipse(c, Vector2(r, r), 24, a0, PI - a0), Color(0.92, 0.95, 1.0))
	draw_arc(c, r + 2, 0, TAU, 40, Color(0.85, 0.88, 0.95), 3.0)
	if p.soul >= p.FOCUS_COST and p.hp < p.max_hp:
		draw_arc(c, r + 8, 0, TAU, 40, Color(1, 1, 1, 0.25 + 0.2 * sin(t * 5.0)), 2.0)
	# Fragments de vie (losanges)
	for i in p.max_hp:
		var pos := Vector2(130 + i * 30, 56)
		var shape := DU.diamond(pos, Vector2(10, 14))
		if i < p.hp:
			draw_colored_polygon(shape, Color(0.95, 0.96, 1.0))
		else:
			draw_colored_polygon(shape, Color(0.1, 0.1, 0.15, 0.8))
		var outline := shape.duplicate()
		outline.append(shape[0])
		draw_polyline(outline, Color(0.7, 0.72, 0.8), 1.5)
	# Jauge d'ultime
	var ux := 120.0
	var uy := 118.0
	var uw := 150.0
	var uf: float = float(p.ult) / float(p.ULT_MAX)
	draw_rect(Rect2(ux, uy, uw, 8), Color(0.05, 0.05, 0.08, 0.85))
	var ucol := Color(1.0, 0.82, 0.4) if uf >= 1.0 else Color(0.75, 0.62, 0.35)
	draw_rect(Rect2(ux, uy, uw * uf, 8), ucol)
	draw_rect(Rect2(ux, uy, uw, 8), Color(0.7, 0.72, 0.8), false, 1.0)
	if uf >= 1.0:
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		draw_rect(Rect2(ux - 3, uy - 3, uw + 6, 14), Color(1.0, 0.85, 0.45, 0.4 * pulse), false, 2.0)
		var ut := "ULTIME : {ultimate|1}"
		G.draw_rich(self, font, ux + uw + 10, G.rich_width(font, ut, 15), uy + 9, ut, 15, Color(1.0, 0.88, 0.55))
	# Éclats (monnaie)
	draw_colored_polygon(DU.diamond(Vector2(136, 96), Vector2(7, 9)), Color(0.75, 0.85, 0.95))
	draw_string(font, Vector2(152, 104), str(p.geo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.92, 1.0))
	# Barre du boss
	if main.boss_started and not main.boss_dead and is_instance_valid(main.boss):
		var w := 500.0
		var bx := (sz.x - w) / 2.0
		var by := sz.y - 60.0
		draw_string(font, Vector2(bx, by - 10), main.boss.boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.85, 0.8))
		draw_rect(Rect2(bx, by, w, 10), Color(0.05, 0.05, 0.08, 0.85))
		draw_rect(Rect2(bx, by, w * float(main.boss.hp) / main.boss.max_hp, 10), Color(0.85, 0.4, 0.3))
	# Flash blanc de l'ultime
	if main.flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.97, 0.88, main.flash * 0.55))
	# Message central
	if message_t > 0.0 and message != "":
		var alpha := clampf(message_t, 0.0, 1.0)
		var lines := message.split("\n")
		for i in lines.size():
			var fs := 34 if i == 0 else 22
			var y := sz.y * 0.28 + i * 38.0
			G.draw_rich(self, font, 0, sz.x, y, lines[i], fs, Color(0.92, 0.94, 1.0, alpha), true)
	# Panneau du tutoriel
	if main.sign_text != "":
		var sl: PackedStringArray = main.sign_text.split("\n")
		var bw := 200.0
		for line in sl:
			bw = maxf(bw, G.rich_width(font, line, 21) + 60.0)
		bw = minf(bw, sz.x - 20.0)
		var bh := 24.0 + sl.size() * 30.0
		var bpos := Vector2((sz.x - bw) / 2.0, sz.y - 120.0 - bh)
		draw_rect(Rect2(bpos, Vector2(bw, bh)), Color(0.03, 0.04, 0.08, 0.88))
		draw_rect(Rect2(bpos, Vector2(bw, bh)), Color(0.6, 0.75, 0.95, 0.8), false, 2.0)
		for i in sl.size():
			G.draw_rich(self, font, bpos.x, bw, bpos.y + 38 + i * 30, sl[i], 21, Color(0.95, 0.96, 1.0))
	# Compteur d'images par seconde (Options)
	if Settings.show_fps:
		draw_string(font, Vector2(sz.x - 110, 28), "%d FPS" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_RIGHT, 100, 16, Color(0.7, 1.0, 0.7, 0.9))
	# Aide contextuelle
	var hint := ""
	if main.interact_hint != "":
		hint = main.interact_hint
	elif not p.sitting and not p.dead and p.global_position.distance_to(main.bench_pos) < 48:
		hint = "{up|1} : se reposer sur le banc"
	elif p.sitting:
		hint = "{inventory|1} : changer d'équipement    bouger : se lever"
	elif t < 14.0 and not GameState.is_tutorial():
		hint = "{move_left|1}{move_right|1} bouger   {jump|1} sauter   {attack|1} frapper   {dash|1} ruée   {parry|1} parade   {spell|1} sort   {ultimate|1} ultime   {focus|1} soin   {inventory|1} inventaire   {pause|1} pause"
	if hint != "" and (Settings.show_hints or main.interact_hint != ""):
		G.draw_rich(self, font, 0, sz.x, sz.y - 18, hint, 16, Color(0.75, 0.8, 0.9, 0.9))

extends Control
# Interface : réceptacle d'âme, fragments de vie, éclats (monnaie), barre du boss, messages.

const MapView = preload("res://scripts/map_view.gd")
const DU = preload("res://scripts/draw_util.gd")
const G = preload("res://scripts/glyphs.gd")

var main
var message := ""
var message_t := 0.0
var shown_soul := 0.0
var damage_log := []     # [dégâts, nom, type de coup, coup fatal, âge]
const LOG_TIME := 1.6
var t := 0.0
var toasts := []        # [texte, âge] : succès débloqués

func _ready() -> void:
	Achievements.unlocked.connect(func(id):
		toasts.append([tr("Succès débloqué : %s") % tr(Achievements.info(id)[1]), 0.0])
		Audio.sfx("achievement", 0.0, 0.0))
	Achievements.cosmetic_unlocked.connect(func(item_id):
		toasts.append([tr("Cosmétique obtenu : %s") % tr(GameState.cos.item(item_id)["name"]), 0.0]))

func add_damage(dmg: int, who: String, kind: String, killed: bool) -> void:
	if not Settings.damage_numbers:
		return
	# regroupe les coups rapides sur la même cible
	if not damage_log.is_empty() and damage_log[0][1] == who and damage_log[0][4] < 0.25 and not damage_log[0][3]:
		damage_log[0][0] += dmg
		damage_log[0][3] = killed
		damage_log[0][4] = 0.0
		return
	damage_log.push_front([dmg, who, kind, killed, 0.0])
	if damage_log.size() > 6:
		damage_log.pop_back()

func _process(delta: float) -> void:
	t += delta
	for d in damage_log:
		d[4] += delta
	damage_log = damage_log.filter(func(d): return d[4] < LOG_TIME)
	message_t -= delta
	for ts in toasts:
		ts[1] += delta
	toasts = toasts.filter(func(ts): return ts[1] < 4.0)
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
	# Réceptacle d'âme : flacon de verre cerclé de laiton, liquide qui ondule
	var c := Vector2(72, 72)
	var r := 36.0
	var brass := Color(0.72, 0.58, 0.32)
	var soul_c := Color(0.85, 0.92, 1.0)
	DU.glow(self, c, r * 1.6, Color(0.5, 0.65, 1.0), 0.25 + 0.3 * (shown_soul / float(p.SOUL_MAX)))
	draw_circle(c, r + 6, Color(0.03, 0.025, 0.04, 0.9))
	draw_circle(c, r, Color(0.04, 0.05, 0.1))
	var frac := shown_soul / float(p.SOUL_MAX)
	if frac > 0.01:
		var top := c.y + r - 2.0 * r * frac
		var pts := PackedVector2Array()
		var n := 28
		for i in n + 1:
			var x := c.x - r + 2.0 * r * i / n
			var dx := x - c.x
			var half := sqrt(maxf(r * r - dx * dx, 0.0))
			var wy := top + sin(t * 3.0 + i * 0.6) * 1.8 + sin(t * 1.7 - i * 0.3) * 1.2 if frac < 0.99 else c.y - half
			pts.append(Vector2(x, clampf(wy, c.y - half, c.y + half)))
		for i in range(n, -1, -1):
			var x := c.x - r + 2.0 * r * i / n
			var dx := x - c.x
			pts.append(Vector2(x, c.y + sqrt(maxf(r * r - dx * dx, 0.0))))
		var cols := PackedColorArray()
		for q in pts:
			var k := clampf((q.y - (c.y - r)) / (2.0 * r), 0.0, 1.0)
			cols.append(Color(0.95, 0.97, 1.0).lerp(Color(0.45, 0.6, 0.95), k))
		if not Geometry2D.triangulate_polygon(pts).is_empty():
			draw_polygon(pts, cols)
		# bulles qui montent dans le liquide
		for i in 4:
			var u := fposmod(t * 0.4 + i * 0.27, 1.0)
			var by2 := lerpf(c.y + r - 4.0, top + 3.0, u)
			if by2 > top + 2.0:
				draw_circle(Vector2(c.x - 14 + i * 9 + sin(t * 2.0 + i) * 2.0, by2), 1.6, Color(1, 1, 1, 0.6))
	# reflet du verre et cerclage
	draw_arc(c, r - 5, PI * 1.1, PI * 1.45, 12, Color(1, 1, 1, 0.45), 3.0)
	draw_arc(c, r + 3, 0, TAU, 48, brass.darkened(0.45), 6.0)
	draw_arc(c, r + 3, 0, TAU, 48, brass, 3.0)
	draw_arc(c, r + 3, PI * 1.05, PI * 1.6, 16, DU.lit(brass, 1.5, 0.1), 1.6)
	for k in 8:
		var aa := k * TAU / 8.0 + PI / 8.0
		DU.ball(self, c + Vector2.from_angle(aa) * (r + 3), 2.4, brass.lightened(0.1))
	# petite lanterne au sommet du flacon
	DU.box(self, Rect2(c + Vector2(-6, -r - 12), Vector2(12, 6)), brass)
	draw_arc(c + Vector2(0, -r - 13), 4.0, PI, TAU, 8, brass, 1.6)
	if p.soul >= p.FOCUS_COST and p.hp < p.max_hp:
		draw_arc(c, r + 10, 0, TAU, 48, Color(soul_c, 0.25 + 0.2 * sin(t * 5.0)), 2.0)
	# Masques de vie : petits masques peints, qui se fissurent quand ils se vident
	for i in p.max_hp:
		var pos := Vector2(132 + i * 32, 56)
		var mask := PackedVector2Array([pos + Vector2(-10, -12), pos + Vector2(-6, -15), pos + Vector2(6, -15), pos + Vector2(10, -12),
			pos + Vector2(10, 2), pos + Vector2(5, 12), pos + Vector2(0, 15), pos + Vector2(-5, 12), pos + Vector2(-10, 2)])
		draw_colored_polygon(mask, Color(0.02, 0.02, 0.04, 0.85))
		var inner := PackedVector2Array()
		for q in mask:
			inner.append(pos + (q - pos) * 0.86)
		if i < p.hp:
			DU.poly(self, inner, Color(0.93, 0.94, 1.0), false)
			draw_colored_polygon(DU.ellipse(pos + Vector2(-4, -3), Vector2(2.6, 3.4)), Color(0.08, 0.08, 0.14))
			draw_colored_polygon(DU.ellipse(pos + Vector2(4, -3), Vector2(2.6, 3.4)), Color(0.08, 0.08, 0.14))
			draw_line(pos + Vector2(-7, -10), pos + Vector2(-2, -12), Color(1, 1, 1, 0.8), 1.4)
		else:
			draw_colored_polygon(inner, Color(0.12, 0.12, 0.18, 0.9))
			draw_polyline(PackedVector2Array([pos + Vector2(-2, -13), pos + Vector2(1, -5), pos + Vector2(-3, 2), pos + Vector2(1, 11)]), Color(0.35, 0.36, 0.45), 1.2)
		var outline := mask.duplicate()
		outline.append(mask[0])
		draw_polyline(outline, Color(0.7, 0.72, 0.8) if i < p.hp else Color(0.35, 0.36, 0.45), 1.4)
	# Jauge d'ultime : tube de laiton qui se remplit de lumière dorée
	var ux := 122.0
	var uy := 118.0
	var uw := 150.0
	var uf: float = float(p.ult) / float(p.ULT_MAX)
	DU.box(self, Rect2(ux - 3, uy - 3, uw + 6, 14), brass.darkened(0.35))
	draw_rect(Rect2(ux, uy, uw, 8), Color(0.05, 0.04, 0.03, 0.95))
	var ucol := Color(1.0, 0.82, 0.4) if uf >= 1.0 else Color(0.85, 0.62, 0.3)
	if uf > 0.0:
		DU.vgrad(self, Rect2(ux, uy, uw * uf, 8), ucol.lightened(0.3), ucol.darkened(0.2))
		draw_line(Vector2(ux, uy + 1.5), Vector2(ux + uw * uf, uy + 1.5), Color(1, 1, 1, 0.5), 1.0)
	for k in range(1, 5):
		draw_line(Vector2(ux + uw * k / 5.0, uy), Vector2(ux + uw * k / 5.0, uy + 8), Color(0.1, 0.08, 0.05, 0.6), 1.0)
	if uf >= 1.0:
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		DU.glow(self, Vector2(ux + uw / 2.0, uy + 4), uw * 0.6, Color(1.0, 0.85, 0.45), 0.35 * pulse)
		var ut := "ULTIME : {ultimate|1}"
		G.draw_rich(self, font, ux + uw + 10, G.rich_width(font, ut, 15), uy + 9, ut, 15, Color(1.0, 0.88, 0.55))
	# Éclats (monnaie) : petit cristal à facettes qui scintille
	var gp := Vector2(136, 96)
	DU.glow(self, gp, 12.0, Color(0.7, 0.85, 1.0), 0.4)
	draw_colored_polygon(PackedVector2Array([gp + Vector2(0, -10), gp + Vector2(7, -3), gp + Vector2(4, 9), gp + Vector2(-4, 9), gp + Vector2(-7, -3)]), Color(0.6, 0.78, 0.95))
	draw_colored_polygon(PackedVector2Array([gp + Vector2(0, -10), gp + Vector2(7, -3), gp + Vector2(0, 0), gp + Vector2(-7, -3)]), Color(0.85, 0.94, 1.0))
	draw_line(gp + Vector2(0, 0), gp + Vector2(0, 9), Color(0.4, 0.55, 0.75), 1.0)
	var twk := absf(sin(t * 2.3))
	draw_line(gp + Vector2(-4, -8) - Vector2(2.5, 0) * twk, gp + Vector2(-4, -8) + Vector2(2.5, 0) * twk, Color(1, 1, 1, twk), 1.0)
	draw_string(font, Vector2(153, 105), str(p.geo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.05, 0.05, 0.08, 0.8))
	draw_string(font, Vector2(152, 104), str(p.geo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.92, 1.0))
	if GameState.one_life:
		# mode « une seule vie » : petit crâne d'os après les éclats
		var kx := 152.0 + font.get_string_size(str(p.geo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 20.0
		var kc := Vector2(kx, 96)
		DU.glow(self, kc, 12.0, Color(1.0, 0.4, 0.3), 0.3)
		draw_circle(kc + Vector2(0, -1), 7.0, Color(0.92, 0.88, 0.8))
		draw_rect(Rect2(kc + Vector2(-4, 4), Vector2(8, 5)), Color(0.92, 0.88, 0.8))
		draw_circle(kc + Vector2(-2.7, -1), 2.0, Color(0.15, 0.05, 0.05))
		draw_circle(kc + Vector2(2.7, -1), 2.0, Color(0.15, 0.05, 0.05))
		draw_line(kc + Vector2(-1.5, 6), kc + Vector2(-1.5, 9), Color(0.3, 0.2, 0.2), 1.0)
		draw_line(kc + Vector2(1.5, 6), kc + Vector2(1.5, 9), Color(0.3, 0.2, 0.2), 1.0)
	# Barre du boss : plaque de fer forgé, liseré, rouge sombre
	if main.boss_started and not main.boss_dead and is_instance_valid(main.boss):
		var w := 500.0
		var bx := (sz.x - w) / 2.0
		var by := sz.y - 60.0
		var bf: float = float(main.boss.hp) / main.boss.max_hp
		draw_string(font, Vector2(bx + 1, by - 9), tr(main.boss.boss_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(bx, by - 10), tr(main.boss.boss_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.88, 0.78))
		DU.box(self, Rect2(bx - 4, by - 3, w + 8, 16), Color(0.25, 0.22, 0.22))
		draw_rect(Rect2(bx, by, w, 10), Color(0.05, 0.03, 0.03, 0.95))
		DU.vgrad(self, Rect2(bx, by, w * bf, 10), Color(0.95, 0.42, 0.32), Color(0.55, 0.12, 0.1))
		draw_line(Vector2(bx, by + 1.5), Vector2(bx + w * bf, by + 1.5), Color(1, 0.8, 0.7, 0.5), 1.0)
		for side in [-1.0, 1.0]:
			var ex: float = bx + w / 2.0 + side * (w / 2.0 + 8.0)
			draw_colored_polygon(DU.diamond(Vector2(ex, by + 5), Vector2(6, 8)), Color(0.6, 0.5, 0.35))
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
	# Chronomètre (descente du jour, défi des boss, défi chronométré)
	if GameState.daily or GameState.mode == "rush":
		var tt := int(Achievements.run.get("time", 0.0))
		var ts2 := "%d:%02d" % [tt / 60, tt % 60]
		draw_string(font, Vector2(0, 32), ts2, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 24, Color(0.85, 0.92, 1.0))
	if main.challenge_t > 0.0:
		var ct := "%.1f" % main.challenge_t
		draw_string(font, Vector2(0, 64), tr("Défi : %s s") % ct, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 26, Color(1.0, 0.75, 0.35) if main.challenge_t > 3.0 else Color(1.0, 0.4, 0.3))
	# Succès débloqués (bandeau en haut au centre)
	for i in toasts.size():
		var ts: Array = toasts[i]
		var ta := clampf(minf(ts[1] * 4.0, (4.0 - ts[1]) * 2.0), 0.0, 1.0)
		var tw := font.get_string_size(ts[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 40.0
		var tp := Vector2((sz.x - tw) / 2.0, 18.0 + i * 44.0)
		draw_rect(Rect2(tp, Vector2(tw, 36)), Color(0.08, 0.06, 0.02, 0.85 * ta))
		draw_rect(Rect2(tp, Vector2(tw, 36)), Color(1.0, 0.8, 0.4, ta), false, 2.0)
		draw_string(font, tp + Vector2(20, 24), ts[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.9, 0.6, ta))
	# Panneau du tutoriel
	if main.sign_text != "":
		var sl: PackedStringArray = main.sign_text.split("\n")
		var bw := 200.0
		for line in sl:
			bw = maxf(bw, G.rich_width(font, line, 19) + 60.0)
		bw = minf(bw, sz.x - 20.0)
		var bh := 18.0 + sl.size() * 26.0
		# tout en bas de l'écran, juste au-dessus de la ligne des commandes : le centre reste dégagé
		var bpos := Vector2((sz.x - bw) / 2.0, sz.y - 38.0 - bh)
		draw_rect(Rect2(bpos, Vector2(bw, bh)), Color(0.03, 0.04, 0.08, 0.88))
		draw_rect(Rect2(bpos, Vector2(bw, bh)), Color(0.6, 0.75, 0.95, 0.8), false, 2.0)
		for i in sl.size():
			G.draw_rich(self, font, bpos.x, bw, bpos.y + 31 + i * 26, sl[i], 19, Color(0.95, 0.96, 1.0))
	# Dégâts infligés : coin en haut à droite, disparaissent vite
	var ly := 64.0 if Settings.show_fps else 40.0
	# Mini-carte (en descente)
	if Settings.minimap and GameState.mode == "descent" and main.player:
		var mw := 26
		var mh := 12
		var mc := 7.0
		var mo := Vector2(sz.x - mw * mc - 16.0, ly - 16.0)
		var pc := Vector2i(floori(main.player.global_position.x / main.TILE), floori(main.player.global_position.y / main.TILE))
		var mr := Rect2i(pc - Vector2i(mw / 2, mh / 2), Vector2i(mw, mh))
		var mrect := Rect2(mo - Vector2(4, 4), Vector2(mw * mc + 8, mh * mc + 8))
		DU.box(self, mrect.grow(4), Color(0.55, 0.42, 0.24))
		DU.vgrad(self, mrect, Color(MapView.PAPER, 0.92), Color(0.7, 0.58, 0.4, 0.92))
		MapView.draw_cells(self, main, mo, mc, mr)
		MapView.draw_markers(self, main, mo, mc, mr, false)
		draw_rect(mrect, Color(0.3, 0.2, 0.1, 0.8), false, 1.5)
		ly += mh * mc + 24.0
	for d in damage_log:
		var a: float = clampf((LOG_TIME - d[4]) / 0.5, 0.0, 1.0)
		var slide: float = clampf(d[4] / 0.12, 0.0, 1.0)
		var col := Color(1.0, 1.0, 1.0)
		match d[2]:
			"finisher": col = Color(1.0, 0.85, 0.45)
			"spin": col = Color(1.0, 0.65, 0.35)
			"thrust": col = Color(0.75, 0.95, 1.0)
			"autre": col = Color(0.7, 0.85, 1.0)
			"crit": col = Color(1.0, 0.45, 0.25)
		var big := (tr("CRITIQUE -%d") if d[2] == "crit" else "-%d") % d[0]
		var fs := 26 if d[0] >= 3 else 22
		var x := sz.x - 24.0 + (1.0 - slide) * 30.0
		var bw := font.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(x - bw + 2, ly + 2), big, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.6 * a))
		draw_string(font, Vector2(x - bw, ly), big, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, a))
		var who: String = d[1] + (tr(" — vaincu") if d[3] else "")
		var ww := font.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(x - bw - ww - 8, ly - 2), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.82, 0.9, 0.8 * a))
		ly += 30.0
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
		hint = "{move_left|1}{move_right|1} bouger   {jump|1} sauter   {attack|1} frapper   {dash|1} ruée   {parry|1} parade   {spell|1} sort   {ultimate|1} ultime   {focus|1} soin   {inventory|1} inventaire   {map|1} carte   {pause|1} pause"
	if hint != "" and (Settings.show_hints or main.interact_hint != ""):
		G.draw_rich(self, font, 0, sz.x, sz.y - 18, hint, 16, Color(0.75, 0.8, 0.9, 0.9))

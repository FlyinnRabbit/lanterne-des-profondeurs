extends Control
# Interface du duel : masques et âme des deux joueurs, score des manches, compte à rebours.
const DU = preload("res://scripts/draw_util.gd")
const W = preload("res://scripts/weapons.gd")
var main
var cd_t := 0.0
var cd_total := 0.0
var msg := ""
var msg_t := 0.0

func countdown(t: float) -> void:
	cd_t = t
	cd_total = t

func announce(text: String) -> void:
	msg = text
	msg_t = 2.0

func _process(delta: float) -> void:
	if cd_t > 0.0 and cd_t - delta <= 0.0:
		announce(tr("Combattez !"))
		msg_t = 0.9
	cd_t = maxf(cd_t - delta, 0.0)
	msg_t = maxf(msg_t - delta, 0.0)
	queue_redraw()

func _side(p, n: int, right: bool) -> void:
	var f := get_theme_default_font()
	var w := size.x
	var col := Color(0.75, 0.88, 1.0) if n == 1 else Color(1.0, 0.72, 0.68)
	var x0 := 40.0 if not right else w - 40.0
	var dirx := 1.0 if not right else -1.0
	var name := tr("Joueur %d") % n + "  —  " + tr(W.W[p.duel_weapon]["name"]) if W.W.has(p.duel_weapon) else tr("Joueur %d") % n
	draw_string(f, Vector2(x0 if not right else x0 - 420.0, 46), name, HORIZONTAL_ALIGNMENT_LEFT if not right else HORIZONTAL_ALIGNMENT_RIGHT, 420, 20, col)
	for i in p.max_hp:
		var c := Vector2(x0 + dirx * (14.0 + i * 30.0), 78)
		var full: bool = i < p.hp
		DU.flat(self, PackedVector2Array([c + Vector2(0, -12), c + Vector2(10, -4), c + Vector2(7, 11), c + Vector2(-7, 11), c + Vector2(-10, -4)]), col if full else Color(0.2, 0.22, 0.28, 0.8))
		if full:
			draw_circle(c + Vector2(-3, -2), 2.0, Color(0.05, 0.05, 0.08))
			draw_circle(c + Vector2(3, -2), 2.0, Color(0.05, 0.05, 0.08))
	# âme
	var sw := 200.0
	var sx := x0 if not right else x0 - sw
	draw_rect(Rect2(sx, 100, sw, 8), Color(0.1, 0.1, 0.14, 0.8))
	var k := clampf(float(p.soul) / float(p.SOUL_MAX), 0.0, 1.0)
	draw_rect(Rect2(sx if not right else sx + sw * (1.0 - k), 100, sw * k, 8), Color(0.85, 0.9, 1.0))

func _draw() -> void:
	if main == null or main.duel_players.size() < 2:
		return
	var f := get_theme_default_font()
	_side(main.duel_players[0], 1, false)
	_side(main.duel_players[1], 2, true)
	# score des manches
	var s: Array = GameState.duel_score
	var cx := size.x / 2.0
	draw_string(f, Vector2(cx - 150, 60), "%d   —   %d" % [s[0], s[1]], HORIZONTAL_ALIGNMENT_CENTER, 300, 40, Color(1.0, 0.88, 0.55))
	draw_string(f, Vector2(cx - 200, 92), tr("Premier à %d manches") % GameState.DUEL_TARGET, HORIZONTAL_ALIGNMENT_CENTER, 400, 15, Color(0.75, 0.75, 0.8))
	# compte à rebours
	if cd_t > 0.0:
		var n := int(ceil(cd_t / (cd_total / 3.0)))
		var txt := str(n)
		draw_string(f, Vector2(cx - 300, size.y / 2.0 - 30), txt, HORIZONTAL_ALIGNMENT_CENTER, 600, 72, Color(1.0, 0.9, 0.6))
	elif msg_t > 0.0:
		draw_string(f, Vector2(cx - 400, size.y / 2.0 - 30), msg, HORIZONTAL_ALIGNMENT_CENTER, 800, 48, Color(1.0, 0.9, 0.6, minf(msg_t, 1.0)))

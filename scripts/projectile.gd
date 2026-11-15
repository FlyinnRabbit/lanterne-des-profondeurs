extends Node2D
# Projectiles ennemis. Une parade les renvoie (ils blessent alors les ennemis).
#  kind "spore" : boule de spores en ligne droite (cracheurs, Abbesse, Reine)
#  kind "rock"  : rocher qui tombe (Colosse) — soumis à la gravité
#  kind "wave"  : onde de choc qui court au sol (Gardien, Colosse, Ver)
#  kind "acid"  : crachat acide en cloche (Ver) — soumis à la gravité
#  kind "ember" : braise spectrale (Chevalier)

var main
var vel := Vector2.ZERO
var hostile := true
var life := 5.0
var radius := 7.0
var gravity := 0.0
var kind := "spore"
var pierce := false      # traverse les ennemis (lame d'âme)
var damage := 3
var crit := false
var _hit := {}
var t := 0.0

func _ready() -> void:
	add_to_group("projectiles")
	z_index = 2
	if kind == "wave":
		life = minf(life, 3.0)

func get_rect() -> Rect2:
	if kind == "wave":
		return Rect2(global_position - Vector2(12, 34), Vector2(24, 36))
	return Rect2(global_position - Vector2(radius, radius), Vector2(radius, radius) * 2.0)

func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	vel.y += gravity * delta
	global_position += vel * delta
	if kind == "wave":
		# l'onde suit le sol : elle s'arrête contre un mur ou au bord du vide
		var ahead := global_position + Vector2(signf(vel.x) * 14.0, -10.0)
		if main.is_solid_at(ahead) or not main.is_solid_at(global_position + Vector2(0, 6)):
			pop()
			return
	elif main.is_solid_at(global_position):
		pop()
		return
	var r := get_rect()
	if hostile:
		var p = main.player
		if not p.dead and p.dash_t <= 0.0 and r.intersects(p.get_rect()):
			var parried: bool = p.receive_hit(global_position, self)
			if not parried:
				pop()
	else:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.dead and not _hit.has(e) and r.intersects(e.get_rect()):
				if crit:
					main.player.last_crit_t = 0.2
				e.take_hit(damage, vel.normalized())
				_hit[e] = true
				if kind == "shuriken":
					var pl = main.player
					pl.soul = mini(pl.soul + 7, pl.SOUL_MAX)
					pl.ult = mini(pl.ult + 4, pl.ULT_MAX)
					Audio.sfx("hit", 0.1, -3.0)
				if not pierce:
					pop()
					return
				main.shake(3)
				main.player.ult = mini(main.player.ult + 3, main.player.ULT_MAX)
	queue_redraw()

func parried(_dir: Vector2) -> void:
	hostile = false
	life = 3.0
	gravity = 0.0
	vel = -vel * 1.6

func pop() -> void:
	var c := Color(0.75, 0.9, 1.0) if not hostile else _color()
	main.spawn_burst(global_position, c, 8, 120.0, 0.0)
	queue_free()

func _color() -> Color:
	match kind:
		"rock": return Color(0.6, 0.55, 0.5)
		"wave": return Color(1.0, 0.85, 0.55)
		"acid": return Color(0.6, 1.0, 0.35)
		"ember": return Color(0.55, 0.85, 1.0)
		"soulblade": return Color(0.85, 0.95, 1.0)
		"shuriken": return Color(0.8, 0.85, 0.95)
		"dart": return Color(1.0, 0.55, 0.3)
	return Color(0.85, 0.45, 0.95)

func _draw() -> void:
	var c := _color() if hostile else Color(0.6, 0.9, 1.0)
	if crit and kind == "soulblade":
		c = Color(1.0, 0.75, 0.35)
	match kind:
		"rock":
			var pts := PackedVector2Array()
			for i in 7:
				var a := i * TAU / 7.0 + t * 3.0
				pts.append(Vector2(cos(a), sin(a)) * radius * (0.8 + 0.25 * sin(i * 2.3)))
			draw_colored_polygon(pts, c.darkened(0.3))
			draw_polyline(pts + PackedVector2Array([pts[0]]), c, 1.5)
		"wave":
			var h := 30.0 + sin(t * 30.0) * 4.0
			var d := signf(vel.x)
			draw_colored_polygon(PackedVector2Array([Vector2(-10 * d, 0), Vector2(8 * d, 0), Vector2(2 * d, -h), Vector2(-4 * d, -h * 0.6)]), Color(c, 0.85))
			draw_circle(Vector2(0, -4), 14.0, Color(c, 0.2))
		"acid":
			draw_circle(Vector2.ZERO, radius * 1.8, Color(c, 0.2))
			draw_circle(Vector2.ZERO, radius, c)
			draw_circle(Vector2(-2, -2), radius * 0.35, Color(1, 1, 1, 0.7))
		"dart":
			var dd := signf(vel.x)
			draw_line(Vector2(-dd * 12, 0), Vector2(dd * 6, 0), Color(0.55, 0.4, 0.3), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(dd * 10, 0), Vector2(dd * 4, -3), Vector2(dd * 4, 3)]), Color(1.0, 0.6, 0.35))
			draw_line(Vector2(-dd * 12, -3), Vector2(-dd * 9, 0), Color(0.9, 0.85, 0.7), 1.5)
			draw_line(Vector2(-dd * 12, 3), Vector2(-dd * 9, 0), Color(0.9, 0.85, 0.7), 1.5)
		"shuriken":
			var cc := Color(1.0, 0.75, 0.35) if crit else Color(0.85, 0.9, 1.0)
			for i in 4:
				var a := i * PI / 2.0 + t * 25.0
				draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - 0.4) * radius * 0.45, Vector2.from_angle(a) * radius]), cc)
			draw_circle(Vector2.ZERO, radius * 0.22, Color(0.2, 0.22, 0.3))
		"soulblade":
			var d := signf(vel.x)
			draw_circle(Vector2.ZERO, radius * 2.0, Color(0.7, 0.85, 1.0, 0.15))
			draw_arc(Vector2(-d * 6, 0), radius * 1.4, -PI / 2.0 + (0.0 if d > 0 else PI), PI / 2.0 + (0.0 if d > 0 else PI), 16, Color(1, 1, 1, 0.95), 5.0)
			draw_arc(Vector2(-d * 12, 0), radius * 1.1, -PI / 2.0 + (0.0 if d > 0 else PI), PI / 2.0 + (0.0 if d > 0 else PI), 12, Color(0.6, 0.85, 1.0, 0.6), 3.0)
		"ember":
			draw_circle(Vector2.ZERO, radius * 2.2, Color(c, 0.18))
			draw_colored_polygon(PackedVector2Array([Vector2(radius * 1.6, 0), Vector2(0, radius), Vector2(-radius, 0), Vector2(0, -radius)]).duplicate(), c)
		_:
			draw_circle(Vector2.ZERO, radius * 2.0, Color(c, 0.18))
			draw_circle(Vector2.ZERO, radius + sin(t * 20.0), c)
			draw_circle(Vector2(-2, -2), radius * 0.4, Color(1, 1, 1, 0.8))

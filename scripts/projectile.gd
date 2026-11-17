extends Node2D
const DU = preload("res://scripts/draw_util.gd")
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
var boomerang := false   # étoiles niv. 2 : reviennent vers le joueur
var returning := false
var colorblind := false
var volley = null       # étoiles d'une même salve : un seul coup par ennemi (Dictionary partagé)
var from_trap := false   # fléchette de totem : la parer ne rapporte ni âme ni ultime

func _ready() -> void:
	add_to_group("projectiles")
	z_index = 2
	if kind == "wave":
		life = minf(life, 3.0)

func get_rect() -> Rect2:
	if kind == "webpatch":
		return Rect2(global_position - Vector2(22, 10), Vector2(44, 12))
	if kind == "wave":
		return Rect2(global_position - Vector2(12, 34), Vector2(24, 36))
	return Rect2(global_position - Vector2(radius, radius), Vector2(radius, radius) * 2.0)

func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if boomerang:
		if not returning and t > 0.32:
			returning = true
			_hit.clear()
		if returning:
			var to: Vector2 = main.player.global_position - global_position
			if to.length() < 22.0:
				queue_free()
				return
			vel = vel.lerp(to.normalized() * 620.0, minf(delta * 10.0, 1.0))
			life = maxf(life, 0.2)
	vel.y += gravity * delta
	global_position += vel * delta
	if kind == "wave":
		# l'onde suit le sol : elle franchit les marches d'une case (montée ou descente)
		# et ne s'arrête que contre un vrai mur ou au bord du vide
		var T: float = main.TILE
		var ahead := global_position + Vector2(signf(vel.x) * 14.0, -10.0)
		if main.is_solid_at(ahead):
			if not main.is_solid_at(ahead + Vector2(0, -T)) and not main.is_solid_at(global_position + Vector2(0, -T - 10.0)):
				global_position.y -= T          # marche montante
			else:
				pop()
				return
		if not main.is_solid_at(global_position + Vector2(0, 6)):
			if main.is_solid_at(global_position + Vector2(0, 6 + T)):
				global_position.y += T          # marche descendante
			else:
				pop()
				return
	elif kind == "webpatch":
		pass
	elif main.is_solid_at(global_position) and not returning:
		if kind == "web" and hostile:
			_web_patch()
		if boomerang:
			returning = true
			_hit.clear()
		else:
			pop()
			return
	var r := get_rect()
	if hostile:
		var p = main.player
		if not p.dead and p.dash_t <= 0.0 and r.intersects(p.get_rect()):
			if kind == "webpatch":
				p.ensnare(0.4)           # la toile au sol colle tant qu'on marche dessus
			elif kind == "web":
				# boule de toile : englue au lieu de blesser (une parade la renvoie)
				if p.parry_t > 0.0:
					p.receive_hit(global_position, self)
				else:
					p.ensnare(2.2)
					pop()
			else:
				var parried: bool = p.receive_hit(global_position, self)
				if not parried:
					pop()
	else:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.dead and not _hit.has(e) and r.intersects(e.get_rect()):
				# le boss ne se touche que depuis l'intérieur de son arène
				if e.is_boss and main.entry_gate and is_instance_valid(main.entry_gate) and not main.in_arena(main.player.global_position):
					continue
				if volley != null and not returning and volley.has(e):
					continue
				if volley != null and not returning:
					volley[e] = true
				if crit:
					main.player.last_crit_t = 0.2
				var dm := damage
				if kind == "shuriken" and e.is_boss:
					# les boss encaissent mieux les coups à distance : 75 % des dégâts (cumulés)
					var acc: float = float(e.get_meta("ranged_acc", 0.0)) + damage * 0.75
					dm = floori(acc)
					e.set_meta("ranged_acc", acc - dm)
				if dm > 0:
					e.take_hit(dm, vel.normalized())
				else:
					main.spawn_burst(global_position, Color(0.8, 0.85, 1.0), 4, 120.0)
				_hit[e] = true
				if kind == "shuriken":
					var pl = main.player
					pl.soul = mini(pl.soul + 3, pl.SOUL_MAX)
					pl.ult = mini(pl.ult + 2, pl.ULT_MAX)
					Audio.sfx("star_hit", 0.1, -3.0)
					if boomerang and not returning:
						returning = true
						_hit.clear()
						_hit[e] = true
						life = maxf(life, 0.9)
				if not pierce and not boomerang:
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

# la toile qui touche le sol y reste un moment, en nappe collante
func _web_patch() -> void:
	var y := global_position.y
	for i in 3:
		if main.is_solid_at(Vector2(global_position.x, y + 4.0)):
			break
		y += 8.0
	main.spawn_projectile(Vector2(global_position.x, floorf((y + 4.0) / main.TILE) * main.TILE), Vector2.ZERO, {"kind": "webpatch", "life": 5.0, "radius": 22.0})

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
		"web", "webpatch": return Color(0.9, 0.9, 0.97)
		"page": return Color(0.95, 0.88, 0.7)
		"slashwave": return Color(0.85, 0.92, 1.0)
	return Color(0.85, 0.45, 0.95)

# traînée effilée derrière le projectile (dans le sens opposé à sa vitesse)
func _tail(c: Color, w: float, l: float) -> void:
	if vel.length() < 20.0:
		return
	var d := -vel.normalized()
	var nn := d.orthogonal() * w
	var end := d * minf(l, vel.length() * 0.06 + 6.0)
	draw_polygon(PackedVector2Array([nn, end, -nn]), PackedColorArray([Color(c, 0.6), Color(c, 0.0), Color(c, 0.6)]))

func _draw() -> void:
	var c := _color() if hostile else Color(0.6, 0.9, 1.0)
	if hostile and Settings.colorblind:
		c = Color(1.0, 0.1, 0.85)
		draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 16, Color(1, 1, 1), 2.0)
	if crit and kind == "soulblade":
		c = Color(1.0, 0.75, 0.35)
	match kind:
		"page":
			# page arrachée qui tournoie, lignes d'écriture, bord rougeoyant
			_tail(c, 3.0, 20.0)
			var a := t * 12.0
			var u := Vector2.from_angle(a) * 7.0
			var v := Vector2.from_angle(a + PI / 2.0) * 5.0 * absf(cos(t * 7.0))
			DU.flat(self, PackedVector2Array([-u - v, u - v, u + v, -u + v]), c)
			for k in 3:
				var f := -0.5 + k * 0.5
				draw_line(-u * 0.7 + v * f * 0.8, u * 0.7 + v * f * 0.8, Color(0.3, 0.2, 0.25, 0.7), 0.8)
			draw_line(-u - v, u - v, Color(1.0, 0.45, 0.6, 0.8), 1.2)
			return
		"web":
			# boule de toile : pelote de fils qui tourne, brins qui traînent
			_tail(Color(0.95, 0.95, 1.0), radius * 0.5, 24.0)
			for k in 6:
				var a := k * PI / 3.0 + t * 4.0
				draw_line(Vector2.from_angle(a) * radius, Vector2.from_angle(a + PI * 0.8) * radius, Color(0.95, 0.95, 1.0, 0.85), 1.2)
			draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 12, Color(0.95, 0.95, 1.0, 0.7), 1.0)
			return
		"webpatch":
			# nappe de toile au sol, qui s'estompe à la fin
			var fa := clampf(life / 1.0, 0.0, 1.0)
			var wc := Color(0.92, 0.92, 0.98, 0.55 * fa)
			for k in 7:
				var x := -22.0 + k * 7.3
				draw_line(Vector2(x, 0), Vector2(x + 6.0, -7.0 - (k % 2) * 4.0), wc, 1.0)
				draw_line(Vector2(x + 6.0, -7.0 - (k % 2) * 4.0), Vector2(x + 12.0, 0), wc, 1.0)
			draw_line(Vector2(-24, -1), Vector2(24, -1), wc, 1.2)
			draw_line(Vector2(-18, -5), Vector2(18, -5), Color(wc, wc.a * 0.6), 0.8)
			return
		"rock":
			# rocher qui tourne, arêtes, poussière derrière
			_tail(Color(0.6, 0.55, 0.5), radius * 0.6, 22.0)
			var pts := PackedVector2Array()
			for i in 8:
				var a := i * TAU / 8.0 + t * 3.0
				pts.append(Vector2(cos(a), sin(a)) * radius * (0.8 + 0.25 * sin(i * 2.3)))
			DU.poly(self, pts, c.darkened(0.25))
			draw_line(pts[1] * 0.4, pts[4] * 0.5, c.darkened(0.6), 1.2)
		"wave":
			# onde de choc : vague de poussière et de lumière
			var h := 30.0 + sin(t * 30.0) * 4.0
			var d := signf(vel.x)
			DU.glow(self, Vector2(0, -10), 20.0, c, 0.4)
			draw_polygon(PackedVector2Array([Vector2(-12 * d, 0), Vector2(9 * d, 0), Vector2(3 * d, -h), Vector2(-5 * d, -h * 0.6)]),
				PackedColorArray([Color(c, 0.2), Color(c.lightened(0.5), 0.95), Color(1, 1, 1, 0.9), Color(c, 0.4)]))
			for i in 3:
				draw_circle(Vector2(-d * (6 + i * 7), -2 - i), 4.0 - i, Color(0.8, 0.75, 0.7, 0.4))
		"acid":
			# goutte d'acide qui s'étire, bulles
			_tail(c, radius * 0.8, 18.0)
			DU.glow(self, Vector2.ZERO, radius * 2.4, c, 0.4)
			var dd := vel.normalized() if vel.length() > 1.0 else Vector2.RIGHT
			var drop := PackedVector2Array()
			for i in 14:
				var a := i * TAU / 14.0
				var v := Vector2.from_angle(a)
				var stretch := 1.0 + 0.5 * maxf(0.0, -v.dot(dd))
				drop.append(v * radius * stretch)
			DU.flat(self, drop, c)
			draw_circle(-dd * radius * 0.2, radius * 0.6, c.lightened(0.25))
			draw_circle(Vector2(-2, -2), radius * 0.3, Color(1, 1, 1, 0.75))
			draw_circle(Vector2(sin(t * 9.0) * 2.0, cos(t * 7.0) * 2.0), 1.2, Color(1, 1, 1, 0.5))
		"slashwave":
			# lame d'air de l'aiguille : croissant translucide
			var sd := signf(vel.x)
			var a := clampf(life / 0.32, 0.0, 1.0)
			var a0 := -1.2 if sd > 0 else PI - 1.2
			var a1 := 1.2 if sd > 0 else PI + 1.2
			draw_arc(Vector2(-sd * 8, 0), 16.0, a0, a1, 14, Color(0.6, 0.85, 1.0, 0.4 * a), 9.0)
			draw_arc(Vector2(-sd * 8, 0), 17.0, a0, a1, 14, Color(1, 1, 1, a), 2.5)
			for i in 3:
				draw_line(Vector2(-sd * (14 + i * 6), -6 + i * 6), Vector2(-sd * (24 + i * 6), -6 + i * 6), Color(0.8, 0.9, 1.0, 0.4 * a), 1.2)
		"dart":
			# fléchette : hampe de bois, pointe de fer, empennage de plumes
			var dd := signf(vel.x)
			_tail(Color(1, 1, 1), 1.5, 26.0)
			draw_line(Vector2(-dd * 12, 0), Vector2(dd * 6, 0), Color(0.35, 0.25, 0.18), 2.6)
			draw_line(Vector2(-dd * 12, -0.6), Vector2(dd * 6, -0.6), Color(0.62, 0.48, 0.32), 1.0)
			DU.flat(self, PackedVector2Array([Vector2(dd * 12, 0), Vector2(dd * 4, -3.5), Vector2(dd * 5.5, 0), Vector2(dd * 4, 3.5)]), Color(0.7, 0.72, 0.8))
			DU.flat(self, PackedVector2Array([Vector2(-dd * 8, 0), Vector2(-dd * 14, -4.5), Vector2(-dd * 12, 0), Vector2(-dd * 14, 4.5)]), Color(0.85, 0.3, 0.25))
		"shuriken":
			var cc := Color(1.0, 0.75, 0.35) if crit else Color(0.85, 0.9, 1.0)
			DU.glow(self, Vector2.ZERO, radius * 1.8, cc, 0.35)
			draw_arc(Vector2.ZERO, radius * 0.95, t * 25.0, t * 25.0 + 2.0, 10, Color(cc, 0.35), 2.0)
			for i in 4:
				var a := i * PI / 2.0 + t * 25.0
				DU.flat(self, PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - 0.4) * radius * 0.45, Vector2.from_angle(a) * radius]), cc)
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * radius * 0.9, Color(1, 1, 1, 0.7), 0.8)
			draw_circle(Vector2.ZERO, radius * 0.22, Color(0.2, 0.22, 0.3))
		"soulblade":
			# lame d'âme : croissant lumineux, cœur blanc, filaments
			var d := signf(vel.x)
			DU.glow(self, Vector2.ZERO, radius * 3.0, c, 0.5)
			var a0 := -PI / 2.0 + (0.0 if d > 0 else PI)
			var a1 := PI / 2.0 + (0.0 if d > 0 else PI)
			draw_arc(Vector2(-d * 6, 0), radius * 1.4, a0, a1, 18, Color(c, 0.5), 10.0)
			draw_arc(Vector2(-d * 6, 0), radius * 1.45, a0, a1, 18, Color(1, 1, 1, 0.95), 3.5)
			draw_arc(Vector2(-d * 12, 0), radius * 1.1, a0, a1, 14, Color(c, 0.6), 3.0)
			for i in 4:
				var y := (i - 1.5) * radius * 0.6
				draw_line(Vector2(-d * radius * 1.2, y), Vector2(-d * radius * (2.4 + 0.4 * sin(t * 20.0 + i)), y * 1.2), Color(c.lightened(0.4), 0.45), 1.2)
		"ember":
			# braise : flamme effilée qui ondule
			_tail(Color(1.0, 0.5, 0.2), radius * 0.9, 20.0)
			DU.glow(self, Vector2.ZERO, radius * 2.6, c, 0.5)
			var dd := vel.normalized() if vel.length() > 1.0 else Vector2.RIGHT
			var nn := dd.orthogonal()
			var flick := 1.0 + 0.2 * sin(t * 30.0)
			DU.flat(self, PackedVector2Array([dd * radius * 1.2, nn * radius * 0.9, -dd * radius * 2.4 * flick, -nn * radius * 0.9]), c)
			DU.flat(self, PackedVector2Array([dd * radius * 0.7, nn * radius * 0.45, -dd * radius * 1.3 * flick, -nn * radius * 0.45]), Color(1.0, 0.95, 0.7))
		_:
			# spore / boule d'énergie : halo, cœur, anneau qui tourne
			_tail(c, radius * 0.7, 20.0)
			DU.glow(self, Vector2.ZERO, radius * 2.6, c, 0.45)
			DU.ball(self, Vector2.ZERO, radius + sin(t * 20.0) * 0.8, c)
			draw_arc(Vector2.ZERO, radius * 1.5, t * 6.0, t * 6.0 + 2.2, 10, Color(c.lightened(0.4), 0.6), 1.4)
			draw_circle(Vector2(-2, -2), radius * 0.35, Color(1, 1, 1, 0.8))

extends AnimatableBody2D
const DU = preload("res://scripts/draw_util.gd")
# Plateformes spéciales :
#  mover   (H) : plateforme qui fait l'aller-retour au-dessus d'un gouffre
#  crumble (C) : bloc fragile qui s'effondre peu après qu'on s'y pose, puis se reforme
var main
var kind := "mover"
var size := Vector2(96, 16)
var x_min := 0.0
var x_max := 0.0
var speed := 110.0
var dir := 1.0
var t := 0.0
var state := "solid"     # crumble : solid / shake / gone
var st_t := 0.0
var cs: CollisionShape2D
var hp := 3              # breakable : coups nécessaires

func _ready() -> void:
	add_to_group("sleepy")
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = kind == "mover"
	var sh := RectangleShape2D.new()
	sh.size = size
	cs = CollisionShape2D.new()
	cs.shape = sh
	cs.position = size / 2.0
	if kind == "mover":
		cs.one_way_collision = false
	add_child(cs)
	if kind == "breakable":
		add_to_group("breakables")

func get_rect() -> Rect2:
	return Rect2(global_position, size)

# Sol fissuré : se brise après quelques coups
func hit(_dmg: int) -> void:
	if state == "gone":
		return
	hp -= 1
	st_t = 0.15
	main.spawn_burst(global_position + size / 2.0, _block_cols(_biome_id())[0].lightened(0.15), 8, 140.0)
	Audio.sfx("hit", 0.1, -4.0)
	if hp <= 0:
		state = "gone"
		remove_from_group("breakables")
		cs.set_deferred("disabled", true)
		main.spawn_burst(global_position + size / 2.0, _block_cols(_biome_id())[0].lightened(0.2), 22, 220.0, 400.0)
		main.shake(5)
		Audio.sfx("kill", 0.0, -2.0)

func _player_on() -> bool:
	var p = main.player
	if p == null or p.dead or not p.is_on_floor():
		return false
	var r: Rect2 = p.get_rect()
	return absf(r.end.y - global_position.y) < 4.0 and r.end.x > global_position.x + 2.0 and r.position.x < global_position.x + size.x - 2.0

func _physics_process(delta: float) -> void:
	t += delta
	if kind == "breakable":
		st_t -= delta
	match kind:
		"mover":
			var nx := position.x + dir * speed * delta
			if nx >= x_max:
				nx = x_max
				dir = -1.0
			elif nx <= x_min:
				nx = x_min
				dir = 1.0
			position.x = nx
		"crumble":
			match state:
				"solid":
					if _player_on():
						state = "shake"
						st_t = 0.55
						Audio.sfx("door", 0.2, -12.0)
						# Mines de Cristal : la secousse fait pleuvoir des gravats du plafond
						if String(main.pal.get("id", "")) == "cristal":
							main.debris_rain(global_position.x + size.x / 2.0, global_position.y)
				"shake":
					st_t -= delta
					if st_t <= 0.0:
						state = "gone"
						st_t = 3.0
						cs.set_deferred("disabled", true)
						main.spawn_burst(global_position + size / 2.0, Color(0.55, 0.45, 0.38), 10, 120.0, 400.0)
				"gone":
					st_t -= delta
					if st_t <= 0.0:
						var pr: Rect2 = main.player.get_rect()
						if not pr.intersects(Rect2(global_position, size)):
							state = "solid"
							cs.set_deferred("disabled", false)
	queue_redraw()

func _slab(off: Vector2, c: Color, cut: float) -> void:
	# dalle de pierre : dégradé, arête éclairée, ombre dessous, joints entre blocs
	DU.vgrad(self, Rect2(off, size), c.lightened(0.08), c.darkened(0.45))
	draw_rect(Rect2(off, Vector2(size.x, 3)), c.lightened(0.35))
	draw_rect(Rect2(off + Vector2(0, size.y - 3), Vector2(size.x, 3)), c.darkened(0.6))
	var x := cut
	while x < size.x - 4:
		draw_line(off + Vector2(x, 3), off + Vector2(x, size.y - 3), c.darkened(0.55), 1.5)
		draw_line(off + Vector2(x + 1.5, 3), off + Vector2(x + 1.5, size.y - 3), c.lightened(0.15), 1.0)
		x += cut
	for k in int(size.x / 11.0):
		var h := fposmod(sin(k * 12.9898 + size.x) * 43758.5453, 1.0)
		draw_circle(off + Vector2(5 + k * 11 + h * 4, 7 + h * (size.y - 12)), 1.0 + h, c.darkened(0.3))

func _draw() -> void:
	match kind:
		"mover":
			var c := Color(0.36, 0.3, 0.26)
			_slab(Vector2.ZERO, c, 9999.0)
			for k in [6.0, size.x - 6.0]:
				draw_circle(Vector2(k, size.y * 0.5), 2.4, Color(0.25, 0.22, 0.2))
				draw_circle(Vector2(k - 0.6, size.y * 0.5 - 0.6), 1.0, Color(0.8, 0.75, 0.65))
			for i in 3:
				var rc := Vector2(size.x * (0.25 + i * 0.25), size.y * 0.55)
				var a := 0.55 + 0.35 * sin(t * 4.0 + i)
				draw_colored_polygon(DU.diamond(rc, Vector2(3, 4)), Color(0.7, 0.88, 1.0, a))
				DU.glow(self, rc, 10.0, Color(0.6, 0.85, 1.0), a * 0.5)
		"breakable":
			if state == "gone":
				return
			var off2 := Vector2(sin(t * 80.0) * 2.0, 0) if st_t > 0.0 else Vector2.ZERO
			_breakable_block(off2)
		"crumble":
			_crumble_bridge()

# ---------------------------------------------------------------- ponts qui s'effondrent
# Chaque biome a son pont, fait de pièces : il tremble pièce par pièce, puis les pièces tombent
# en tournoyant (une seconde environ) ; reste un contour fantôme jusqu'à ce qu'il se reforme.
func _biome_id() -> String:
	return String(main.pal.get("id", "")) if main and main.pal else ""

func _bridge_piece_w(bio: String) -> float:
	match bio:
		"ossuaire": return 9.0
		"bibliotheque": return 14.0
		"ruche": return 16.0
		"cristal", "glace": return 24.0
		"jardins": return 20.0
		"jungle", "citadelle": return 12.0
		"forge": return 32.0
		"antique", "desert": return 32.0
	return 16.0

func _hh(i: int, k: int) -> float:
	return fposmod(sin(i * 12.9898 + k * 78.233 + size.x * 0.37) * 43758.5453, 1.0)

func _crumble_bridge() -> void:
	var bio := _biome_id()
	var pw := _bridge_piece_w(bio)
	var n := maxi(1, int(round(size.x / pw)))
	pw = size.x / n
	var fall := -1.0
	if state == "gone":
		fall = 3.0 - st_t
		if fall > 1.4:
			# contour fantôme : le pont se reformera ici
			var k := clampf((fall - 1.4) / 1.6, 0.0, 1.0)
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.75, 0.65, 0.18 * k), false, 1.0)
			return
	# cordes / chaînes du pont (sous les pièces), qui cassent à la chute
	if fall < 0.0:
		_bridge_ropes(bio, false)
	for i in n:
		var r := Rect2(Vector2(i * pw, 0), Vector2(pw, size.y))
		var c := r.get_center()
		var ang := 0.0
		var o := Vector2.ZERO
		if state == "shake":
			o = Vector2(sin(t * 70.0 + i * 1.7) * 1.4, absf(sin(t * 50.0 + i)) * 1.5 * (1.0 - st_t / 0.55))
			ang = sin(t * 40.0 + i * 2.3) * 0.05
		elif fall >= 0.0:
			var delay := _hh(i, 3) * 0.18
			var ft := maxf(fall - delay, 0.0)
			o = Vector2((_hh(i, 5) - 0.5) * 40.0 * ft, 0.5 * 1400.0 * ft * ft)
			ang = (_hh(i, 7) - 0.5) * 7.0 * ft
		draw_set_transform(c + o, ang, Vector2.ONE)
		_bridge_piece(bio, i, Rect2(-r.size / 2.0, r.size))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fall < 0.0:
		_bridge_ropes(bio, true)
		if state == "shake":
			for i in 4:
				var px := fposmod(t * 97.0 + i * 37.0, size.x)
				draw_rect(Rect2(Vector2(px, size.y + fposmod(t * 60.0 + i * 9.0, 14.0)), Vector2(3, 2)), _bits_col(bio))

func _bits_col(bio: String) -> Color:
	match bio:
		"ossuaire": return Color(0.85, 0.8, 0.68)
		"bibliotheque": return Color(0.93, 0.9, 0.8)
		"desert": return Color(0.85, 0.7, 0.45)
		"glace": return Color(0.85, 0.95, 1.0)
		"cristal": return main.pal["moss"]
		"ruche": return Color(1.0, 0.75, 0.25)
		"forge": return Color(1.0, 0.5, 0.15)
	return Color(0.45, 0.38, 0.32)

# cordes de soutien (devant = false : sous les pièces ; true : par-dessus)
func _bridge_ropes(bio: String, front: bool) -> void:
	match bio:
		"jungle":
			if front:
				for yy in [3.0, size.y - 3.0]:
					draw_line(Vector2(0, yy), Vector2(size.x, yy), Color(0.3, 0.45, 0.18), 1.6)
			else:
				# main courante en liane, avec feuilles
				var pts := PackedVector2Array()
				for i in 9:
					var k := i / 8.0
					pts.append(Vector2(k * size.x, -14.0 + sin(k * PI) * 5.0))
				draw_polyline(pts, Color(0.28, 0.42, 0.16), 2.0)
				for i in range(1, 8, 2):
					draw_colored_polygon(PackedVector2Array([pts[i], pts[i] + Vector2(5, 3), pts[i] + Vector2(1, 5)]), Color(0.35, 0.6, 0.22))
				for i in int(size.x / 24.0) + 1:
					var x := minf(i * 24.0 + 4.0, size.x - 2.0)
					draw_line(Vector2(x, -14.0 + sin(x / size.x * PI) * 5.0), Vector2(x, 2), Color(0.28, 0.42, 0.16), 1.2)
		"citadelle":
			if not front:
				var pts := PackedVector2Array()
				for i in 13:
					var k := i / 12.0
					pts.append(Vector2(k * size.x, -12.0 + sin(k * PI) * 6.0))
				for i in pts.size():
					draw_arc(pts[i], 2.2, 0, TAU, 8, Color(0.42, 0.36, 0.32), 1.4)
				draw_line(pts[0], Vector2(0, 4), Color(0.42, 0.36, 0.32), 1.4)
				draw_line(pts[pts.size() - 1], Vector2(size.x, 4), Color(0.42, 0.36, 0.32), 1.4)
		"jardins":
			if not front:
				# filaments de mycélium qui relient les chapeaux
				var pts := PackedVector2Array()
				for i in 9:
					var k := i / 8.0
					pts.append(Vector2(k * size.x, size.y * 0.6 + sin(k * PI) * 3.0))
				draw_polyline(pts, Color(0.92, 0.9, 0.8, 0.8), 1.4)
				for i in range(1, 8, 2):
					draw_line(pts[i], pts[i] + Vector2(2, 7), Color(0.92, 0.9, 0.8, 0.6), 1.0)
		"ossuaire":
			if front:
				for yy in [4.0, size.y - 4.0]:
					draw_line(Vector2(0, yy), Vector2(size.x, yy), Color(0.45, 0.32, 0.25, 0.9), 1.4)
		"profondeurs", "hub", "":
			if front:
				draw_line(Vector2(0, 5), Vector2(size.x, 5), Color(0.55, 0.45, 0.3, 0.7), 1.2)

func _bridge_piece(bio: String, i: int, r: Rect2) -> void:
	var h1 := _hh(i, 1)
	var h2 := _hh(i, 2)
	match bio:
		"ossuaire":
			# fémur dressé : deux nœuds à chaque bout
			var bone := Color(0.86, 0.81, 0.68).darkened(h1 * 0.15)
			var a := Vector2(0, r.position.y + 2)
			var b := Vector2((h2 - 0.5) * 2.0, r.end.y - 2)
			draw_line(a, b, bone.darkened(0.35), 5.0)
			draw_line(a, b, bone, 3.4)
			for q in [a, b]:
				draw_circle(q + Vector2(-1.6, 0), 2.5, bone)
				draw_circle(q + Vector2(1.6, 0), 2.5, bone)
			if i % 6 == 3:
				var sc := Vector2(0, r.position.y - 4)
				draw_circle(sc, 5.0, bone)
				draw_circle(sc + Vector2(-2, 0), 1.3, Color(0.15, 0.12, 0.1))
				draw_circle(sc + Vector2(2, 0), 1.3, Color(0.15, 0.12, 0.1))
		"bibliotheque":
			var cols := [Color(0.55, 0.2, 0.18), Color(0.2, 0.32, 0.5), Color(0.3, 0.42, 0.25), Color(0.5, 0.38, 0.18), Color(0.38, 0.22, 0.42)]
			var c: Color = cols[int(h1 * 5.0) % 5]
			var lift := h2 * 3.0
			var br := Rect2(r.position + Vector2(0.5, lift), Vector2(r.size.x - 1.0, r.size.y - lift))
			DU.vgrad(self, br, c.lightened(0.12), c.darkened(0.35))
			draw_rect(Rect2(br.position + Vector2(1, 1), Vector2(br.size.x - 2, 3)), Color(0.93, 0.88, 0.74))
			for yy in [0.45, 0.7]:
				draw_line(br.position + Vector2(0, br.size.y * yy), br.position + Vector2(br.size.x, br.size.y * yy), Color(0.9, 0.75, 0.35, 0.8), 1.0)
			if i % 5 == 2:
				# un livre ouvert posé dessus
				var top := Vector2(0, br.position.y - 1)
				draw_colored_polygon(PackedVector2Array([top, top + Vector2(-8, -3), top + Vector2(-8, -1), top + Vector2(0, 1)]), Color(0.95, 0.92, 0.82))
				draw_colored_polygon(PackedVector2Array([top, top + Vector2(8, -3), top + Vector2(8, -1), top + Vector2(0, 1)]), Color(0.9, 0.86, 0.75))
		"jungle", "citadelle":
			# planche de bois, nœuds et clous
			var wood := Color(0.45, 0.3, 0.18) if bio == "jungle" else Color(0.36, 0.28, 0.22)
			wood = wood.lerp(wood.lightened(0.2), h1)
			var pr := Rect2(r.position + Vector2(1, h2 * 2.0), Vector2(r.size.x - 2, r.size.y - 3))
			DU.vgrad(self, pr, wood.lightened(0.1), wood.darkened(0.4))
			draw_line(pr.position + Vector2(1, 2), pr.position + Vector2(1, pr.size.y - 2), wood.lightened(0.3), 1.0)
			draw_circle(pr.position + Vector2(pr.size.x / 2.0, 4), 1.1, Color(0.2, 0.18, 0.16))
			if h1 > 0.6:
				draw_arc(pr.get_center() + Vector2(0, 2), 2.0, 0, TAU, 8, wood.darkened(0.5), 1.0)
		"cristal", "glace":
			# dalle de cristal / bloc de glace translucide
			var cc: Color = main.pal["moss"] if bio == "cristal" else Color(0.75, 0.9, 1.0)
			var pts := PackedVector2Array([r.position + Vector2(1, 1 + h1 * 2), Vector2(r.end.x - 1, r.position.y + 1 + h2 * 2), Vector2(r.end.x - 2, r.end.y - 1), Vector2(r.position.x + 2, r.end.y - 2)])
			draw_colored_polygon(pts, Color(cc.darkened(0.35), 0.92))
			draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[1] + Vector2(-3, 4), pts[0] + Vector2(3, 4)]), Color(cc.lightened(0.35), 0.9))
			draw_line(pts[0] + Vector2(4, 6), pts[0] + Vector2(9, r.size.y - 5), Color(1, 1, 1, 0.45), 1.2)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(cc.lightened(0.5), 0.8), 1.0)
			if bio == "glace" and h1 > 0.5:
				draw_colored_polygon(PackedVector2Array([Vector2(-2, r.end.y - 1), Vector2(2, r.end.y - 1), Vector2(0, r.end.y + 6 + h2 * 5)]), Color(0.8, 0.92, 1.0))
		"forge":
			# plaque de fer rivetée, fentes rougeoyantes
			var iron := Color(0.26, 0.22, 0.22)
			DU.vgrad(self, r.grow(-0.5), iron.lightened(0.15), iron.darkened(0.4))
			for k in 3:
				var yy := r.position.y + 4 + k * 4
				draw_line(Vector2(r.position.x + 5, yy), Vector2(r.end.x - 5, yy), Color(1.0, 0.45 + 0.1 * sin(t * 3.0 + i), 0.12, 0.8), 1.4)
			for q in [r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3)]:
				draw_circle(q, 1.4, iron.lightened(0.4))
		"ruche":
			# alvéole de cire, miel qui perle
			var wax := Color(0.95, 0.72, 0.28).lerp(Color(0.85, 0.6, 0.2), h1)
			var cpos := Vector2(0, 0)
			var hex := PackedVector2Array()
			for k in 6:
				hex.append(cpos + Vector2.from_angle(k * TAU / 6.0 + PI / 6.0) * r.size.x * 0.55)
			draw_colored_polygon(hex, wax)
			var inner := PackedVector2Array()
			for k in 6:
				inner.append(cpos + Vector2.from_angle(k * TAU / 6.0 + PI / 6.0) * r.size.x * 0.33)
			draw_colored_polygon(inner, Color(1.0, 0.82, 0.3).darkened(0.2))
			if h2 > 0.6:
				var dl := 3.0 + fposmod(t * 2.0 + h1 * 5.0, 1.0) * 5.0
				draw_line(Vector2(0, r.end.y - 1), Vector2(0, r.end.y + dl), Color(1.0, 0.7, 0.15), 2.0)
		"desert":
			# brique de grès, sable qui s'écoule des joints
			var sand := Color(0.72, 0.56, 0.36).lerp(Color(0.8, 0.64, 0.42), h1)
			DU.vgrad(self, r.grow(-0.5), sand.lightened(0.1), sand.darkened(0.3))
			draw_line(Vector2(r.position.x + 3, r.position.y + r.size.y * 0.5), Vector2(r.end.x - 3, r.position.y + r.size.y * 0.5), sand.darkened(0.25), 1.0)
			if state == "shake" or h2 > 0.7:
				var fl := 4.0 + fposmod(t * 3.0 + h1, 1.0) * 6.0
				draw_line(Vector2(r.end.x - 1, r.end.y), Vector2(r.end.x - 1, r.end.y + fl), Color(0.85, 0.7, 0.45, 0.8), 1.5)
		"antique":
			# dalle de marbre veinée, frise grecque
			var marble := Color(0.78, 0.76, 0.72).lerp(Color(0.86, 0.84, 0.8), h1)
			DU.vgrad(self, r.grow(-0.5), marble, marble.darkened(0.3))
			draw_line(Vector2(r.position.x + 2, r.position.y + 3), Vector2(r.end.x - 2, r.position.y + 3), marble.lightened(0.2), 1.0)
			var y0 := r.position.y + r.size.y * 0.6
			for k in int(r.size.x / 8.0):
				var x0 := r.position.x + 2 + k * 8
				draw_polyline(PackedVector2Array([Vector2(x0, y0 + 3), Vector2(x0, y0 - 2), Vector2(x0 + 5, y0 - 2), Vector2(x0 + 5, y0 + 1), Vector2(x0 + 2, y0 + 1)]), marble.darkened(0.35), 1.0)
			draw_line(Vector2(r.position.x + 4 + h2 * 10, r.position.y + 5), Vector2(r.position.x + 10 + h2 * 10, r.end.y - 3), Color(0.55, 0.55, 0.6, 0.5), 0.8)
		"jardins":
			# chapeau de champignon (vu de côté) : dôme tacheté, lamelles dessous, pied qui pend
			var caps := [Color(0.78, 0.3, 0.24), Color(0.85, 0.55, 0.25), Color(0.62, 0.35, 0.55), Color(0.82, 0.42, 0.28)]
			var cap: Color = caps[int(h1 * 4.0) % 4]
			var cw := r.size.x * 0.68 + 3.0
			var top := r.position.y - 2.0 - h2 * 3.0
			var base_y := r.position.y + r.size.y * 0.55
			# pied (court, un peu de biais)
			draw_line(Vector2(0, base_y), Vector2((h2 - 0.5) * 3.0, r.end.y + 3.0), Color(0.86, 0.82, 0.72), 3.0)
			# lamelles
			var gill := PackedVector2Array([Vector2(-cw, base_y), Vector2(cw, base_y), Vector2(cw * 0.7, base_y + 4.0), Vector2(-cw * 0.7, base_y + 4.0)])
			draw_colored_polygon(gill, Color(0.9, 0.82, 0.68))
			for k in 5:
				var gx := -cw * 0.6 + k * cw * 0.3
				draw_line(Vector2(gx, base_y), Vector2(gx * 0.85, base_y + 4.0), Color(0.7, 0.6, 0.48), 0.8)
			# dôme
			var dome := DU.ellipse(Vector2(0, base_y), Vector2(cw, base_y - top), 16, PI, TAU)
			dome.append(Vector2(cw, base_y))
			draw_colored_polygon(dome, cap)
			var hl := PackedVector2Array()
			for k in 6:
				var a := PI * (1.12 + k * 0.06)
				hl.append(Vector2(cos(a) * (cw - 3.0), base_y + sin(a) * (base_y - top - 2.5)))
			draw_polyline(hl, cap.lightened(0.35), 1.6)
			for k in 3:
				var sp := Vector2((_hh(i, 10 + k) - 0.5) * cw * 1.2, base_y - (base_y - top) * (0.35 + _hh(i, 20 + k) * 0.4))
				draw_circle(sp, 1.2 + _hh(i, 30 + k) * 1.2, Color(1.0, 0.95, 0.85))
			if state == "shake" and h1 > 0.4:
				var k2 := fposmod(t * 1.5 + h2, 1.0)
				draw_circle(Vector2((h2 - 0.5) * cw, top - k2 * 10.0), 1.3, Color(0.75, 1.0, 0.55, 1.0 - k2))
		_:
			# Profondeurs, Sanctuaire : lame d'ardoise moussue, petite lueur bleue
			var c := Color(0.42, 0.4, 0.44) if bio != "hub" else Color(0.5, 0.42, 0.36)
			DU.vgrad(self, r.grow(-0.5), c.lightened(0.08), c.darkened(0.45))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), c.lightened(0.3))
			if bio == "profondeurs":
				draw_rect(Rect2(r.position + Vector2(0, -1), Vector2(r.size.x * (0.4 + h1 * 0.5), 2)), Color(0.42, 0.62, 0.7))
				if h2 > 0.7:
					draw_circle(r.position + Vector2(r.size.x * h1, 6), 1.6, Color(0.6, 0.9, 1.0, 0.8 + 0.2 * sin(t * 3.0 + i)))
			draw_line(r.position + Vector2(r.size.x * 0.4, 3), r.position + Vector2(r.size.x * 0.55, r.size.y - 3), c.darkened(0.6), 1.0)

# ---------------------------------------------------------------- dalles fissurées (à casser)
# Même idée que les ponts : la matière du biome, et des fissures qui luisent (plus nombreuses à
# chaque coup reçu) pour montrer qu'on peut la briser.
func _block_cols(bio: String) -> Array:
	# [matière, couleur des fissures]
	match bio:
		"profondeurs": return [Color(0.32, 0.34, 0.42), Color(0.55, 0.85, 1.0)]
		"jardins": return [Color(0.4, 0.3, 0.2), Color(0.6, 1.0, 0.5)]
		"citadelle": return [Color(0.38, 0.34, 0.42), Color(1.0, 0.78, 0.45)]
		"cristal": return [Color(0.2, 0.34, 0.4), main.pal["moss"]]
		"forge": return [Color(0.2, 0.15, 0.14), Color(1.0, 0.5, 0.12)]
		"bibliotheque": return [Color(0.42, 0.28, 0.16), Color(1.0, 0.82, 0.45)]
		"glace": return [Color(0.62, 0.78, 0.9), Color(1.0, 1.0, 1.0)]
		"ruche": return [Color(0.82, 0.58, 0.2), Color(1.0, 0.9, 0.5)]
		"ossuaire": return [Color(0.48, 0.45, 0.4), Color(0.95, 0.9, 0.75)]
		"jungle": return [Color(0.36, 0.26, 0.16), Color(0.7, 1.0, 0.45)]
		"desert": return [Color(0.7, 0.54, 0.34), Color(1.0, 0.9, 0.6)]
		"antique": return [Color(0.74, 0.72, 0.68), Color(1.0, 0.85, 0.45)]
	return [Color(0.42, 0.38, 0.36), Color(1.0, 0.85, 0.5)]

func _breakable_block(o: Vector2) -> void:
	var bio := _biome_id()
	var cs2: Array = _block_cols(bio)
	var c: Color = cs2[0]
	var glow: Color = cs2[1]
	var r := Rect2(o, size)
	DU.vgrad(self, r, c.lightened(0.12), c.darkened(0.4))
	draw_rect(Rect2(o, Vector2(size.x, 3)), c.lightened(0.3))
	draw_rect(Rect2(o + Vector2(0, size.y - 3), Vector2(size.x, 3)), c.darkened(0.55))
	var hx := fposmod(sin(position.x * 0.13 + position.y * 0.07) * 43758.5453, 1.0)
	match bio:
		"profondeurs":
			draw_rect(Rect2(o + Vector2(0, -1), Vector2(size.x * (0.5 + hx * 0.4), 3)), Color(0.42, 0.62, 0.7))
			draw_line(o + Vector2(0, size.y * 0.55), o + Vector2(size.x, size.y * 0.5), c.darkened(0.4), 1.0)
		"jardins":
			# terre tenue par des racines, petit champignon
			for k in 3:
				var y := 6.0 + k * 8.0
				draw_line(o + Vector2(0, y), o + Vector2(size.x, y + sin(k + hx * 6.0) * 3.0), Color(0.55, 0.42, 0.25), 1.6)
			draw_line(o + Vector2(size.x * 0.7, 0), o + Vector2(size.x * 0.7, -6), Color(0.85, 0.8, 0.7), 2.0)
			draw_colored_polygon(DU.ellipse(o + Vector2(size.x * 0.7, -6), Vector2(5, 3), 8, PI, TAU), Color(0.75, 0.3, 0.25))
		"citadelle":
			for k in 2:
				var y := o.y + k * size.y / 2.0
				draw_line(Vector2(o.x, y), Vector2(o.x + size.x, y), c.darkened(0.5), 1.2)
				var jx := o.x + (size.x / 2.0 if k == 0 else size.x / 4.0)
				draw_line(Vector2(jx, y), Vector2(jx, y + size.y / 2.0), c.darkened(0.5), 1.2)
		"cristal":
			for k in 3:
				var bx := o.x + 5 + k * (size.x - 10) / 2.0
				var hh := 6.0 + fposmod(hx * 7.0 + k, 1.0) * 6.0
				draw_colored_polygon(PackedVector2Array([Vector2(bx - 3, o.y + 2), Vector2(bx + 3, o.y + 2), Vector2(bx + 1, o.y - hh)]), glow)
		"forge":
			# basalte refroidi : plaques sombres et bord rougeoyant
			draw_rect(Rect2(o + Vector2(0, size.y - 4), Vector2(size.x, 2)), Color(1.0, 0.45, 0.12, 0.5 + 0.2 * sin(t * 3.0)))
		"bibliotheque":
			# panneau de bois sculpté, rivets de laiton
			draw_rect(Rect2(o + Vector2(4, 4), size - Vector2(8, 8)), c.darkened(0.25), false, 1.5)
			for q in [Vector2(3, 3), Vector2(size.x - 3, 3), Vector2(3, size.y - 3), Vector2(size.x - 3, size.y - 3)]:
				draw_circle(o + q, 1.6, Color(0.9, 0.72, 0.35))
		"glace":
			draw_line(o + Vector2(4, 4), o + Vector2(10, size.y - 6), Color(1, 1, 1, 0.5), 1.4)
			draw_colored_polygon(PackedVector2Array([o + Vector2(size.x * 0.6, size.y), o + Vector2(size.x * 0.6 + 6, size.y), o + Vector2(size.x * 0.6 + 3, size.y + 7)]), Color(0.8, 0.92, 1.0))
		"ruche":
			for k in 4:
				var cc := o + Vector2(8 + (k % 2) * 16, 8 + (k / 2) * 16)
				var hex := PackedVector2Array()
				for j in 6:
					hex.append(cc + Vector2.from_angle(j * TAU / 6.0 + PI / 6.0) * 6.5)
				draw_polyline(hex + PackedVector2Array([hex[0]]), c.darkened(0.3), 1.2)
		"ossuaire":
			# bloc de terre et d'os tassés, un crâne
			for k in 3:
				var a := fposmod(hx * 5.0 + k * 1.7, PI)
				var p := o + Vector2(6 + k * 9, 8 + k * 7)
				draw_line(p - Vector2.from_angle(a) * 5.0, p + Vector2.from_angle(a) * 5.0, Color(0.86, 0.81, 0.68), 2.4)
			draw_circle(o + Vector2(size.x * 0.68, size.y * 0.62), 5.0, Color(0.86, 0.81, 0.68))
			draw_circle(o + Vector2(size.x * 0.68 - 2, size.y * 0.6), 1.2, Color(0.15, 0.12, 0.1))
			draw_circle(o + Vector2(size.x * 0.68 + 2, size.y * 0.6), 1.2, Color(0.15, 0.12, 0.1))
		"jungle":
			# tronçon de bois moussu : cernes, mousse sur le dessus
			draw_arc(o + size / 2.0, 6.0, 0, TAU, 12, c.darkened(0.3), 1.2)
			draw_arc(o + size / 2.0, 11.0, 0, TAU, 14, c.darkened(0.3), 1.2)
			draw_rect(Rect2(o + Vector2(0, -2), Vector2(size.x, 4)), Color(0.35, 0.6, 0.22))
		"desert":
			draw_line(o + Vector2(2, size.y * 0.5), o + Vector2(size.x - 2, size.y * 0.5), c.darkened(0.25), 1.0)
			var fl := 3.0 + fposmod(t * 2.0 + hx, 1.0) * 6.0
			draw_line(o + Vector2(size.x * 0.4, size.y), o + Vector2(size.x * 0.4, size.y + fl), Color(0.85, 0.7, 0.45, 0.8), 1.5)
		"antique":
			var y0 := o.y + size.y * 0.62
			for k in int(size.x / 8.0):
				var x0 := o.x + 2 + k * 8
				draw_polyline(PackedVector2Array([Vector2(x0, y0 + 3), Vector2(x0, y0 - 2), Vector2(x0 + 5, y0 - 2), Vector2(x0 + 5, y0 + 1), Vector2(x0 + 2, y0 + 1)]), c.darkened(0.35), 1.0)
	# fissures lumineuses : une branche de plus à chaque coup encaissé
	var pulse := 0.55 + 0.25 * sin(t * 3.0)
	var crk := Color(glow, pulse)
	DU.glow(self, o + Vector2(14, 16), 18.0, glow, 0.3 + 0.15 * sin(t * 3.0))
	draw_line(o + Vector2(6, 2), o + Vector2(14, 16), crk, 2.0)
	draw_line(o + Vector2(14, 16), o + Vector2(10, 30), crk, 2.0)
	draw_line(o + Vector2(14, 16), o + Vector2(26, 22), crk, 2.0)
	if hp <= 2:
		draw_line(o + Vector2(26, 22), o + Vector2(30, 6), crk, 1.6)
		draw_line(o + Vector2(10, 30), o + Vector2(2, 24), crk, 1.6)
	if hp <= 1:
		draw_line(o + Vector2(14, 16), o + Vector2(22, 3), crk, 1.6)
		draw_line(o + Vector2(26, 22), o + Vector2(31, 30), crk, 1.6)

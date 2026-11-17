extends "res://scripts/enemy.gd"
# Singe chapardeur : bondit de plateforme en plateforme, te lance des fruits durs et, s'il te
# touche, te vole des éclats puis s'enfuit en ricanant. Rattrape-le et frappe-le pour les
# récupérer : sinon, il disparaît avec au bout de quelques secondes.
# Élite : vole davantage et lance deux fruits.

var dir := -1.0
var hop_cd := 0.6
var throw_cd := 1.5
var windup_t := 0.0
var loot := 0            # éclats volés
var flee_t := 0.0
var steal_cd := 0.0
const FLEE_TIME := 7.0

func _ready() -> void:
	size = Vector2(24, 24)
	hp = 3
	geo_value = 4
	setup_body()
	floor_snap_length = 6.0
	anim_t = randf() * 4.0

# il vole au lieu de frapper : son contact ne blesse pas
func is_harmful() -> bool:
	return false

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	hop_cd -= delta
	throw_cd -= delta
	steal_cd -= delta
	velocity.y = minf(velocity.y + 1700.0 * delta, 900.0)
	var p = main.player
	var alive_p: bool = p != null and not p.dead
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1600.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	elif windup_t > 0.0:
		windup_t -= delta
		velocity.x = 0.0
		if windup_t <= 0.0 and alive_p:
			_throw(p)
	elif loot > 0:
		# fuite : à l'opposé du héros, en bondissant
		flee_t -= delta
		if alive_p:
			dir = signf(global_position.x - p.global_position.x) if global_position.x != p.global_position.x else dir
		if is_on_floor():
			velocity.x = dir * 150.0 * spd()
			if hop_cd <= 0.0 or is_on_wall() or _edge():
				velocity = Vector2(dir * 300.0 * spd(), -560.0)
				hop_cd = 0.5
		if flee_t <= 0.0:
			_escape()
			return
	elif alive_p:
		var d: Vector2 = p.global_position - global_position
		if absf(d.x) < 460.0 * aggro() and absf(d.y) < 220.0:
			dir = signf(d.x) if d.x != 0.0 else dir
			if is_on_floor():
				if throw_cd <= 0.0 and absf(d.x) > 140.0 and not main.wall_between(global_position, p.global_position):
					windup_t = 0.4
					throw_cd = (2.4 if not elite else 1.9) / aggro()
					velocity.x = 0.0
				elif hop_cd <= 0.0:
					# bond vers le héros (un peu au-dessus : il cherche à lui tomber dessus)
					velocity = Vector2(clampf(d.x * 1.6, -320.0, 320.0) * spd(), -520.0 + clampf(d.y, -200.0, 0.0))
					hop_cd = randf_range(0.7, 1.1) / aggro()
				else:
					velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		elif is_on_floor():
			velocity.x = 0.0
		# vol à la tire
		if steal_cd <= 0.0 and p.invuln_t <= 0.0 and p.dash_t <= 0.0 and get_rect().grow(4.0).intersects(p.get_rect()):
			_steal(p)
	move_and_slide()
	queue_redraw()

func _edge() -> bool:
	return is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 18.0, size.y / 2.0 + 8.0))

func _throw(p) -> void:
	var from := global_position + Vector2(dir * 8.0, -12.0)
	var to: Vector2 = p.global_position + Vector2(0, -8)
	var dx := to.x - from.x
	var tt := clampf(absf(dx) / 320.0, 0.45, 1.1)
	var g := 900.0
	var v := Vector2(dx / tt, (to.y - from.y - 0.5 * g * tt * tt) / tt)
	main.spawn_projectile(from, v, {"kind": "fruit", "radius": 7.0, "gravity": g, "life": 3.0})
	if elite:
		main.spawn_projectile(from, v * Vector2(0.75, 1.05), {"kind": "fruit", "radius": 7.0, "gravity": g, "life": 3.0})
	Audio.sfx("whip", 0.2, -8.0)

func _steal(p) -> void:
	var amount: int = mini(int(p.geo), (8 + 4 * GameState.palier) * (2 if elite else 1))
	steal_cd = 1.0
	if amount <= 0:
		return
	p.geo -= amount
	loot += amount
	flee_t = FLEE_TIME
	hop_cd = 0.0
	main.spawn_burst(p.global_position, Color(0.75, 0.85, 1.0), 10, 160.0)
	main.show_message(tr("Un singe t'a volé %d éclats ! Rattrape-le !") % amount, 2.5)
	Audio.sfx("pickup", 0.3, -4.0)

# trop tard : il file avec le butin
func _escape() -> void:
	main.spawn_burst(global_position, Color(0.6, 0.45, 0.3), 16, 200.0)
	main.show_message(tr("Le singe s'est enfui avec %d éclats…") % loot, 2.5)
	dead = true
	remove_from_group("enemies")
	queue_free()

func die() -> void:
	if loot > 0 and main.player:
		main.player.geo += loot
		main.show_message(tr("Éclats récupérés : +%d") % loot, 2.0)
		main.spawn_fx("shards", global_position, Color(0.75, 0.85, 1.0), Vector2(clampi(loot / 4 + 1, 1, 8), 0))
		loot = 0
	super.die()

func telegraph() -> int:
	return 1 if windup_t > 0.0 and stun_t <= 0.0 else 0

func fx_color() -> Color:
	return Color(0.55, 0.38, 0.25)

func _draw() -> void:
	var f := dir
	var fur := body_color(Color(0.5, 0.33, 0.2))
	var face := body_color(Color(0.92, 0.8, 0.62))
	var air := not is_on_floor() if not display else false
	var run := absf(velocity.x) > 10.0 and not air
	var sw := sin(anim_t * 16.0) * 3.0 if run else 0.0
	# queue enroulée
	var tail := PackedVector2Array()
	for i in 10:
		var u := i / 9.0
		tail.append(Vector2(-f * (8.0 + u * 10.0), 4.0 - u * 16.0 + sin(anim_t * 3.0 + u * 3.0) * 2.0))
	tail.append(tail[9] + Vector2(f * 4.0, -3.0))
	draw_polyline(tail, fur.darkened(0.2), 3.0)
	# pattes
	draw_line(Vector2(-4, 6), Vector2(-5 + sw, 12), fur.darkened(0.3), 3.0)
	draw_line(Vector2(4, 6), Vector2(5 - sw, 12), fur.darkened(0.3), 3.0)
	# corps et ventre
	DU.poly(self, DU.ellipse(Vector2(0, 1), Vector2(10, 9)), fur)
	DU.poly(self, DU.ellipse(Vector2(f * 2.0, 3), Vector2(5, 6)), face.darkened(0.1))
	# bras : levé pour lancer, ou qui serre le sac
	var arm_end := Vector2(f * 6.0, -14.0) if windup_t > 0.0 else Vector2(f * 11.0, 4.0 + (sin(anim_t * 10.0) * 2.0 if run else 0.0))
	draw_line(Vector2(f * 6.0, -1), arm_end, fur.darkened(0.15), 3.0)
	if windup_t > 0.0:
		DU.ball(self, arm_end + Vector2(0, -3), 5.0, Color(0.95, 0.55, 0.2))
	# sac d'éclats volés
	if loot > 0:
		var sk := Vector2(-f * 9.0, -6.0)
		DU.ball(self, sk, 7.0, Color(0.72, 0.62, 0.42))
		draw_line(sk + Vector2(0, -6), Vector2(f * 2.0, -4), Color(0.4, 0.3, 0.2), 1.4)
		for i in 3:
			DU.flat(self, DU.diamond(sk + Vector2(-3 + i * 3, -7 - (i % 2) * 2), Vector2(1.6, 2.4)), Color(0.75, 0.88, 1.0))
	# tête : oreilles rondes, masque clair, yeux malins
	var hd := Vector2(f * 4.0, -10.0)
	for s in [-1.0, 1.0]:
		DU.ball(self, hd + Vector2(s * 8.0, -2.0), 3.6, fur.darkened(0.1))
		draw_circle(hd + Vector2(s * 8.0, -2.0), 1.8, face.darkened(0.2))
	DU.ball(self, hd, 8.0, fur)
	DU.poly(self, DU.ellipse(hd + Vector2(f * 1.5, 1.5), Vector2(6, 5)), face)
	var eye := Color(0.1, 0.07, 0.05)
	for s in [-1.0, 1.0]:
		draw_circle(hd + Vector2(f * 1.5 + s * 2.6, -0.5), 1.4, eye)
	# sourire narquois (grand quand il fuit avec le butin)
	var mw := 3.5 if loot > 0 else 2.2
	draw_arc(hd + Vector2(f * 2.0, 2.5), mw, 0.2, PI - 0.2, 6, Color(0.35, 0.18, 0.12), 1.2)
	draw_stun(-26.0)

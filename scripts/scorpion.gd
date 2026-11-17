extends "res://scripts/enemy.gd"
# Scorpion des sables : avance pinces en avant. À portée, il recule le dard au-dessus de sa tête
# (annoncé) puis frappe en avant et en hauteur : sa piqûre empoisonne (1 dégât de plus deux
# secondes plus tard, sauf si tu te soignes ou te reposes ; il ne tue jamais). Ses pinces bloquent les coups bas :
# frappe-le de face à hauteur normale, de dessus ou dans le dos.
# Élite : crache aussi une giclée de venin à distance.

var dir := -1.0
var state := "walk"     # walk / windup_sting / sting / recover / windup_spit
var state_t := 0.0
var cd := 1.0
var spit_cd := 2.5

func _ready() -> void:
	size = Vector2(36, 20)
	hp = 5
	geo_value = 5
	setup_body()
	floor_snap_length = 6.0
	anim_t = randf() * 3.0

# pendant la piqûre, le dard prolonge la zone dangereuse (en avant et en hauteur)
func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if state == "sting":
		r = r.merge(Rect2(global_position + Vector2(dir * 14.0 - (44.0 if dir < 0 else 0.0), -30), Vector2(44, 24)))
	return r

func take_hit(dmg: int, d: Vector2) -> void:
	# les pinces parent les coups bas venant de face
	if main.player and main.player.attack_kind == "low" and signf(d.x) == -dir and stun_t <= 0.0 and dmg < 5:
		flash_t = 0.1
		main.spawn_burst(global_position + Vector2(dir * 18.0, 4.0), Color(1.0, 0.9, 0.6), 6, 160.0)
		Audio.sfx("parry", 0.15, -8.0)
		return
	super.take_hit(dmg, d)

func _go(s: String, t: float) -> void:
	state = s
	state_t = t

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	cd -= delta
	spit_cd -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	var alive_p: bool = p != null and not p.dead
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
		_go("walk", 0.0)
	elif stun_t > 0.0:
		velocity.x = 0.0
		_go("walk", 0.0)
	else:
		match state:
			"walk":
				velocity.x = 0.0
				if alive_p:
					var d: Vector2 = p.global_position - global_position
					if absf(d.x) < 400.0 * aggro() and absf(d.y) < 100.0:
						dir = signf(d.x) if d.x != 0.0 else dir
						if absf(d.x) < 66.0 and cd <= 0.0:
							_go("windup_sting", (0.5 if not elite else 0.4) / sqrt(aggro()))
						elif elite and absf(d.x) > 160.0 and spit_cd <= 0.0 and not main.wall_between(global_position, p.global_position):
							_go("windup_spit", 0.4)
						elif absf(d.x) > 40.0 and is_on_floor() and main.is_solid_at(global_position + Vector2(dir * 22.0, size.y / 2.0 + 8.0)):
							velocity.x = dir * 85.0 * spd()
			"windup_sting":
				velocity.x = -dir * 10.0
				if state_t <= 0.0:
					_go("sting", 0.22)
					Audio.sfx("slash", 0.1, -3.0)
			"sting":
				velocity.x = dir * 60.0
				if alive_p and p.dash_t <= 0.0 and p.invuln_t <= 0.0 and get_rect().intersects(p.get_rect()):
					if not p.receive_hit(global_position, self):
						_poison(p)
				if state_t <= 0.0:
					_go("recover", 0.7)
			"recover":
				velocity.x = 0.0
				if state_t <= 0.0:
					cd = 1.2 / aggro()
					_go("walk", 0.0)
			"windup_spit":
				velocity.x = 0.0
				if state_t <= 0.0 and alive_p:
					var from := global_position + Vector2(dir * 10.0, -26.0)
					var to: Vector2 = p.global_position + Vector2(0, -8)
					var tt := clampf(absf(to.x - from.x) / 300.0, 0.4, 1.0)
					main.spawn_projectile(from, Vector2((to.x - from.x) / tt, (to.y - from.y - 0.5 * 900.0 * tt * tt) / tt), {"kind": "acid", "radius": 6.0, "gravity": 900.0, "life": 3.0})
					Audio.sfx("spit", 0.15, -4.0)
					spit_cd = 3.0 / aggro()
					_go("recover", 0.4)
	move_and_slide()
	queue_redraw()

# venin : 1 dégât deux secondes plus tard (annulé si le héros se soigne ou s'assoit)
func _poison(p) -> void:
	if p.has_meta("poisoned"):
		return
	p.set_meta("poisoned", true)
	var hp0: int = p.hp
	await get_tree().create_timer(2.0, false).timeout
	if not is_instance_valid(p):
		return
	p.remove_meta("poisoned")
	if p.dead or p.sitting or p.hp > hp0:
		return
	# le venin affaiblit mais ne tue jamais : il laisse au moins un masque
	if p.hp > 1:
		p.hp -= 1
		main.spawn_burst(p.global_position, Color(0.6, 1.0, 0.35), 8, 120.0)
		Audio.sfx("hurt", 0.1, -6.0)

func telegraph() -> int:
	if stun_t > 0.0:
		return 0
	return 1 if state in ["windup_sting", "windup_spit"] else 0

func fx_color() -> Color:
	return Color(0.75, 0.55, 0.3)

func _draw() -> void:
	var f := dir
	var shell := body_color(Color(0.62, 0.42, 0.22))
	var dark := body_color(Color(0.32, 0.2, 0.12))
	var walk := sin(anim_t * 14.0) * 2.0 if absf(velocity.x) > 5.0 else 0.0
	var gy := size.y * 0.5
	# pattes (4 de chaque côté)
	for i in 4:
		var lx := -10.0 + i * 6.0
		var sw := walk if i % 2 == 0 else -walk
		leg(Vector2(lx, 2), Vector2(lx - f * 3 + sw, 6), Vector2(lx - f * 6 + sw, gy), dark, 1.6)
	# abdomen segmenté
	for i in 4:
		var cx := -f * (6.0 + i * 4.0)
		DU.poly(self, DU.ellipse(Vector2(cx, 1.0 - i * 0.6), Vector2(6.5 - i * 0.4, 6.0 - i * 0.6)), shell.darkened(0.06 * i))
		draw_arc(Vector2(cx, 1.0 - i * 0.6), 6.0 - i * 0.6, PI + 0.4, TAU - 0.4, 8, shell.lightened(0.2), 1.0)
	# queue : dressée au-dessus du dos et recourbée vers l'avant ; armée (plus haute, tremblante)
	# pendant la préparation, détendue vers l'avant pendant la piqûre
	var rest := [Vector2(-18, -2), Vector2(-25, -11), Vector2(-25, -22), Vector2(-18, -30), Vector2(-8, -31), Vector2(-1, -25)]
	var armed := [Vector2(-18, -3), Vector2(-28, -15), Vector2(-29, -29), Vector2(-21, -39), Vector2(-10, -41), Vector2(-3, -35)]
	var strike := [Vector2(-16, -6), Vector2(-8, -18), Vector2(4, -24), Vector2(16, -25), Vector2(28, -22), Vector2(40, -17)]
	var key: Array = rest
	match state:
		"windup_sting", "windup_spit": key = armed
		"sting": key = strike
	var shake := Vector2(sin(anim_t * 50.0), 0) * (1.0 if state == "windup_sting" else 0.0)
	var pts: Array = []
	for q in key:
		var v: Vector2 = q
		pts.append(Vector2(v.x * f, v.y + sin(anim_t * 3.0 + v.y * 0.1) * 0.6) + shake)
	for i in range(1, pts.size()):
		draw_line(pts[i - 1], pts[i], dark, 4.5 - i * 0.3)
	for i in range(1, pts.size()):
		DU.ball(self, pts[i], 3.8 - i * 0.35, shell)
	var prev: Vector2 = pts[pts.size() - 1]
	# dard
	var tip_dir: Vector2 = (prev - pts[pts.size() - 2]).normalized().rotated(0.6 * f if state != "sting" else 0.0)
	DU.flat(self, PackedVector2Array([prev + tip_dir.orthogonal() * 3.0, prev + tip_dir * 9.0, prev - tip_dir.orthogonal() * 3.0]), Color(0.9, 0.85, 0.7))
	if state == "windup_sting" or state == "windup_spit":
		DU.glow(self, prev, 10.0, Color(0.6, 1.0, 0.35), 0.5)
	# tête et pinces
	var hd := Vector2(f * 10.0, 0.0)
	DU.poly(self, DU.ellipse(hd, Vector2(7, 5.5)), shell)
	draw_circle(hd + Vector2(f * 3.0, -3.0), 1.2, Color(0.1, 0.05, 0.02))
	draw_circle(hd + Vector2(f * 0.5, -3.5), 1.0, Color(0.1, 0.05, 0.02))
	for s in [-1.0, 1.0]:
		var arm := hd + Vector2(f * 6.0, s * 2.0 + 1.0)
		var claw := arm + Vector2(f * 9.0, -2.0 + s * 3.0)
		draw_line(arm, claw, dark, 3.0)
		var op := 0.35 + 0.25 * sin(anim_t * 6.0 + s)
		DU.flat(self, PackedVector2Array([claw, claw + Vector2(f * 7.0, -3.0 - op * 3.0), claw + Vector2(f * 3.0, 0)]), shell.lightened(0.1))
		DU.flat(self, PackedVector2Array([claw, claw + Vector2(f * 7.0, 2.0 + op * 3.0), claw + Vector2(f * 3.0, 0)]), shell)
	draw_stun(-22.0)

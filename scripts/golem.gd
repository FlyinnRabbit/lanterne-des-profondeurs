extends "res://scripts/enemy.gd"
# Golem de givre (Abysses Gelés) : bloc de glace lent et lourd (presque pas de recul). À portée,
# il lève les poings et frappe le sol : une onde de givre court au ras du sol des deux côtés
# (il faut la sauter). Élite : deux ondes à la suite.

var dir := -1.0
var windup := 0.0
var slam_cd := 1.5
var waves := 0
var wave_x := []     # ondes en cours : [x, sens, vie]

func _ready() -> void:
	size = Vector2(36, 42)
	hp = 6
	geo_value = 6
	knock_resist = 0.25
	setup_body()

func telegraph() -> int:
	return 1 if windup > 0.0 and stun_t <= 0.0 else 0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	_waves(delta)
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
		windup = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity.x = 0.0
		if windup <= 0.0:
			_slam()
			if waves > 0:
				waves -= 1
				windup = 0.5
	else:
		knock = Vector2.ZERO
		slam_cd -= delta
		var near: bool = p and not p.dead and absf(p.global_position.y - global_position.y) < 80.0 * reach and absf(p.global_position.x - global_position.x) < 300.0 * aggro()
		if near:
			dir = -1.0 if p.global_position.x < global_position.x else 1.0
			if absf(p.global_position.x - global_position.x) < 190.0 and slam_cd <= 0.0 and is_on_floor():
				windup = 0.75 if not elite else 0.55
				waves = 1 if elite else 0
				slam_cd = 2.6 / aggro()
		velocity.x = dir * 38.0 * spd()
		if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 22.0, size.y / 2.0 + 8.0)):
			dir = -dir
	move_and_slide()
	if is_on_wall():
		dir = -dir
	queue_redraw()

func _slam() -> void:
	main.shake(6)
	Audio.sfx("hammer", 0.1, -4.0)
	main.spawn_burst(global_position + Vector2(0, size.y / 2.0), Color(0.8, 0.92, 1.0), 16, 200.0)
	wave_x.append([0.0, 1.0, 0.0])
	wave_x.append([0.0, -1.0, 0.0])

func _waves(delta: float) -> void:
	var p = main.player
	var foot := global_position.y + size.y / 2.0
	for w in wave_x.duplicate():
		w[0] += w[1] * 330.0 * delta
		w[2] += delta
		var wx: float = global_position.x + w[0]
		if w[2] > 0.9 or main.is_solid_at(Vector2(wx, foot - 10.0)) or not main.is_solid_at(Vector2(wx, foot + 6.0)):
			wave_x.erase(w)
			continue
		if p and not p.dead and absf(p.global_position.x - wx) < 14.0 and p.get_rect().end.y > foot - 18.0 and absf(p.global_position.y - foot) < 60.0:
			p.receive_hit(Vector2(wx, foot), self)

func fx_color() -> Color:
	return Color(0.75, 0.9, 1.0)

func _draw() -> void:
	var ice := body_color(Color(0.62, 0.82, 0.98) if not elite else Color(0.55, 0.7, 1.0))
	var dark := ice.darkened(0.45)
	var lift := -10.0 if windup > 0.0 else 0.0
	var f := dir
	# corps en blocs
	DU.flat(self, PackedVector2Array([Vector2(-16, 20), Vector2(-18, -4), Vector2(-10, -16), Vector2(10, -16), Vector2(18, -4), Vector2(16, 20)]), ice)
	DU.flat(self, PackedVector2Array([Vector2(-16, 20), Vector2(-18, -4), Vector2(-10, -16), Vector2(-4, -16), Vector2(-6, 20)]), Color(1, 1, 1, 0.18))
	draw_line(Vector2(-6, -6), Vector2(4, 6), dark, 1.4)
	draw_line(Vector2(4, 6), Vector2(10, 2), dark, 1.2)
	# tête
	DU.flat(self, PackedVector2Array([Vector2(-7, -16), Vector2(-6, -26), Vector2(6, -27), Vector2(8, -16)]), ice.lightened(0.1))
	draw_circle(Vector2(f * 3, -21), 2.2, Color(0.2, 0.6, 1.0))
	DU.glow(self, Vector2(f * 3, -21), 8.0, Color(0.4, 0.8, 1.0), 0.4)
	# poings
	for sd in [-1.0, 1.0]:
		var hp2 := Vector2(sd * 21, 4 + lift * (1.6 if windup > 0.0 else 0.0))
		DU.flat(self, DU.ellipse(hp2, Vector2(7, 8)), ice.darkened(0.12))
	# ondes de givre
	var foot := size.y / 2.0
	for w in wave_x:
		var x: float = w[0]
		var a: float = 1.0 - w[2] / 0.9
		for k in 3:
			DU.flat(self, PackedVector2Array([Vector2(x - 6 + k * 4, foot), Vector2(x - 3 + k * 4, foot - 14 + k * 3), Vector2(x + k * 4, foot)]), Color(0.85, 0.95, 1.0, a))
	draw_stun(-34.0)

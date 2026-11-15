extends CharacterBody2D
# Le Veilleur : petit voyageur encapuchonné armé d'une aiguille.
# Course, saut à hauteur variable, ruée (dash), coups dans 4 directions
# (le coup vers le bas fait rebondir : « pogo »), concentration pour se soigner.

const DU = preload("res://scripts/draw_util.gd")
const C = preload("res://scripts/charms.gd")

const SIZE := Vector2(20, 34)
const RUN_SPEED := 270.0
const GRAVITY := 1800.0
const FALL_MAX := 950.0
const JUMP_VELOCITY := -720.0
const JUMP_CUT := 0.4
const COYOTE := 0.1
const JUMP_BUFFER := 0.12
const DASH_SPEED := 760.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.45
const ATTACK_COOLDOWN := 0.36
const ATTACK_TIME := 0.12
const POGO_VELOCITY := -580.0
const INVULN_TIME := 1.3
const FOCUS_TIME := 0.9
const SOUL_PER_HIT := 11
const FOCUS_COST := 33
const SOUL_MAX := 99
const PARRY_WINDOW := 0.2
const PARRY_COOLDOWN := 0.55
const ULT_MAX := 100
const ULT_PER_HIT := 6
const ULT_PER_PARRY := 25
const ULT_CHARGE_TIME := 0.55

var main
var max_hp := 5
var hp := 5
var soul := 0
var geo := 0
var can_dash := false
var facing := 1
var coyote_t := 0.0
var buffer_t := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var air_dash_used := false
var attack_cd := 0.0
var attack_t := 0.0
var attack_dir := Vector2.RIGHT
var attack_hit := {}
var invuln_t := 0.0
var knock_t := 0.0
var recoil_t := 0.0
var recoil_vx := 0.0
var focus_t := 0.0
var last_safe := Vector2.ZERO
var sitting := false
var dead := false
var anim_t := 0.0
var squash := Vector2.ONE
var was_on_floor := true
var parry_t := 0.0
var parry_cd := 0.0
var parry_flash := 0.0
var ult := 0
var ult_charge_t := 0.0

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	last_safe = global_position

# ---------------------------------------------------------------- emblèmes
func eq(id: int) -> bool:
	return GameState.has_charm(id)

func run_speed() -> float:
	return RUN_SPEED * (1.12 if eq(C.SWIFT_CLOAK) else 1.0)

func dash_cooldown() -> float:
	return DASH_COOLDOWN * (0.5 if eq(C.SWIFT_CLOAK) else 1.0)

func parry_window() -> float:
	return 0.35 if eq(C.MIRROR) else PARRY_WINDOW

func focus_time() -> float:
	return FOCUS_TIME * (0.55 if eq(C.QUICK_FOCUS) else 1.0)

func soul_per_hit() -> int:
	return roundi((SOUL_PER_HIT + (6 if eq(C.GREED) else 0)) * float(GameState.d("soul")))

func ult_per_hit() -> int:
	return roundi((ULT_PER_HIT + (4 if eq(C.GREED) else 0)) * float(GameState.d("ult")))

func nail_damage() -> int:
	return 2 if eq(C.BRUTE) else 1

func reach() -> float:
	return 1.4 if eq(C.LONG_NAIL) else 1.0

# À appeler quand l'équipement change
func apply_equipment() -> void:
	max_hp = 5 + (2 if eq(C.GLASS_HEART) else 0) + GameState.max_hp_bonus()
	hp = mini(hp, max_hp)

func get_rect() -> Rect2:
	return Rect2(global_position - SIZE / 2.0, SIZE)

func _physics_process(delta: float) -> void:
	anim_t += delta
	for t in ["coyote_t", "buffer_t", "dash_t", "dash_cd", "attack_cd", "attack_t", "invuln_t", "knock_t", "recoil_t"]:
		set(t, maxf(get(t) - delta, 0.0))
	parry_t = maxf(parry_t - delta, 0.0)
	parry_cd = maxf(parry_cd - delta, 0.0)
	parry_flash = maxf(parry_flash - delta, 0.0)
	squash = squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	modulate.a = 0.35 if (invuln_t > 0.0 and fmod(invuln_t, 0.16) < 0.08 and not sitting) else 1.0
	queue_redraw()
	if dead:
		return
	if sitting:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump") or absf(Input.get_axis("move_left", "move_right")) > 0.5 or Input.is_action_just_pressed("down"):
			sitting = false
		return

	# Ultime : immobile et invulnérable pendant la charge, puis onde de choc
	if ult_charge_t > 0.0:
		ult_charge_t -= delta
		velocity = Vector2.ZERO
		if ult_charge_t <= 0.0:
			main.ultimate_blast(global_position)
			invuln_t = maxf(invuln_t, 0.4)
		return
	if Input.is_action_just_pressed("ultimate") and knock_t <= 0.0:
		if ult >= ULT_MAX:
			ult = 0
			ult_charge_t = ULT_CHARGE_TIME
			dash_t = 0.0
			attack_t = 0.0
			main.on_ultimate_charge(self)
			return
		else:
			main.show_message("Ultime pas encore chargé", 0.9)

	# Parade : courte fenêtre où un coup ou un projectile est renvoyé
	if Input.is_action_just_pressed("parry") and parry_cd <= 0.0 and knock_t <= 0.0:
		parry_t = parry_window()
		parry_cd = PARRY_COOLDOWN

	var dir := Input.get_axis("move_left", "move_right")
	if absf(dir) < 0.3:
		dir = 0.0
	else:
		dir = signf(dir)
	if Input.is_action_just_pressed("jump"):
		buffer_t = JUMP_BUFFER
	var on_floor := is_on_floor()
	if on_floor:
		coyote_t = COYOTE
		air_dash_used = false
		if not was_on_floor:
			squash = Vector2(1.3, 0.7)
			main.spawn_burst(global_position + Vector2(0, SIZE.y / 2), Color(0.6, 0.65, 0.8, 0.6), 6, 80.0, 50.0)
		_update_safe_spot()

	# Concentration (soin) : maintenir L au sol avec 33 d'âme
	if Input.is_action_pressed("focus") and on_floor and soul >= FOCUS_COST and hp < max_hp and knock_t <= 0.0:
		focus_t += delta
		velocity.x = 0.0
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
		if focus_t >= focus_time():
			focus_t = 0.0
			soul -= FOCUS_COST
			hp += 1
			Audio.sfx("heal", 0.0)
			main.spawn_burst(global_position, Color(1, 1, 1), 20, 160.0, -100.0)
		move_and_slide()
		_post_move(on_floor)
		return
	focus_t = 0.0

	# Ruée
	if can_dash and Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and (on_floor or not air_dash_used) and knock_t <= 0.0:
		if dir != 0.0:
			facing = int(dir)
		dash_t = DASH_TIME
		dash_cd = dash_cooldown()
		Audio.sfx("dash")
		if not on_floor:
			air_dash_used = true
		squash = Vector2(1.3, 0.8)
		main.spawn_burst(global_position, Color(0.2, 0.2, 0.3, 0.8), 10, 120.0, 0.0)
	if dash_t > 0.0:
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		move_and_slide()
		_post_move(on_floor)
		return

	# Déplacement horizontal (nerveux, sans inertie, comme l'original)
	if knock_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
	elif recoil_t > 0.0:
		velocity.x = recoil_vx
	else:
		velocity.x = dir * run_speed() * (0.35 if parry_t > 0.0 else 1.0)
		if dir != 0.0 and attack_t <= 0.0:
			facing = int(dir)

	# Saut
	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	if buffer_t > 0.0 and coyote_t > 0.0 and knock_t <= 0.0:
		velocity.y = JUMP_VELOCITY
		Audio.sfx("jump", 0.1, -4.0)
		buffer_t = 0.0
		coyote_t = 0.0
		squash = Vector2(0.7, 1.3)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Attaque
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0 and knock_t <= 0.0:
		attack_cd = ATTACK_COOLDOWN
		attack_t = ATTACK_TIME
		Audio.sfx("slash", 0.12, -2.0)
		attack_hit.clear()
		if Input.is_action_pressed("up"):
			attack_dir = Vector2.UP
		elif Input.is_action_pressed("down") and not on_floor:
			attack_dir = Vector2.DOWN
		else:
			attack_dir = Vector2(facing, 0)
	if attack_t > 0.0:
		_do_attack_hits()

	move_and_slide()
	_post_move(on_floor)

func _post_move(prev_on_floor: bool) -> void:
	was_on_floor = is_on_floor()
	if not prev_on_floor and was_on_floor:
		pass
	_check_hazards()

func _update_safe_spot() -> void:
	var feet_y := global_position.y + SIZE.y / 2.0 + 4.0
	var l := Vector2(global_position.x - SIZE.x, feet_y)
	var r := Vector2(global_position.x + SIZE.x, feet_y)
	if main.is_solid_at(l) and main.is_solid_at(r):
		last_safe = global_position

func attack_rect() -> Rect2:
	var p := global_position
	if attack_dir == Vector2.UP:
		var hu := 62.0 * reach()
		return Rect2(p + Vector2(-32, -SIZE.y / 2.0 + 4 - hu), Vector2(64, hu))
	if attack_dir == Vector2.DOWN:
		return Rect2(p + Vector2(-32, SIZE.y / 2.0 - 6), Vector2(64, 62.0 * reach()))
	var w := 70.0 * reach()
	var x := p.x + SIZE.x / 2.0 - 4.0 if facing > 0 else p.x - SIZE.x / 2.0 - w + 4.0
	return Rect2(Vector2(x, p.y - 30), Vector2(w, 54))

func _do_attack_hits() -> void:
	var r := attack_rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or attack_hit.has(e):
			continue
		if e.get_rect().intersects(r):
			attack_hit[e] = true
			e.take_hit(nail_damage(), attack_dir)
			Audio.sfx("hit")
			soul = mini(soul + soul_per_hit(), SOUL_MAX)
			ult = mini(ult + ult_per_hit(), ULT_MAX)
			main.shake(4)
			main.hit_stop(0.04)
			if attack_dir == Vector2.DOWN:
				_pogo()
			elif attack_dir.x != 0.0:
				recoil_t = 0.08
				recoil_vx = -facing * 320.0
	# Les spores ennemies peuvent être détruites d'un coup d'aiguille
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile and pr.get_rect().intersects(r):
			pr.pop()
			soul = mini(soul + 4, SOUL_MAX)
	if attack_dir == Vector2.DOWN and not attack_hit.has("spikes"):
		for s in main.spikes:
			if s.intersects(r):
				attack_hit["spikes"] = true
				main.spawn_burst(Vector2(global_position.x, s.position.y), Color(1, 1, 1), 6, 120.0)
				_pogo()
				break

func _pogo() -> void:
	velocity.y = POGO_VELOCITY
	air_dash_used = false
	dash_cd = 0.0
	squash = Vector2(0.8, 1.2)

func _check_hazards() -> void:
	if dead:
		return
	var r := get_rect().grow(-3)
	for s in main.spikes:
		if r.intersects(s):
			_hazard_respawn()
			return
	# Esquive : pendant la ruée on traverse ennemis et projectiles
	if dash_t > 0.0:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_harmful() and r.intersects(e.get_rect()):
			receive_hit(e.global_position, e)
			return

# Point d'entrée de tout coup reçu (contact ou projectile). Renvoie true si paré.
func receive_hit(from_pos: Vector2, source) -> bool:
	if dead:
		return false
	if parry_t > 0.0:
		_on_parry(from_pos, source)
		return true
	if invuln_t > 0.0 or ult_charge_t > 0.0 or sitting:
		return false
	take_damage(int(GameState.d("dmg")), from_pos.x)
	return false

func _on_parry(from_pos: Vector2, source) -> void:
	parry_t = 0.0
	parry_cd = 0.12
	parry_flash = 0.25
	invuln_t = maxf(invuln_t, 0.4)
	ult = mini(ult + roundi(ULT_PER_PARRY * float(GameState.d("ult"))), ULT_MAX)
	soul = mini(soul + soul_per_hit(), SOUL_MAX)
	var d := (from_pos - global_position).normalized()
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	if source and source.has_method("parried"):
		source.parried(d)
	velocity.x = -signf(d.x) * 200.0
	recoil_t = 0.1
	recoil_vx = velocity.x
	main.on_parry(global_position + d * 18.0)

func take_damage(amount: int, from_x: float) -> void:
	if dead:
		return
	hp -= amount
	invuln_t = INVULN_TIME
	knock_t = 0.22
	dash_t = 0.0
	focus_t = 0.0
	sitting = false
	var d := signf(global_position.x - from_x)
	if d == 0.0:
		d = -facing
	velocity = Vector2(d * 380.0, -380.0)
	main.on_player_hurt()
	if eq(C.THORNS):
		main.thorns_burst(global_position)
	if hp <= 0:
		_die()

func _hazard_respawn() -> void:
	hp -= int(GameState.d("dmg"))
	main.on_player_hurt()
	if hp <= 0:
		_die()
		return
	global_position = last_safe
	velocity = Vector2.ZERO
	invuln_t = INVULN_TIME
	knock_t = 0.3

func _die() -> void:
	dead = true
	hp = 0
	velocity = Vector2.ZERO
	visible = false
	main.on_player_died()

func respawn(pos: Vector2) -> void:
	global_position = pos
	last_safe = pos
	velocity = Vector2.ZERO
	hp = max_hp
	dead = false
	visible = true
	invuln_t = 1.0
	ult_charge_t = 0.0
	parry_t = 0.0

func sit(pos: Vector2) -> void:
	sitting = true
	global_position = pos
	last_safe = pos
	velocity = Vector2.ZERO
	hp = max_hp

# ---------------------------------------------------------------- dessin
func _draw() -> void:
	var moving := absf(velocity.x) > 10.0 and is_on_floor()
	var bob := sin(anim_t * 16.0) * 1.5 if moving else sin(anim_t * 2.5) * 0.6
	var sway := sin(anim_t * 16.0) * 3.0 if moving else sin(anim_t * 2.0) * 1.0
	if not is_on_floor():
		sway = clampf(velocity.y / 120.0, -4.0, 4.0)
	if sitting:
		bob = 4.0

	# Traînée de ruée
	if dash_t > 0.0:
		for i in 4:
			var a := 0.35 - i * 0.08
			draw_rect(Rect2(Vector2(-facing * (14 + i * 16) - 8, -14 + i * 2), Vector2(16, 24 - i * 4)), Color(0.15, 0.15, 0.25, a))

	# Ultime en charge : anneaux dorés qui se resserrent
	if ult_charge_t > 0.0:
		var k := 1.0 - ult_charge_t / ULT_CHARGE_TIME
		for i in 3:
			var rr := (1.0 - fmod(k + i * 0.33, 1.0)) * 70.0 + 8.0
			draw_arc(Vector2(0, -4), rr, 0.0, TAU, 40, Color(1.0, 0.85, 0.45, 0.25 + 0.6 * k), 3.0)
		draw_circle(Vector2(0, -4), 10.0 + 14.0 * k, Color(1.0, 0.9, 0.6, 0.35))
	elif ult >= ULT_MAX:
		draw_circle(Vector2(0, -4), 26.0 + sin(anim_t * 6.0) * 3.0, Color(1.0, 0.85, 0.45, 0.12))
	# Parade : garde levée et éclat
	if parry_t > 0.0:
		var base_a := 0.0 if facing > 0 else PI
		draw_arc(Vector2(facing * 10, -6), 22.0, base_a - 1.4, base_a + 1.4, 16, Color(0.8, 0.9, 1.0, 0.8), 3.0)
		draw_line(Vector2(facing * 8, -20), Vector2(facing * 8, 6), Color(0.9, 0.92, 1.0), 2.5)
	if parry_flash > 0.0:
		var pk := parry_flash / 0.25
		draw_arc(Vector2(0, -6), 40.0 * (1.5 - pk), 0.0, TAU, 32, Color(1, 1, 1, pk), 4.0 * pk + 1.0)
	# Halo de concentration
	if focus_t > 0.0:
		var k := focus_t / focus_time()
		draw_circle(Vector2(0, -4), 10.0 + 30.0 * k, Color(1, 1, 1, 0.12 + 0.2 * k))

	draw_set_transform(Vector2(0, SIZE.y / 2.0), 0.0, Vector2(squash.x * facing, squash.y))
	var cloak := Color(0.07, 0.06, 0.11)
	var trim := Color(0.22, 0.2, 0.32)
	# Écharpe qui flotte
	var scarf := PackedVector2Array([Vector2(-4, -24 + bob), Vector2(-12, -22 + bob + sway * 0.5), Vector2(-20, -24 + bob + sway), Vector2(-26, -20 + bob + sway * 1.4)])
	draw_polyline(scarf, Color(0.45, 0.8, 0.82), 3.0)
	# Cape
	var cape := PackedVector2Array([
		Vector2(-8, -26 + bob), Vector2(8, -26 + bob), Vector2(12, -3), Vector2(8, 0),
		Vector2(4, -4 + sway * 0.3), Vector2(0, 0), Vector2(-4, -4 - sway * 0.3), Vector2(-8, 0), Vector2(-13, -3)])
	draw_colored_polygon(cape, cloak)
	draw_polyline(cape, trim, 1.2)
	# Petites jambes
	if not sitting:
		var step := sin(anim_t * 16.0) * 3.0 if moving else 0.0
		draw_line(Vector2(-3, -3), Vector2(-3 + step, 0), cloak, 3.0)
		draw_line(Vector2(3, -3), Vector2(3 - step, 0), cloak, 3.0)
	# Capuche pointue (la pointe retombe vers l'arrière)
	var hy := -26.0 + bob
	var hood := PackedVector2Array([
		Vector2(-10, hy + 4), Vector2(11, hy + 4), Vector2(12, hy - 8), Vector2(6, hy - 16),
		Vector2(-4, hy - 18), Vector2(-14, hy - 22 + sway * 0.5), Vector2(-11, hy - 8)])
	draw_colored_polygon(hood, cloak)
	draw_polyline(hood, trim, 1.2)
	# Visage : vide sombre et un œil ambré
	draw_colored_polygon(DU.ellipse(Vector2(3, hy - 6), Vector2(6.5, 6.0)), Color(0.0, 0.0, 0.02))
	var blink := 0.3 if fmod(anim_t, 3.7) < 0.12 else 2.6
	draw_circle(Vector2(5, hy - 6), 5.0, Color(1.0, 0.7, 0.3, 0.25))
	draw_colored_polygon(DU.ellipse(Vector2(5, hy - 6), Vector2(2.4, blink)), Color(1.0, 0.8, 0.4))
	# Aiguille tenue au repos
	if attack_t <= 0.0 and not sitting:
		draw_line(Vector2(8, -14 + bob), Vector2(16, -2), Color(0.8, 0.82, 0.9), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Arc de l'attaque
	if attack_t > 0.0:
		var k := attack_t / ATTACK_TIME
		var r := attack_rect()
		var c := r.get_center() - global_position
		var ang := attack_dir.angle()
		var col := Color(0.95, 0.97, 1.0, 0.9 * k)
		draw_arc(c - attack_dir * 14.0, 30.0, ang - 1.3, ang + 1.3, 18, col, 7.0 * k + 1.0)
		draw_arc(c - attack_dir * 18.0, 22.0, ang - 1.0, ang + 1.0, 14, Color(0.7, 0.85, 1.0, 0.5 * k), 3.0)
		draw_line(Vector2.ZERO, attack_dir * 30.0 + Vector2(0, -4), Color(0.85, 0.87, 0.95), 2.0)

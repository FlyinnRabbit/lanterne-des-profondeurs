extends "res://scripts/enemy.gd"
# Base commune des boss : réveil, remise à zéro, phase 2 à mi-vie, étourdissement à la parade.
# Chaque boss implémente _choose() (choisir l'attaque) et _tick(delta) (exécuter l'état courant).

var max_hp := 40
var boss_name := "Boss"
var home := Vector2.ZERO
var floor_y := 0.0
var state := "sleep"
var state_t := 0.0
var dir := -1
var phase := 1
var last_attack := ""

func boss_setup(sz: Vector2, base_hp: int, name: String) -> void:
	size = sz
	is_boss = true
	boss_name = name
	max_hp = roundi(base_hp * float(GameState.scaled("boss_hp")))
	hp = max_hp
	geo_value = 0
	knock_resist = 0.0
	setup_body()
	floor_y = home.y + size.y / 2.0

func p():
	return main.player

func wake() -> void:
	state = "idle"
	state_t = 1.0

func reset() -> void:
	hp = max_hp
	phase = 1
	state = "sleep"
	stun_t = 0.0
	visible = true
	global_position = home
	velocity = Vector2.ZERO

func is_harmful() -> bool:
	return not dead and state != "sleep" and stun_t <= 0.0

func rage() -> float:
	return (1.3 if phase == 2 else 1.0) * sqrt(float(GameState.scaled("speed")) * float(GameState.scaled("aggro")))

func take_hit(dmg: int, dir_hit: Vector2) -> void:
	if state == "sleep":
		return
	super.take_hit(dmg, dir_hit)
	if phase == 1 and hp > 0 and hp <= max_hp / 2:
		phase = 2
		main.shake(14)
		main.spawn_burst(global_position, Color(1.0, 0.5, 0.4), 40, 320.0, 0.0)
		Audio.sfx("hurt", 0.0, 2.0)
		on_phase2()

func on_phase2() -> void:
	pass

func parried(_d: Vector2) -> void:
	flash_t = 0.1
	if not try_stun(1.0 * stun_mult()):
		return
	state = "recover"
	state_t = 1.0

func die() -> void:
	dead = true
	remove_from_group("enemies")
	main.on_boss_killed()
	queue_free()

func face_player() -> void:
	dir = -1 if p().global_position.x < global_position.x else 1

# Tirage d'une attaque pondérée, en évitant de répéter deux fois la même
func pick(weights: Dictionary) -> String:
	var w := weights.duplicate()
	if w.size() > 1 and w.has(last_attack):
		w.erase(last_attack)
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			last_attack = k
			return k
	last_attack = w.keys()[0]
	return last_attack

func go(s: String, t: float) -> void:
	state = s
	state_t = t

func telegraphing() -> bool:
	return state.begins_with("windup")

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	state_t -= delta
	stun_t -= delta
	if stun_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
		if motion_mode == MOTION_MODE_GROUNDED:
			velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	if state == "sleep":
		velocity.x = 0.0
		if motion_mode == MOTION_MODE_GROUNDED:
			velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
		move_and_slide()
		queue_redraw()
		return
	if state == "idle" and state_t <= 0.0:
		_choose()
	_tick(delta)
	queue_redraw()

func _choose() -> void:
	go("idle", 1.0)

func _tick(_delta: float) -> void:
	pass

# Petites étoiles d'étourdissement
func draw_stun(y: float) -> void:
	if stun_t > 0.0:
		for i in 4:
			var a := anim_t * 4.0 + i * TAU / 4.0
			DU.ball(self, Vector2(cos(a) * 26.0, y + sin(a) * 5.0), 3.0, Color(1, 1, 0.7))

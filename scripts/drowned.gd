extends "res://scripts/enemy.gd"
# Noyé (Citadelle Engloutie) : un fidèle englouti qui sort d'une flaque quand le héros approche,
# avance en titubant et l'agrippe de ses bras ruisselants. Élite : il se replonge et ressurgit
# derrière le héros.

var dir := -1.0
var state := "hidden"    # hidden / appear / walk / windup / grab / sink
var st_t := 0.0
var rise := 0.0           # 0 sous l'eau, 1 debout
var dove := false

func _ready() -> void:
	size = Vector2(22, 40)
	hp = 4
	geo_value = 4
	setup_body()

func is_harmful() -> bool:
	return super.is_harmful() and state in ["walk", "windup", "grab"]

func take_hit(dmg: int, d: Vector2) -> void:
	if state == "hidden":
		return
	super.take_hit(dmg, d)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	st_t -= delta
	var dxp: float = (p.global_position.x - global_position.x) if p else 999.0
	match state:
		"hidden":
			rise = 0.0
			velocity.x = 0.0
			if p and not p.dead and absf(dxp) < 170.0 * aggro() and absf(p.global_position.y - global_position.y) < 70.0:
				state = "appear"
				st_t = 0.8
				Audio.sfx("spit", 0.2, -8.0)
		"appear":
			rise = 1.0 - st_t / 0.8
			velocity.x = 0.0
			if st_t <= 0.0:
				state = "walk"
		"walk":
			rise = 1.0
			if absf(knock.x) > 10.0:
				velocity.x = knock.x
				knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
			elif stun_t > 0.0:
				velocity.x = 0.0
			else:
				dir = -1.0 if dxp < 0.0 else 1.0
				velocity.x = dir * 50.0 * spd()
				if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 16.0, size.y / 2.0 + 8.0)):
					velocity.x = 0.0
				if absf(dxp) < 44.0:
					state = "windup"
					st_t = 0.4
				elif elite and not dove and absf(dxp) > 140.0:
					state = "sink"
					st_t = 0.6
		"windup":
			velocity.x = 0.0
			if st_t <= 0.0:
				state = "grab"
				st_t = 0.3
				if p and absf(dxp) < 52.0 and absf(p.global_position.y - global_position.y) < 50.0:
					p.receive_hit(global_position, self)
		"grab":
			velocity.x = 0.0
			if st_t <= 0.0:
				state = "walk"
		"sink":
			rise = st_t / 0.6
			velocity.x = 0.0
			if st_t <= 0.0 and p:
				dove = true
				var nx: float = p.global_position.x - signf(dxp) * 60.0
				if main.is_solid_at(Vector2(nx, global_position.y + size.y / 2.0 + 8.0)) and not main.is_solid_at(Vector2(nx, global_position.y)):
					global_position.x = nx
				state = "appear"
				st_t = 0.6
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(0.4, 0.55, 0.6)

func _draw() -> void:
	var foot := size.y / 2.0
	# flaque
	DU.flat(self, DU.ellipse(Vector2(0, foot - 1), Vector2(20, 4)), Color(0.25, 0.4, 0.55, 0.8))
	draw_arc(Vector2(0, foot - 1), 16.0 + fmod(anim_t * 8.0, 6.0), PI, TAU, 10, Color(0.6, 0.8, 1.0, 0.4), 1.0)
	if rise <= 0.02:
		draw_circle(Vector2(sin(anim_t * 2.0) * 6, foot - 3), 1.5, Color(0.7, 0.9, 1.0, 0.6))
		return
	var h := 40.0 * rise
	var skin := body_color(Color(0.42, 0.52, 0.5) if not elite else Color(0.45, 0.4, 0.55))
	var robe := body_color(Color(0.2, 0.24, 0.3))
	var f := dir
	var top := foot - h
	# robe trempée qui ruisselle
	DU.flat(self, PackedVector2Array([Vector2(-9, foot), Vector2(-7, top + 14), Vector2(7, top + 14), Vector2(9, foot)]), robe)
	for i in 3:
		var dx := -5.0 + i * 5.0
		var dy := fmod(anim_t * 30.0 + i * 7.0, 20.0)
		draw_line(Vector2(dx, top + 16 + dy), Vector2(dx, top + 19 + dy), Color(0.6, 0.85, 1.0, 0.6), 1.0)
	# tête penchée, capuche
	DU.flat(self, DU.ellipse(Vector2(f * 2, top + 7), Vector2(7, 7)), robe.lightened(0.1))
	DU.flat(self, DU.ellipse(Vector2(f * 3, top + 9), Vector2(4.5, 4.5)), skin)
	draw_circle(Vector2(f * 4.5, top + 8), 1.2, Color(0.9, 1.0, 0.9))
	# bras tendus
	var reach := 1.0 if state in ["windup", "grab"] else 0.5
	var arm_y := top + 18
	draw_line(Vector2(f * 4, arm_y), Vector2(f * (10 + 12 * reach), arm_y - 4 + (6 if state == "grab" else 0)), skin, 2.6)
	draw_line(Vector2(-f * 2, arm_y + 2), Vector2(f * (6 + 10 * reach), arm_y + 2), skin.darkened(0.15), 2.4)
	draw_stun(top - 6)

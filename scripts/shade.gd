extends "res://scripts/enemy.gd"
# Ombre : reste du héros là où il est tombé. Elle garde les éclats perdus ;
# la vaincre les rend. Elle flotte lentement vers le joueur et blesse au contact.
var geo_kept := 0
var home := Vector2.ZERO

func _ready() -> void:
	size = Vector2(22, 34)
	hp = 4
	show_bar = true
	setup_body()
	hp = 4
	hp_max = 4
	geo_value = geo_kept
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 0
	home = global_position
	add_child(main.make_light(Color(0.6, 0.5, 1.0), 0.8, 0.9))

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	var target := home + Vector2(sin(anim_t * 0.7) * 20.0, sin(anim_t * 1.3) * 10.0)
	if p and not p.dead and p.global_position.distance_to(global_position) < 300.0:
		target = p.global_position + Vector2(0, -8)
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		velocity = velocity.move_toward((target - global_position).normalized() * 70.0, 400.0 * delta)
	move_and_slide()
	queue_redraw()

func die() -> void:
	GameState.prog.erase("shade")
	GameState.snapshot.erase("shade")
	Achievements.unlock("shade")
	main.show_message(tr("Ombre vaincue : %d éclats récupérés !") % geo_kept, 3.0)
	Audio.sfx("pickup", 0.0)
	super.die()

func _draw() -> void:
	var c := body_color(Color(0.12, 0.08, 0.2, 0.9))
	var bob := sin(anim_t * 3.0) * 2.0
	var pts := PackedVector2Array()
	for i in 12:
		var a := PI + i * PI / 11.0
		pts.append(Vector2(cos(a) * 11.0, -6 + bob + sin(a) * 14.0))
	for i in 5:
		pts.append(Vector2(11.0 - i * 5.5, 16 + bob + (4.0 if i % 2 == 0 else 0.0) + sin(anim_t * 6.0 + i) * 2.0))
	draw_colored_polygon(pts, c)
	draw_line(Vector2(-6, -18 + bob), Vector2(-10, -30 + bob), c, 3.0)
	draw_line(Vector2(6, -18 + bob), Vector2(10, -30 + bob), c, 3.0)
	draw_circle(Vector2(-4, -8 + bob), 2.5, Color(0.85, 0.75, 1.0))
	draw_circle(Vector2(4, -8 + bob), 2.5, Color(0.85, 0.75, 1.0))
	draw_circle(Vector2.ZERO, 26.0, Color(0.5, 0.35, 0.9, 0.08 + 0.05 * sin(anim_t * 2.0)))

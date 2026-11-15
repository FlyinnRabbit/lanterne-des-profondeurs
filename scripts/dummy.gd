extends "res://scripts/enemy.gd"
# Mannequin d'entraînement : ne bouge pas, ne blesse pas, ne meurt pas.

var wobble := 0.0

func _ready() -> void:
	size = Vector2(28, 44)
	hp = 9999
	geo_value = 0
	setup_body()

func is_harmful() -> bool:
	return false

func parried(_d: Vector2) -> void:
	pass

func take_hit(dmg: int, dir: Vector2) -> void:
	flash_t = 0.12
	wobble = 1.0 * (signf(dir.x) if dir.x != 0.0 else 1.0)
	main.spawn_burst(global_position, Color(0.85, 0.75, 0.55), 6 + dmg, 140.0)
	hp = 9999

func _physics_process(delta: float) -> void:
	flash_t -= delta
	anim_t += delta
	wobble = move_toward(wobble, 0.0, delta * 3.0)
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	velocity.x = 0.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var ang := sin(anim_t * 25.0) * 0.25 * absf(wobble) * signf(wobble)
	draw_set_transform(Vector2(0, 22), ang, Vector2.ONE)
	var wood := Color(0.42, 0.32, 0.24)
	var straw := body_color(Color(0.78, 0.68, 0.45))
	draw_line(Vector2(0, 0), Vector2(0, -44), wood, 4.0)
	draw_line(Vector2(-14, -30), Vector2(14, -30), wood, 3.0)
	draw_colored_polygon(DU.ellipse(Vector2(0, -26), Vector2(11, 12)), straw)
	draw_circle(Vector2(0, -44), 8.0, straw)
	draw_line(Vector2(-4, -46), Vector2(-1, -43), Color(0.2, 0.15, 0.1), 2.0)
	draw_line(Vector2(-1, -46), Vector2(-4, -43), Color(0.2, 0.15, 0.1), 2.0)
	draw_line(Vector2(2, -46), Vector2(5, -43), Color(0.2, 0.15, 0.1), 2.0)
	draw_line(Vector2(5, -46), Vector2(2, -43), Color(0.2, 0.15, 0.1), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

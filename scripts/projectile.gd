extends Node2D
# Boule de spores tirée par les cracheurs et l'Abbesse.
# Une parade la renvoie : elle blesse alors les ennemis.

var main
var vel := Vector2.ZERO
var hostile := true
var life := 5.0
var radius := 7.0
var t := 0.0

func _ready() -> void:
	add_to_group("projectiles")
	z_index = 2

func get_rect() -> Rect2:
	return Rect2(global_position - Vector2(radius, radius), Vector2(radius, radius) * 2.0)

func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += vel * delta
	if main.is_solid_at(global_position):
		pop()
		return
	var r := get_rect()
	if hostile:
		var p = main.player
		if not p.dead and p.dash_t <= 0.0 and r.intersects(p.get_rect()):
			var parried: bool = p.receive_hit(global_position, self)
			if not parried:
				pop()
	else:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.dead and r.intersects(e.get_rect()):
				e.take_hit(3, vel.normalized())
				pop()
				return
	queue_redraw()

func parried(_dir: Vector2) -> void:
	hostile = false
	life = 3.0
	vel = -vel * 1.6

func pop() -> void:
	main.spawn_burst(global_position, Color(0.75, 0.9, 1.0) if not hostile else Color(0.85, 0.55, 0.9), 8, 120.0, 0.0)
	queue_free()

func _draw() -> void:
	var c := Color(0.85, 0.45, 0.95) if hostile else Color(0.6, 0.9, 1.0)
	draw_circle(Vector2.ZERO, radius * 2.0, Color(c, 0.18))
	draw_circle(Vector2.ZERO, radius + sin(t * 20.0), c)
	draw_circle(Vector2(-2, -2), radius * 0.4, Color(1, 1, 1, 0.8))

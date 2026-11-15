extends AnimatableBody2D
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
	main.spawn_burst(global_position + size / 2.0, Color(0.6, 0.55, 0.5), 8, 140.0)
	Audio.sfx("hit", 0.1, -4.0)
	if hp <= 0:
		state = "gone"
		remove_from_group("breakables")
		cs.set_deferred("disabled", true)
		main.spawn_burst(global_position + size / 2.0, Color(0.7, 0.6, 0.5), 22, 220.0, 400.0)
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

func _draw() -> void:
	match kind:
		"mover":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.3, 0.26))
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 4)), Color(0.55, 0.5, 0.42))
			for i in 3:
				draw_circle(Vector2(size.x * (0.2 + i * 0.3), size.y * 0.6), 2.5, Color(0.7, 0.85, 1.0, 0.6 + 0.3 * sin(t * 4.0 + i)))
		"breakable":
			if state == "gone":
				return
			var off2 := Vector2(sin(t * 80.0) * 2.0, 0) if st_t > 0.0 else Vector2.ZERO
			var rock := Color(0.42, 0.38, 0.36)
			draw_rect(Rect2(off2, size), rock)
			draw_rect(Rect2(off2, Vector2(size.x, 3)), rock.lightened(0.25))
			var crk := Color(0.95, 0.85, 0.6, 0.55 + 0.25 * sin(t * 3.0))
			draw_line(off2 + Vector2(6, 2), off2 + Vector2(14, 16), crk, 2.0)
			draw_line(off2 + Vector2(14, 16), off2 + Vector2(10, 30), crk, 2.0)
			draw_line(off2 + Vector2(14, 16), off2 + Vector2(26, 22), crk, 2.0)
		"crumble":
			if state == "gone":
				var k := 1.0 - st_t / 3.0
				draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.42, 0.36, 0.15 * k), false, 1.0)
				return
			var off := Vector2(sin(t * 70.0) * 1.5, 0) if state == "shake" else Vector2.ZERO
			var c := Color(0.5, 0.42, 0.36)
			draw_rect(Rect2(off, size), c)
			draw_rect(Rect2(off, Vector2(size.x, 3)), c.lightened(0.2))
			# fissures
			for i in int(size.x / 32.0):
				var x := 16.0 + i * 32.0
				draw_line(off + Vector2(x - 4, 2), off + Vector2(x + 2, size.y * 0.5), Color(0.2, 0.15, 0.12), 1.5)
				draw_line(off + Vector2(x + 2, size.y * 0.5), off + Vector2(x - 2, size.y), Color(0.2, 0.15, 0.12), 1.5)

extends AnimatableBody2D
const DU = preload("res://scripts/draw_util.gd")
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

func _slab(off: Vector2, c: Color, cut: float) -> void:
	# dalle de pierre : dégradé, arête éclairée, ombre dessous, joints entre blocs
	DU.vgrad(self, Rect2(off, size), c.lightened(0.08), c.darkened(0.45))
	draw_rect(Rect2(off, Vector2(size.x, 3)), c.lightened(0.35))
	draw_rect(Rect2(off + Vector2(0, size.y - 3), Vector2(size.x, 3)), c.darkened(0.6))
	var x := cut
	while x < size.x - 4:
		draw_line(off + Vector2(x, 3), off + Vector2(x, size.y - 3), c.darkened(0.55), 1.5)
		draw_line(off + Vector2(x + 1.5, 3), off + Vector2(x + 1.5, size.y - 3), c.lightened(0.15), 1.0)
		x += cut
	for k in int(size.x / 11.0):
		var h := fposmod(sin(k * 12.9898 + size.x) * 43758.5453, 1.0)
		draw_circle(off + Vector2(5 + k * 11 + h * 4, 7 + h * (size.y - 12)), 1.0 + h, c.darkened(0.3))

func _draw() -> void:
	match kind:
		"mover":
			var c := Color(0.36, 0.3, 0.26)
			_slab(Vector2.ZERO, c, 9999.0)
			for k in [6.0, size.x - 6.0]:
				draw_circle(Vector2(k, size.y * 0.5), 2.4, Color(0.25, 0.22, 0.2))
				draw_circle(Vector2(k - 0.6, size.y * 0.5 - 0.6), 1.0, Color(0.8, 0.75, 0.65))
			for i in 3:
				var rc := Vector2(size.x * (0.25 + i * 0.25), size.y * 0.55)
				var a := 0.55 + 0.35 * sin(t * 4.0 + i)
				draw_colored_polygon(DU.diamond(rc, Vector2(3, 4)), Color(0.7, 0.88, 1.0, a))
				DU.glow(self, rc, 10.0, Color(0.6, 0.85, 1.0), a * 0.5)
		"breakable":
			if state == "gone":
				return
			var off2 := Vector2(sin(t * 80.0) * 2.0, 0) if st_t > 0.0 else Vector2.ZERO
			var rock := Color(0.42, 0.38, 0.36)
			_slab(off2, rock, 9999.0)
			var crk := Color(0.95, 0.85, 0.6, 0.55 + 0.25 * sin(t * 3.0))
			DU.glow(self, off2 + Vector2(14, 16), 18.0, Color(1.0, 0.85, 0.5), 0.35 + 0.15 * sin(t * 3.0))
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
			_slab(off, c, 32.0)
			# fissures
			for i in int(size.x / 32.0):
				var x := 16.0 + i * 32.0
				draw_polyline(PackedVector2Array([off + Vector2(x - 4, 3), off + Vector2(x + 2, size.y * 0.5), off + Vector2(x - 2, size.y - 3)]), Color(0.15, 0.1, 0.08), 1.6)
				draw_line(off + Vector2(x + 2, size.y * 0.5), off + Vector2(x + 7, size.y * 0.35), Color(0.15, 0.1, 0.08), 1.0)
			if state == "shake":
				for i in 4:
					var px := fposmod(t * 97.0 + i * 37.0, size.x)
					draw_rect(Rect2(off + Vector2(px, size.y + fposmod(t * 60.0 + i * 9.0, 14.0)), Vector2(2, 2)), c.darkened(0.3))

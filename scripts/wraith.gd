extends "res://scripts/enemy.gd"
# Spectre : fantôme qui disparaît (intouchable), réapparaît près du joueur en scintillant,
# lance une orbe lente puis reste un moment vulnérable. Élite : deux orbes.

var state := "visible"
var state_t := 2.0
var alpha := 1.0

func _ready() -> void:
	size = Vector2(26, 34)
	hp = 3
	geo_value = 4
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 0
	state_t = randf_range(1.0, 2.5)

func is_harmful() -> bool:
	return super.is_harmful() and alpha > 0.8

func take_hit(dmg: int, d: Vector2) -> void:
	if alpha < 0.6:
		return    # intouchable quand il est estompé
	super.take_hit(dmg, d)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	var p = main.player
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2(0, sin(anim_t * 2.0) * 20.0), 400.0 * delta)
	if stun_t <= 0.0 and p and not p.dead:
		match state:
			"visible":
				alpha = move_toward(alpha, 1.0, delta * 3.0)
				if state_t <= 0.0:
					state = "fade"
					state_t = 0.5
			"fade":
				alpha = clampf(state_t / 0.5, 0.0, 1.0)
				if state_t <= 0.0:
					if p.global_position.distance_to(global_position) < 520.0 * aggro():
						var a := randf() * TAU
						var target: Vector2 = p.global_position + Vector2(cos(a) * 170.0, -absf(sin(a)) * 110.0 - 40.0)
						if not main.is_solid_at(target) and not _crosses_gate(target):
							global_position = target
					state = "appear"
					state_t = 0.45
			"appear":
				alpha = 0.3 + 0.5 * absf(sin(anim_t * 20.0))
				if state_t <= 0.0:
					alpha = 1.0
					var dirv: Vector2 = (p.global_position - global_position).normalized()
					main.spawn_projectile(global_position, dirv * 170.0 * spd(), {"kind": "ember", "radius": 9.0, "life": 4.0})
					if elite:
						main.spawn_projectile(global_position, dirv.rotated(0.35) * 170.0 * spd(), {"kind": "ember", "radius": 9.0, "life": 4.0})
					state = "visible"
					state_t = randf_range(1.4, 2.2) / aggro()
	move_and_slide()
	queue_redraw()

# Le spectre ne se téléporte jamais de l'autre côté d'une grille d'arène de boss :
# sinon il suivait le joueur dans la cage du boss.
func _crosses_gate(target: Vector2) -> bool:
	return main.in_arena(global_position) != main.in_arena(target)

func _draw() -> void:
	var c := body_color(Color(0.72, 0.8, 0.96))
	DU.glow(self, Vector2(0, -2), 30.0, Color(0.5, 0.7, 1.0), 0.35 * alpha)
	# voiles qui traînent en plusieurs couches
	for layer in 2:
		var cl := c.darkened(0.25 * (1 - layer))
		cl.a = (0.35 + 0.4 * layer) * alpha
		var sc := 1.0 - layer * 0.12
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI + i * PI / 12.0
			pts.append(Vector2(cos(a) * 14.0 * sc, -5 + sin(a) * 15.0 * sc))
		for i in 6:
			var x := 14.0 * sc - i * 5.6 * sc
			var wave := sin(anim_t * 6.0 + i + layer * 1.7) * 4.0
			pts.append(Vector2(x + wave * 0.4, 14 + layer * -2 + wave + (6.0 if i % 2 == 0 else 0.0)))
		DU.flat(self, pts, cl)
	# capuche et visage creux
	var hood := Color(c.darkened(0.3), 0.85 * alpha)
	draw_arc(Vector2(0, -6), 12.0, PI * 1.05, PI * 1.95, 14, hood, 2.0)
	DU.flat(self, DU.ellipse(Vector2(0, -5), Vector2(8, 6.5)), Color(0.06, 0.08, 0.16, 0.85 * alpha))
	var eye := Color(0.35, 0.95, 1.0, alpha)
	for ex in [-3.2, 3.2]:
		DU.flat(self, DU.ellipse(Vector2(ex, -6), Vector2(1.8, 2.6)), eye)
		DU.glow(self, Vector2(ex, -6), 7.0, Color(0.4, 0.9, 1.0), 0.5 * alpha)
	draw_line(Vector2(-3, -0.5), Vector2(3, -0.5), Color(0.35, 0.95, 1.0, 0.4 * alpha), 1.0)

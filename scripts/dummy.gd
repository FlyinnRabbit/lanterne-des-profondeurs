extends "res://scripts/enemy.gd"
# Mannequin d'entraînement : ne bouge pas, ne blesse pas, ne meurt pas.

var wobble := 0.0
var hits := []        # [temps, dégâts] : dégâts par seconde sur les 5 dernières secondes

func _ready() -> void:
	size = Vector2(28, 44)
	hp = 9999
	show_bar = false
	geo_value = 0
	setup_body()

func is_harmful() -> bool:
	return false

func parried(_d: Vector2) -> void:
	pass

func take_hit(dmg: int, dir: Vector2) -> void:
	flash_t = 0.12
	main.on_damage_dealt(self, dmg)
	hits.append([anim_t, dmg])
	wobble = 1.0 * (signf(dir.x) if dir.x != 0.0 else 1.0)
	main.spawn_burst(global_position, Color(0.85, 0.75, 0.55), 6 + dmg, 140.0)
	hp = 9999

func _physics_process(delta: float) -> void:
	flash_t -= delta
	anim_t += delta
	wobble = move_toward(wobble, 0.0, delta * 3.0)
	while not hits.is_empty() and anim_t - float(hits[0][0]) > 5.0:
		hits.pop_front()
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	velocity.x = 0.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var ang := sin(anim_t * 25.0) * 0.25 * absf(wobble) * signf(wobble)
	draw_set_transform(Vector2(0, 22), ang, Vector2.ONE)
	var wood := Color(0.42, 0.32, 0.24)
	var straw := body_color(Color(0.78, 0.68, 0.45))
	var rope := Color(0.55, 0.42, 0.28)
	# poteau et traverse
	draw_line(Vector2(0, 2), Vector2(0, -44), wood.darkened(0.4), 5.5)
	draw_line(Vector2(-0.8, 2), Vector2(-0.8, -44), wood, 3.4)
	draw_line(Vector2(-15, -30), Vector2(15, -30), wood.darkened(0.4), 4.0)
	draw_line(Vector2(-15, -30.6), Vector2(15, -30.6), wood, 2.2)
	# corps de paille ficelé, brins qui dépassent
	DU.poly(self, DU.ellipse(Vector2(0, -26), Vector2(11, 12), 20), straw)
	for k in 7:
		var a := -PI * 0.2 + k * 0.45
		var p := Vector2(0, -26) + Vector2(cos(a) * 10.0, sin(a) * 11.0)
		draw_line(p, p + Vector2(cos(a), sin(a)) * 3.5, straw.darkened(0.2), 1.0)
	for yy in [-33.0, -20.0]:
		draw_line(Vector2(-10, yy), Vector2(10, yy + 1.5), rope, 1.8)
	# tête-sac cousue, yeux en croix, rapiéçage
	DU.ball(self, Vector2(0, -44), 8.5, straw.lightened(0.05))
	DU.box(self, Rect2(2, -50, 5, 4), Color(0.55, 0.4, 0.3))
	draw_line(Vector2(-6, -38), Vector2(6, -38), rope, 1.6)
	for k in [-1.0, 1.0]:
		var e := Vector2(k * 3.2 - 0.5, -45)
		draw_line(e + Vector2(-1.6, -1.6), e + Vector2(1.6, 1.6), Color(0.2, 0.15, 0.1), 1.6)
		draw_line(e + Vector2(1.6, -1.6), e + Vector2(-1.6, 1.6), Color(0.2, 0.15, 0.1), 1.6)
	for k in 4:
		draw_line(Vector2(-3 + k * 2, -41), Vector2(-3 + k * 2, -40), Color(0.2, 0.15, 0.1), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not hits.is_empty():
		var total := 0
		for h in hits:
			total += int(h[1])
		var span := maxf(anim_t - float(hits[0][0]), 1.0)
		var f := ThemeDB.fallback_font
		var txt := tr("%.1f dégâts/s") % (total / span)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(f, Vector2(-tw / 2.0, -42), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.6))

extends "res://scripts/enemy.gd"
# Tisseuse : araignée accrochée au plafond par un fil. Elle se laisse tomber quand le joueur
# passe dessous, puis le poursuit au sol. Élite : tombe plus tôt et court plus vite.

var anchor := Vector2.ZERO
var hanging := true
var dir := -1.0

func _ready() -> void:
	size = Vector2(28, 20)
	hp = 3
	geo_value = 4
	setup_body()
	if display:
		return
	# cherche le plafond au-dessus d'elle et s'y accroche
	var y := global_position.y
	for i in 12:
		if main.is_solid_at(Vector2(global_position.x, y - 32.0)):
			break
		y -= 32.0
	anchor = Vector2(global_position.x, floorf(y / 32.0) * 32.0)
	global_position.y = anchor.y + 30.0
	anim_t = randf() * 5.0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	if hanging:
		global_position.y = anchor.y + 30.0 + sin(anim_t * 2.0) * 4.0
		if p and not p.dead and absf(p.global_position.x - global_position.x) < (110.0 if elite else 70.0) * aggro() and p.global_position.y > global_position.y:
			hanging = false
			main.spawn_burst(global_position, Color(0.85, 0.85, 0.9), 6, 80.0)
		if knock.length() > 10.0 or hp < 3:
			hanging = false
		queue_redraw()
		return
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
	elif p and not p.dead and is_on_floor():
		dir = -1.0 if p.global_position.x < global_position.x else 1.0
		velocity.x = dir * 115.0 * spd()
		if is_on_wall():
			velocity.y = -420.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	if hanging:
		draw_line(Vector2(0, -10), Vector2(0, -26) if display else anchor - global_position, Color(0.85, 0.85, 0.95, 0.6), 1.0)
	var body := body_color(Color(0.24, 0.21, 0.3))
	var walk := sin(anim_t * (18.0 if absf(velocity.x) > 5.0 else 3.0)) * 3.0
	# huit pattes à trois segments, les plus lointaines plus sombres
	for k in [-1.0, 1.0]:
		for i in 4:
			var bx: float = k * (3 + i * 2.5)
			var kx: float = k * (13 + i * 4)
			var ky := -8.0 + i * 3.0 + (walk if i % 2 == 0 else -walk)
			var col := body.darkened(0.25 if i % 2 == 0 else 0.0)
			draw_line(Vector2(bx, -2), Vector2(kx, ky - 6), col, 2.2)
			draw_line(Vector2(kx, ky - 6), Vector2(kx + k * 4, ky + 4), col, 1.8)
			draw_line(Vector2(kx + k * 4, ky + 4), Vector2(kx + k * 5, ky + 10), col, 1.2)
			draw_circle(Vector2(kx, ky - 6), 1.3, col.lightened(0.15))
	# abdomen à motif en sablier
	DU.poly(self, DU.ellipse(Vector2(0, 2), Vector2(11, 10), 22), body)
	DU.flat(self, PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(0, 2), Vector2(3, 6), Vector2(-3, 6), Vector2(0, 2)]), Color(0.85, 0.2, 0.25))
	for i in 6:
		var a := i * TAU / 6.0
		draw_line(Vector2(cos(a) * 9.0, 2 + sin(a) * 8.0), Vector2(cos(a) * 11.5, 2 + sin(a) * 10.0), body.lightened(0.2), 0.8)
	# céphalothorax, crochets, grappe d'yeux
	DU.poly(self, DU.ellipse(Vector2(0, -10), Vector2(7, 6), 18), body.lightened(0.05))
	for k in [-1.0, 1.0]:
		draw_line(Vector2(k * 2, -6), Vector2(k * 3, -2), Color(0.75, 0.7, 0.6), 1.6)
	for i in 4:
		draw_circle(Vector2(-4.5 + i * 3, -12 + (i % 2)), 1.4, Color(1.0, 0.3, 0.3))
	draw_circle(Vector2(-1.5, -14.5), 1.0, Color(1.0, 0.45, 0.4))
	draw_circle(Vector2(1.5, -14.5), 1.0, Color(1.0, 0.45, 0.4))
	DU.glow(self, Vector2(0, -12), 9.0, Color(1, 0.3, 0.3), 0.3)

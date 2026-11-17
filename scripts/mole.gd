extends "res://scripts/enemy.gd"
# Taupe fouisseuse : creuse sous le sol (on ne voit qu'un monticule de terre qui avance et une
# traînée de poussière), se glisse sous le héros, puis jaillit. Avant de sortir, le sol se
# fissure, tremble et crache de la terre (avec le « ! ») : comme le Ver, on a le temps de s'écarter.
# Une fois sortie, elle reste exposée un moment : c'est là qu'il faut frapper. Sous terre,
# elle est intouchable.
# Élite : projette deux cailloux en sortant.

var state := "under"     # under / windup / burst / exposed / dig
var state_t := 0.0
var dir := -1.0
var trail_t := 0.0
var cd := 1.0

func _ready() -> void:
	size = Vector2(30, 24)
	hp = 4
	geo_value = 5
	setup_body()
	floor_snap_length = 8.0
	if display:
		state = "exposed"
	state_t = randf_range(0.0, 1.0)

func is_harmful() -> bool:
	return state in ["burst", "exposed"] and not dead and stun_t <= 0.0

func take_hit(dmg: int, d: Vector2) -> void:
	if state in ["under", "windup"]:
		# intouchable sous terre : la terre gicle, rien de plus
		main.spawn_burst(global_position + Vector2(0, 8), Color(0.45, 0.35, 0.25), 5, 100.0)
		return
	super.take_hit(dmg, d)

func _go(s: String, t: float) -> void:
	state = s
	state_t = t

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	cd -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	var alive_p: bool = p != null and not p.dead
	match state:
		"under":
			velocity.x = 0.0
			if alive_p and cd <= 0.0:
				var d: Vector2 = p.global_position - global_position
				if absf(d.x) < 420.0 * aggro() and absf(d.y) < 70.0:
					dir = signf(d.x) if d.x != 0.0 else dir
					if absf(d.x) < 14.0:
						_go("windup", 0.7 / sqrt(aggro()))
						Audio.sfx("door", 0.15, -4.0)
					elif is_on_floor() and main.is_solid_at(global_position + Vector2(dir * 18.0, size.y / 2.0 + 8.0)):
						velocity.x = dir * 120.0 * spd()
				trail_t -= delta
				if trail_t <= 0.0 and absf(velocity.x) > 1.0:
					trail_t = 0.14
					main.spawn_burst(global_position + Vector2(-dir * 6.0, size.y / 2.0 - 2.0), Color(0.45, 0.35, 0.25), 3, 60.0, 300.0)
		"windup":
			velocity.x = 0.0
			if fmod(anim_t, 0.12) < 0.02:
				main.spawn_burst(global_position + Vector2(randf_range(-12, 12), size.y / 2.0 - 2.0), Color(0.5, 0.4, 0.3), 2, 90.0, 400.0)
			if state_t <= 0.0:
				_go("burst", 0.3)
				main.shake(5)
				Audio.sfx("hammer", 0.1, -2.0)
				main.spawn_burst(global_position + Vector2(0, size.y / 2.0), Color(0.5, 0.4, 0.3), 16, 220.0, 500.0)
				# la sortie projette le héros qui était dessus
				if alive_p and p.dash_t <= 0.0 and Rect2(global_position + Vector2(-18, -50), Vector2(36, 62)).intersects(p.get_rect()):
					p.receive_hit(global_position + Vector2(0, 20), self)
				if elite:
					for s in [-1.0, 1.0]:
						main.spawn_projectile(global_position + Vector2(s * 8.0, -10.0), Vector2(s * 160.0, -420.0), {"kind": "rock", "radius": 6.0, "gravity": 900.0, "life": 2.5})
		"burst":
			velocity.x = 0.0
			if state_t <= 0.0:
				_go("exposed", 1.5)
		"exposed":
			if absf(knock.x) > 10.0:
				velocity.x = knock.x
				knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
			else:
				velocity.x = 0.0
			if state_t <= 0.0 and stun_t <= 0.0:
				_go("dig", 0.45)
				Audio.sfx("door", 0.2, -10.0)
		"dig":
			velocity.x = 0.0
			if state_t <= 0.0:
				_go("under", 0.0)
				cd = 0.9
	move_and_slide()
	queue_redraw()

func telegraph() -> int:
	return 1 if state == "windup" and stun_t <= 0.0 else 0

func fx_color() -> Color:
	return Color(0.4, 0.32, 0.3)

func _draw() -> void:
	var gy := size.y / 2.0       # niveau du sol
	var dirt := Color(0.42, 0.32, 0.22)
	if state == "under" or state == "windup":
		# monticule de terre qui avance, mottes, et fissures pendant la préparation
		var bump := 1.0 + (0.25 * sin(anim_t * 40.0) if state == "windup" else 0.0)
		DU.poly(self, DU.ellipse(Vector2(0, gy), Vector2(16, 7) * bump, 14, PI, TAU), dirt)
		for i in 3:
			DU.ball(self, Vector2(-8 + i * 8, gy - 4 - (i % 2) * 2), 2.4, dirt.lightened(0.15))
		if state == "windup":
			var k := 1.0 - clampf(state_t / 0.7, 0.0, 1.0)
			for s in [-1.0, 1.0]:
				var pts := PackedVector2Array([Vector2(s * 4.0, gy), Vector2(s * 12.0, gy - 1.5), Vector2(s * (16.0 + 10.0 * k), gy + 0.5), Vector2(s * (24.0 + 14.0 * k), gy - 1.0)])
				draw_polyline(pts, Color(0.12, 0.08, 0.05), 1.6)
			DU.glow(self, Vector2(0, gy - 4), 22.0, Color(0.9, 0.6, 0.3), 0.25 * k)
		return
	# sortie : la taupe émerge (plus haute pendant le jaillissement)
	var rise := 1.0
	match state:
		"burst": rise = 1.0 - clampf(state_t / 0.3, 0.0, 1.0) * 0.4 + 0.15
		"dig": rise = clampf(state_t / 0.45, 0.0, 1.0)
	var oy := gy - (gy + 10.0) * rise
	var fur := body_color(Color(0.28, 0.24, 0.26))
	var pink := body_color(Color(0.95, 0.6, 0.62))
	# trou et terre retournée
	DU.poly(self, DU.ellipse(Vector2(0, gy), Vector2(18, 5)), Color(0.12, 0.08, 0.06))
	for i in 4:
		DU.ball(self, Vector2(-15 + i * 10, gy - 2), 3.0, dirt)
	# corps velu en poire, grosses pattes-pelles roses
	var body := DU.ellipse(Vector2(0, oy + 8), Vector2(12, 14))
	DU.poly(self, body, fur)
	for s in [-1.0, 1.0]:
		var paw := Vector2(s * 13.0, oy + 10.0)
		DU.poly(self, DU.ellipse(paw, Vector2(5, 4)), pink)
		for k in 3:
			draw_line(paw + Vector2(s * 2.0, -2 + k * 2), paw + Vector2(s * 7.0, -3 + k * 2.5), Color(0.95, 0.9, 0.8), 1.2)
	# museau rose, petits yeux plissés
	DU.ball(self, Vector2(0, oy - 1), 4.0, pink)
	draw_circle(Vector2(-1, oy - 2), 1.0, Color(1, 1, 1, 0.6))
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 4.0, oy - 6), Vector2(s * 7.0, oy - 6.5), Color(0.05, 0.03, 0.03), 1.4)
		for k in 2:
			draw_line(Vector2(s * 3.0, oy + k), Vector2(s * 9.0, oy - 1 + k * 2), Color(0.85, 0.8, 0.75, 0.7), 0.6)
	if state == "exposed" and stun_t <= 0.0 and state_t < 0.4:
		# elle s'apprête à replonger
		DU.glow(self, Vector2(0, oy + 8), 18.0, Color(0.9, 0.7, 0.4), 0.2)
	draw_stun(oy - 16.0)

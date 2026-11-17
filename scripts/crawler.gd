extends "res://scripts/enemy.gd"
# Rampant : petit scarabée à carapace pâle qui patrouille et fait demi-tour au bord du vide.
# Quand il voit le héros, il se ramasse (clignote) puis charge ; l'élite enchaîne deux ruées.

const SPEED := 70.0
var dir := -1
var lunge_t := 0.0     # ruée vers le joueur
var lunge_cd := 0.0
var windup_t := 0.0
var combo := 0       # élite : ruées restantes à enchaîner

func _ready() -> void:
	size = Vector2(30, 22)
	hp = 3
	geo_value = 3
	setup_body()
	floor_snap_length = 6.0

func _physics_process(delta: float) -> void:
	flash_t -= delta
	stun_t -= delta
	if stun_t <= 0.0:
		anim_t += delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity.x = 0.0
	elif windup_t > 0.0:
		windup_t -= delta
		velocity.x = 0.0
		if windup_t <= 0.0:
			lunge_t = 0.45
	elif lunge_t > 0.0:
		lunge_t -= delta
		velocity.x = dir * SPEED * (4.0 if not elite else 4.8) * spd()
		# au bord du vide, il pile net au lieu de s'y jeter
		var ah := global_position + Vector2(dir * (size.x / 2.0 + 4.0), size.y / 2.0 + 8.0)
		if is_on_floor() and not main.is_solid_at(ah):
			lunge_t = 0.0
			velocity.x = 0.0
		if lunge_t <= 0.0 and combo > 0:
			combo -= 1
			var p2 = main.player
			if p2 and not p2.dead:
				dir = -1 if p2.global_position.x < global_position.x else 1
			windup_t = 0.25
	else:
		knock = Vector2.ZERO
		lunge_cd -= delta
		var p = main.player
		# repère le héros devant lui (ou tout près derrière), se ramasse puis charge tête baissée.
		# Élite : charge plus tôt, plus loin, et enchaîne une seconde ruée.
		if lunge_cd <= 0.0 and p and not p.dead and is_on_floor() and absf(p.global_position.y - global_position.y) < 50.0:
			var dxp: float = p.global_position.x - global_position.x
			var seen := (signf(dxp) == dir and absf(dxp) < (200.0 if not elite else 250.0) * aggro()) or absf(dxp) < 70.0
			if seen and not main.wall_between(global_position, p.global_position):
				dir = -1 if dxp < 0.0 else 1
				windup_t = 0.5 if not elite else 0.35
				lunge_cd = (2.6 if not elite else 2.0) / aggro()
				combo = 1 if elite else 0
				flash_t = 0.1
		velocity.x = dir * SPEED * spd()
		if is_on_floor():
			var ahead := global_position + Vector2(dir * (size.x / 2.0 + 4.0), size.y / 2.0 + 8.0)
			if not main.is_solid_at(ahead):
				dir = -dir
	move_and_slide()
	if is_on_wall() and knock == Vector2.ZERO:
		dir = -dir
	queue_redraw()

func _draw() -> void:
	var f := float(dir)
	var leg_a := sin(anim_t * 14.0) * 2.5
	var dark := body_color(Color(0.13, 0.1, 0.15))
	var shell_c := body_color(Color(0.62, 0.56, 0.72))
	if windup_t > 0.0 and fmod(anim_t, 0.1) < 0.05:
		shell_c = Color(1.0, 0.8, 0.6)
	# pattes du fond puis de devant
	for side in [0, 1]:
		for i in 3:
			var lx := -9.0 + i * 8.0
			var sw := (leg_a if (i + side) % 2 == 0 else -leg_a)
			var col := dark.darkened(0.35) if side == 0 else dark
			leg(Vector2(lx, 5), Vector2(lx - f * 3 + sw * 0.4, 7 - side), Vector2(lx + sw - f * 1, 11), col, 2.0)
	# tête, mandibules et antennes
	var hd := Vector2(f * 14, 3)
	draw_line(hd + Vector2(f * 2, -3), hd + Vector2(f * 9, -11 + sin(anim_t * 5.0) * 1.5), dark, 1.2)
	draw_line(hd + Vector2(f * 1, -4), hd + Vector2(f * 6, -12 - sin(anim_t * 4.0) * 1.5), dark, 1.0)
	DU.poly(self, DU.ellipse(hd, Vector2(5.5, 4.6)), body_color(Color(0.2, 0.16, 0.22)))
	draw_line(hd + Vector2(f * 4, 2), hd + Vector2(f * 8, 4), Color(0.75, 0.7, 0.6), 1.4)
	# carapace en dôme : plaques, couture centrale, reflets
	var shell := DU.ellipse(Vector2(0, 6), Vector2(16, 15), 22, PI, TAU)
	DU.poly(self, shell, shell_c)
	for i in 3:
		draw_arc(Vector2(0, 6), 5.0 + i * 4.0, PI + 0.25, TAU - 0.25, 12, shell_c.darkened(0.4), 1.1)
	draw_line(Vector2(-f * 1, -8.5), Vector2(-f * 1, 6), shell_c.darkened(0.45), 1.2)
	draw_line(Vector2(-16, 6), Vector2(16, 6), shell_c.darkened(0.55), 2.0)
	draw_arc(Vector2(-3, 5), 11.0, PI + 0.6, PI + 1.3, 8, Color(1, 1, 1, 0.35), 1.6)
	# œil
	var eye := Color(1.0, 0.55, 0.3) if stun_t <= 0.0 else Color(0.4, 0.4, 0.4)
	draw_circle(hd + Vector2(f * 2.5, -1), 3.5, Color(eye, 0.25))
	draw_circle(hd + Vector2(f * 2.5, -1), 1.8, eye)
	draw_stun(-16.0)

extends "res://scripts/enemy.gd"
# Mimique : fausse cachette au trésor, identique aux vraies… à un détail près (le couvercle a
# un petit tic de temps en temps). Quand le héros s'approche — ou la frappe — elle se réveille,
# claque des mâchoires puis sautille vers lui en mordant. Battue, elle lâche un beau butin.
# Élite : plus rapide, morsures plus fréquentes.

var state := "sleep"     # sleep / windup_wake / hop
var state_t := 0.0
var dir := -1.0
var hop_cd := 0.0
var tic_t := 0.0

func _ready() -> void:
	size = Vector2(28, 22)
	hp = 6
	geo_value = 14
	show_bar = false
	setup_body()
	if display:
		state = "hop"
	floor_snap_length = 6.0
	tic_t = randf_range(2.0, 5.0)

func is_harmful() -> bool:
	return state == "hop" and not dead and stun_t <= 0.0

func take_hit(dmg: int, d: Vector2) -> void:
	if state == "sleep":
		_wake()
	super.take_hit(dmg, d)

func _wake() -> void:
	state = "windup_wake"
	state_t = 0.5
	Audio.sfx("hammer", 0.2, -6.0)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	hop_cd -= delta
	tic_t -= delta
	if tic_t < -0.25:
		tic_t = randf_range(3.0, 6.0)
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	match state:
		"sleep":
			velocity.x = 0.0
			if p and not p.dead and p.global_position.distance_to(global_position) < 72.0:
				_wake()
		"windup_wake":
			velocity.x = 0.0
			if state_t <= 0.0:
				state = "hop"
				hop_cd = 0.1
		"hop":
			if absf(knock.x) > 10.0:
				velocity.x = knock.x
				knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
			elif stun_t > 0.0:
				knock = Vector2.ZERO
				velocity.x = 0.0
			elif is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
				if hop_cd <= 0.0 and p and not p.dead:
					dir = signf(p.global_position.x - global_position.x) if p.global_position.x != global_position.x else dir
					velocity = Vector2(dir * 210.0 * spd(), -380.0)
					hop_cd = (0.75 if not elite else 0.55) / aggro()
					Audio.sfx("hit", 0.25, -12.0)
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(0.55, 0.38, 0.22)

func _draw() -> void:
	var wood := body_color(Color(0.45, 0.3, 0.18))
	var gold := Color(0.85, 0.7, 0.3) if flash_t <= 0.0 else Color(1, 1, 1)
	if state == "sleep":
		# exactement comme une cachette… sauf le tic du couvercle
		var lift := 2.5 if tic_t < 0.0 else 0.0
		DU.box(self, Rect2(-14, -7, 28, 18), wood)
		DU.poly(self, DU.ellipse(Vector2(0, -7 - lift), Vector2(14, 7), 12, PI, TAU), wood.lightened(0.1))
		DU.box(self, Rect2(-14, -1, 28, 3), gold)
		DU.box(self, Rect2(-3, -5 - lift, 6, 7), Color(0.95, 0.8, 0.35))
		if lift > 0.0:
			draw_line(Vector2(-10, -7), Vector2(10, -7), Color(0.05, 0.02, 0.02), 1.5)
		DU.ball(self, Vector2(0, -1), 18.0 + sin(anim_t * 3.0) * 2.0, Color(1.0, 0.85, 0.4, 0.12))
		return
	var f := dir
	var open := 0.35 + 0.35 * absf(sin(anim_t * (14.0 if state == "windup_wake" else 7.0)))
	# petites pattes griffues
	var step := sin(anim_t * 14.0) * 2.0 if not is_on_floor() else 0.0
	for lx in [-9.0, -3.0, 4.0, 10.0]:
		draw_line(Vector2(lx, 9), Vector2(lx + step, 14), Color(0.25, 0.16, 0.12), 2.2)
	# caisse : base, ferrure, bouche ouverte (langue, dents), couvercle relevé
	DU.box(self, Rect2(-14, -4, 28, 14), wood)
	DU.box(self, Rect2(-14, 1, 28, 3), gold)
	var hinge := Vector2(-f * 14.0, -4.0)
	var lid_a := -open * 0.9 * f
	var dome: PackedVector2Array = DU.ellipse(Vector2(0, -4), Vector2(14, 7), 12, PI, TAU)
	var lid := PackedVector2Array()
	for q in dome:
		lid.append(hinge + (q - hinge).rotated(lid_a))
	var front := hinge + (Vector2(f * 14.0, -4.0) - hinge).rotated(lid_a)
	# gueule : intérieur sombre, langue, dents du bas et du haut
	DU.flat(self, PackedVector2Array([hinge, Vector2(f * 14.0, -4.0), front]), Color(0.3, 0.05, 0.08))
	DU.flat(self, PackedVector2Array([Vector2(-f * 4.0, -4), Vector2(f * 10.0, -4), Vector2(f * 6.0, -8.0 - open * 5.0)]), Color(0.85, 0.3, 0.4))
	for i in 4:
		var u := 0.2 + i * 0.22
		var bp := hinge.lerp(Vector2(f * 14.0, -4.0), u)
		DU.flat(self, PackedVector2Array([bp - Vector2(2, 0), bp + Vector2(2, 0), bp + Vector2(0, -4)]), Color(0.95, 0.93, 0.85))
		var tp := hinge.lerp(front, u)
		var nrm := (front - hinge).normalized().orthogonal() * f
		DU.flat(self, PackedVector2Array([tp - (front - hinge).normalized() * 2.0, tp + (front - hinge).normalized() * 2.0, tp - nrm * 4.0]), Color(0.95, 0.93, 0.85))
	DU.poly(self, lid, wood.lightened(0.1))
	draw_polyline(lid, gold, 1.4)
	# yeux qui luisent sous le couvercle
	var ec := Color(1.0, 0.75, 0.2) if not elite else Color(1.0, 0.35, 0.25)
	for s in [-1.0, 1.0]:
		var ep := hinge.lerp(front, 0.55 + s * 0.15) + Vector2(0, -5.0).rotated(lid_a)
		draw_circle(ep, 1.8, ec)
		DU.glow(self, ep, 6.0, ec, 0.5)
	draw_stun(-24.0)

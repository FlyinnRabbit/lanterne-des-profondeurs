extends "res://scripts/enemy.gd"
# Tortue de cristal (Mines de Cristal) : carapace de cristal qui renvoie les coups portés de
# face (aucun dégât). Il faut la frapper par-derrière, par-dessus (piqué), ou la retourner d'une
# parade. Elle charge carapace en avant. Élite : charge plus longue.

var dir := -1.0
var windup := 0.0
var charge_t := 0.0
var charge_cd := 2.0
var flipped_t := 0.0   # retournée : vulnérable de partout

func _ready() -> void:
	size = Vector2(38, 24)
	hp = 4
	geo_value = 5
	knock_resist = 0.4
	setup_body()

func telegraph() -> int:
	return 1 if windup > 0.0 and stun_t <= 0.0 else 0

func parried(d: Vector2) -> void:
	super.parried(d)
	flipped_t = 2.2

func take_hit(dmg: int, d: Vector2) -> void:
	var p = main.player
	var from_front: bool = p != null and signf(p.global_position.x - global_position.x) == dir
	var from_above: bool = d.y > 0.5 or (p != null and p.global_position.y < global_position.y - 20.0 * reach)
	if flipped_t <= 0.0 and stun_t <= 0.0 and from_front and not from_above:
		# la carapace encaisse : étincelles et petit recul pour le héros
		flash_t = 0.06
		main.spawn_burst(global_position + Vector2(dir * 18.0, -4), main.pal.get("moss", Color(0.6, 0.9, 1.0)), 8, 160.0)
		Audio.sfx("parry", 0.1, -8.0)
		if p:
			p.recoil_t = 0.12
			p.recoil_vx = signf(p.global_position.x - global_position.x) * 260.0
		return
	super.take_hit(dmg, d)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	flipped_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0 or flipped_t > 0.0:
		velocity.x = 0.0
		windup = 0.0
		charge_t = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity.x = 0.0
		if windup <= 0.0:
			charge_t = 0.7 if not elite else 1.0
	elif charge_t > 0.0:
		charge_t -= delta
		velocity.x = dir * 260.0 * spd()
		if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 22.0, size.y / 2.0 + 8.0)):
			charge_t = 0.0
	else:
		knock = Vector2.ZERO
		charge_cd -= delta
		var near: bool = p and not p.dead and absf(p.global_position.y - global_position.y) < 50.0 * reach and absf(p.global_position.x - global_position.x) < 260.0 * aggro()
		if near:
			dir = -1.0 if p.global_position.x < global_position.x else 1.0
			if charge_cd <= 0.0:
				windup = 0.5
				charge_cd = 2.6 / aggro()
		velocity.x = dir * 30.0 * spd()
		if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 22.0, size.y / 2.0 + 8.0)):
			dir = -dir
	move_and_slide()
	if is_on_wall():
		dir = -dir
		charge_t = 0.0
	queue_redraw()

func fx_color() -> Color:
	return main.pal.get("moss", Color(0.6, 0.9, 1.0)) if main else Color(0.6, 0.9, 1.0)

func _draw() -> void:
	var f := dir
	var crys: Color = main.pal.get("moss", Color(0.55, 0.9, 1.0)) if main else Color(0.55, 0.9, 1.0)
	var skin := body_color(Color(0.35, 0.42, 0.35))
	var flip := flipped_t > 0.0
	var oy := -2.0 if not flip else 6.0
	if flip:
		# sur le dos : pattes qui gigotent
		for i in 4:
			var lx := -12 + i * 8
			draw_line(Vector2(lx, -2), Vector2(lx + sin(anim_t * 20.0 + i) * 3, -10), skin, 2.4)
	else:
		for i in 4:
			var lx := -12 + i * 8
			draw_line(Vector2(lx, 6), Vector2(lx + sin(anim_t * 10.0 + i) * 2, 12), skin, 2.6)
		# tête
		DU.flat(self, DU.ellipse(Vector2(f * 20, 4), Vector2(6, 5)), skin)
		draw_circle(Vector2(f * 22, 3), 1.4, Color(0.05, 0.05, 0.05))
	# carapace de cristaux (plus brillante à l'avant : c'est là qu'elle bloque)
	var sh := PackedVector2Array()
	for i in 9:
		var a := PI + i * PI / 8.0
		sh.append(Vector2(cos(a) * 18, oy + sin(a) * (14 if not flip else -10)))
	DU.flat(self, sh, body_color(crys.darkened(0.35)))
	for i in 4:
		var bx := -12.0 + i * 8.0
		var hh := 10.0 + (i % 2) * 4.0
		var cc := crys.lightened(0.1 if signf(bx) == f else -0.1)
		var up := -1.0 if not flip else 1.0
		DU.flat(self, PackedVector2Array([Vector2(bx - 4, oy - 4 * up * -1), Vector2(bx, oy + up * hh), Vector2(bx + 4, oy)]), body_color(cc))
	if windup > 0.0:
		DU.glow(self, Vector2(f * 14, -6), 20.0, crys, 0.5)
	draw_stun(-24.0)

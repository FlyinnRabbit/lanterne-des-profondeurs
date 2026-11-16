extends "res://scripts/enemy.gd"
# Lancier : soldat-insecte armé d'une lance. Il s'approche, se met en garde (annonce)
# puis porte un estoc long qui touche loin devant lui. Parer l'estoc l'étourdit.

var dir := -1.0
var state := "walk"
var state_t := 0.0
var cd := 1.0

func _ready() -> void:
	size = Vector2(28, 40)
	hp = 4
	geo_value = 5
	setup_body()
	floor_snap_length = 6.0

# Pendant l'estoc, la lance prolonge la zone dangereuse
func telegraph() -> int:
	return 2 if state == "windup" and stun_t <= 0.0 else 0

func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if state == "thrust":
		r = r.merge(Rect2(global_position + Vector2(dir * 14.0 - (76.0 if dir < 0 else 0.0), -14), Vector2(76, 12)))   # coup haut : on l'esquive accroupi
	return r

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	cd -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
		state = "walk"
	elif stun_t > 0.0:
		velocity.x = 0.0
		state = "walk"
	else:
		match state:
			"walk":
				velocity.x = 0.0
				if p and not p.dead:
					var d: Vector2 = p.global_position - global_position
					if absf(d.x) < 420.0 * aggro() and absf(d.y) < 120.0:
						dir = signf(d.x) if d.x != 0.0 else dir
						if absf(d.x) < 120.0 and cd <= 0.0 and not main.wall_between(global_position, p.global_position):
							state = "windup"
							state_t = (0.4 if elite else 0.55) / sqrt(aggro())
						elif absf(d.x) > 70.0:
							velocity.x = dir * 75.0 * spd()
					if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 20.0, size.y / 2.0 + 8.0)):
						velocity.x = 0.0
			"windup":
				velocity.x = -dir * 15.0
				if state_t <= 0.0:
					state = "thrust"
					state_t = 0.25
					Audio.sfx("slash", 0.1, -2.0)
			"thrust":
				velocity.x = dir * 160.0 * spd()
				if state_t <= 0.0:
					state = "walk"
					cd = 1.3 / aggro()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var f := dir
	var tele := state == "windup"
	var armor := Color(0.36, 0.44, 0.4)
	if tele and fmod(anim_t, 0.12) < 0.06:
		armor = Color(1.0, 0.75, 0.5)
	armor = body_color(armor)
	var dark := body_color(Color(0.1, 0.12, 0.11))
	var cloth := body_color(Color(0.5, 0.17, 0.16))
	var moving := absf(velocity.x) > 5.0
	var step := sin(anim_t * 10.0) * 3.0 if moving else 0.0
	var lean := f * (3.0 if state == "thrust" else (-2.0 if tele else 0.0))
	# jambes fines d'insecte à genouillères
	for k in [-1.0, 1.0]:
		var hip := Vector2(k * 4 + lean * 0.3, 6)
		var knee := Vector2(k * 4 + f * 3 + step * k * 0.5, 13)
		var foot := Vector2(k * 4 + step * k, 20)
		var col := dark if k > 0 else dark.darkened(0.35)
		leg(hip, knee, foot, col, 2.6)
		draw_circle(knee, 2.2, armor.darkened(0.2))
		draw_line(foot, foot + Vector2(f * 4, 0), col, 1.8)
	# cape qui flotte derrière
	var flow := sin(anim_t * 4.0) * 2.0
	DU.poly(self, PackedVector2Array([Vector2(-f * 3 + lean, -12), Vector2(-f * 16, 6 + flow), Vector2(-f * 13, 13 + flow), Vector2(-f * 7, 9), Vector2(-f * 3, 10)]), cloth.darkened(0.2))
	# abdomen sous le tabard
	DU.poly(self, DU.ellipse(Vector2(-f * 2, 3), Vector2(8, 7), 18), dark.lightened(0.1))
	# torse en armure segmentée (taille fine)
	var torso := PackedVector2Array([Vector2(-8 + lean, -14), Vector2(8 + lean, -14), Vector2(6 + lean * 0.6, -3), Vector2(3, 2), Vector2(-3, 2), Vector2(-6 + lean * 0.6, -3)])
	DU.poly(self, torso, armor)
	for yy in [-10.0, -6.0]:
		draw_line(Vector2(-6.5 + lean * 0.8, yy), Vector2(6.5 + lean * 0.8, yy), armor.darkened(0.45), 1.0)
	# tabard rouge à liseré doré
	var tab := PackedVector2Array([Vector2(-3 + lean * 0.5, -3), Vector2(3 + lean * 0.5, -3), Vector2(4, 10), Vector2(0, 12), Vector2(-4, 10)])
	DU.poly(self, tab, cloth)
	draw_polyline(PackedVector2Array([Vector2(-4, 10), Vector2(0, 12), Vector2(4, 10)]), Color(0.9, 0.75, 0.35), 1.2)
	draw_line(Vector2(-7 + lean * 0.6, -2), Vector2(7 + lean * 0.6, -2), Color(0.35, 0.25, 0.15), 2.2)
	# épaulière
	DU.poly(self, DU.ellipse(Vector2(-f * 5 + lean, -13), Vector2(5, 3.5), 14), armor.lightened(0.1))
	# tête casquée à crête et visière
	var hd := Vector2(f * 3 + lean, -21)
	DU.poly(self, PackedVector2Array([hd + Vector2(-f * 6, 5), hd + Vector2(-f * 7, -3), hd + Vector2(-f * 3, -7), hd + Vector2(f * 4, -6), hd + Vector2(f * 8, 0), hd + Vector2(f * 6, 5)]), armor.darkened(0.1))
	var crest := PackedVector2Array([hd + Vector2(-f * 3, -6), hd + Vector2(f * 3, -7), hd + Vector2(-f * 6, -16 + sin(anim_t * 3.0)), hd + Vector2(-f * 14, -11 + sin(anim_t * 3.0 + 0.5) * 1.5)])
	DU.poly(self, crest, cloth.lightened(0.1))
	draw_line(hd + Vector2(-f * 1, -1), hd + Vector2(f * 8, -1), Color(0.03, 0.03, 0.04), 3.0)
	var eye := Color(1.0, 0.6, 0.3) if not tele else Color(1, 1, 0.7)
	draw_line(hd + Vector2(f * 2, -1), hd + Vector2(f * 7, -1), eye, 1.4)
	DU.glow(self, hd + Vector2(f * 5, -1), 8.0, eye, 0.45)
	# antennes
	draw_line(hd + Vector2(f * 2, -6), hd + Vector2(f * 9, -13 + sin(anim_t * 4.0)), dark, 1.0)
	# lance tenue à deux mains : en arrière pendant l'annonce, tendue pendant l'estoc
	var hand := Vector2(f * 9 + lean, -7)
	var back := -16.0 if tele else 0.0
	var reach := 76.0 if state == "thrust" else 34.0
	var a := hand + Vector2(f * back, 0)
	var b := a + Vector2(f * reach, 0)
	draw_line(a - Vector2(f * 18, 0), b, Color(0.3, 0.2, 0.12), 3.6)
	draw_line(a - Vector2(f * 18, 0.8), b - Vector2(0, 0.8), Color(0.62, 0.46, 0.28), 1.3)
	for k in 3:
		var wx := a.x - f * (4 + k * 2.5)
		draw_line(Vector2(wx, a.y - 2), Vector2(wx, a.y + 2), Color(0.2, 0.12, 0.08), 1.0)
	draw_line(b - Vector2(f * 3, 0), b - Vector2(f * 6, 0) + Vector2(0, 8 + sin(anim_t * 6.0) * 2.0), Color(0.8, 0.2, 0.2), 2.2)
	DU.poly(self, PackedVector2Array([b, b + Vector2(-f * 8, -5), b + Vector2(f * 10, 0), b + Vector2(-f * 8, 5)]), Color(0.8, 0.84, 0.92))
	draw_line(b + Vector2(-f * 6, 0), b + Vector2(f * 9, 0), Color(1, 1, 1, 0.75), 1.0)
	DU.ball(self, hand, 3.0, dark.lightened(0.15))
	DU.ball(self, hand - Vector2(f * 9, 0), 2.6, dark.lightened(0.1))
	if state == "thrust":
		draw_line(b, b - Vector2(f * 40, 0), Color(1, 1, 1, 0.5), 6.0)
	draw_stun(-38.0)

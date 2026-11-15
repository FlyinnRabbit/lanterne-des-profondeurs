extends CharacterBody2D
# Base commune des ennemis : vie, clignotement, recul, mort.

const DU = preload("res://scripts/draw_util.gd")

var main
var hp := 3
var size := Vector2(28, 24)
var flash_t := 0.0
var knock := Vector2.ZERO
var dead := false
var geo_value := 3
var anim_t := 0.0
var knock_resist := 1.0
var stun_t := 0.0
var elite := false      # version élite : plus de vie, plus rapide, attaque spéciale, lueur rouge
var is_boss := false

# Multiplicateurs liés à la difficulté (et au statut élite)
func spd() -> float:
	return float(GameState.scaled("speed")) * (1.2 if elite else 1.0)

func aggro() -> float:
	return float(GameState.scaled("aggro")) * (1.25 if elite else 1.0)

func setup_body() -> void:
	var s := RectangleShape2D.new()
	s.size = size
	var cs := CollisionShape2D.new()
	cs.shape = s
	add_child(cs)
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")
	if not is_boss:
		hp = maxi(1, roundi(hp * float(GameState.scaled("hp")) * (1.7 if elite else 1.0)))
	if elite:
		geo_value *= 2
		add_child(main.make_light(Color(1.0, 0.3, 0.25), 0.9, 1.0))

func get_rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)

func is_harmful() -> bool:
	return not dead and stun_t <= 0.0

# Appelé quand le joueur pare le contact : l'ennemi est repoussé et étourdi (inoffensif).
func parried(dir: Vector2) -> void:
	stun_t = 1.1
	flash_t = 0.1
	knock = Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, -0.3) * 420.0

func take_hit(dmg: int, dir: Vector2) -> void:
	if dead:
		return
	hp -= dmg
	flash_t = 0.12
	knock = dir * 340.0 * knock_resist
	main.spawn_burst(global_position, Color(1.0, 0.95, 0.85), 8, 180.0)
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	remove_from_group("enemies")
	main.on_enemy_killed(self, geo_value)
	queue_free()

func body_color(base: Color) -> Color:
	if flash_t > 0.0:
		return Color(1, 1, 1)
	return base.lerp(Color(1.0, 0.35, 0.3), 0.35) if elite else base

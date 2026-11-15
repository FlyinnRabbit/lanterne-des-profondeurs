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
var hp_max := 0          # vie de départ (pour la barre de vie)
var show_bar := true
const HpBarScript = preload("res://scripts/hp_bar.gd")
const TelegraphScript = preload("res://scripts/telegraph.gd")

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
	hp_max = hp
	var tg := Node2D.new()
	tg.set_script(TelegraphScript)
	add_child(tg)
	if show_bar and not is_boss:
		var bar := Node2D.new()
		bar.set_script(HpBarScript)
		add_child(bar)

func get_rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)

# Annonce d'attaque : 0 rien, 1 attaque qui arrive, 2 attaque haute (s'accroupir)
func telegraph() -> int:
	if dead or stun_t > 0.0:
		return 0
	for k in ["windup_t", "windup", "dive_windup"]:
		if k in self and float(get(k)) > 0.0:
			return 1
	if "fuse" in self and float(get("fuse")) >= 0.0:
		return 1
	if "state" in self:
		var st := str(get("state"))
		if st.begins_with("windup") or st == "appear":
			return 1
	return 0

func is_harmful() -> bool:
	return not dead and stun_t <= 0.0

# Étourdissement. Parade parfaite : ×1,6. Les boss ne peuvent pas être étourdis en boucle :
# après un étourdissement, ils y sont insensibles 2,5 s (la parade bloque quand même le coup).
var stun_immune_until := 0.0

func stun_mult() -> float:
	return 1.6 if main.player and main.player.parry_perfect_now else 1.0

func try_stun(t: float) -> bool:
	var now: float = main.clock
	if is_boss and now < stun_immune_until:
		flash_t = 0.1
		return false
	stun_t = maxf(stun_t, t)
	if is_boss:
		stun_immune_until = now + t + 2.5
	return true

# Appelé quand le joueur pare le contact : l'ennemi est repoussé et étourdi (inoffensif).
func parried(dir: Vector2) -> void:
	try_stun(1.1 * stun_mult())
	flash_t = 0.1
	knock = Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, -0.3) * 420.0

func take_hit(dmg: int, dir: Vector2) -> void:
	if dead:
		return
	hp -= dmg
	main.on_damage_dealt(self, dmg)
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

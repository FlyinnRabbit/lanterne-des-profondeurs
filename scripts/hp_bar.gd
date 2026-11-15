extends Node2D
# Barre de vie au-dessus d'un ennemi : trait fin, avec une traînée claire qui rattrape
# la vie restante (effet « chargement »). Visible dès que l'ennemi est blessé.

var lag := 1.0      # part de vie affichée par la traînée (descend doucement)
var shown_t := 0.0

func _ready() -> void:
	z_index = 20
	z_as_relative = false

func _process(delta: float) -> void:
	var e = get_parent()
	if not is_instance_valid(e) or e.hp_max <= 0:
		return
	var frac := clampf(float(e.hp) / e.hp_max, 0.0, 1.0)
	lag = move_toward(lag, frac, delta * 0.8) if lag > frac else frac
	if frac < 1.0:
		shown_t = 3.0
	shown_t -= delta
	position = Vector2(0, -e.size.y / 2.0 - 10.0)
	visible = Settings.enemy_bars and (frac < 1.0 or e.elite)
	modulate.a = float(e.alpha) if "alpha" in e else 1.0   # le spectre estompé reste caché
	queue_redraw()

func _draw() -> void:
	var e = get_parent()
	if not is_instance_valid(e):
		return
	var frac := clampf(float(e.hp) / e.hp_max, 0.0, 1.0)
	var w := clampf(e.size.x + 6.0, 26.0, 60.0)
	var r := Rect2(-w / 2.0, 0, w, 4)
	draw_rect(r.grow(1.0), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(r.position, Vector2(w * lag, 4)), Color(1.0, 0.95, 0.8, 0.85))      # traînée
	var col := Color(0.9, 0.25, 0.25).lerp(Color(0.95, 0.75, 0.3), frac)
	draw_rect(Rect2(r.position, Vector2(w * frac, 4)), col)
	if e.elite:
		draw_rect(r.grow(1.0), Color(1.0, 0.45, 0.35), false, 1.0)

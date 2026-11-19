extends Node2D
# Familier lumineux : suit le héros (purement décoratif). Son apparence vient du cosmétique équipé.
const DU = preload("res://scripts/draw_util.gd")
var main
var kind := ""
var t := 0.0
var light: PointLight2D

func _ready() -> void:
	z_index = 4
	light = main.make_light(Color(1, 1, 1), 0.8, 0.28)
	add_child(light)
	_refresh()
	GameState.cos.changed.connect(_refresh)
	if main.player:
		global_position = main.player.global_position + Vector2(-30, -40)

func _refresh() -> void:
	kind = GameState.cos.eq("pet")
	visible = kind != "pet_none"
	light.enabled = visible
	light.color = GameState.cos.look("pet")["c"]

func _process(delta: float) -> void:
	if not visible or main.player == null:
		return
	t += delta
	var p = main.player
	var goal: Vector2 = p.global_position + Vector2(-p.facing * 30.0, -44.0) + Vector2(sin(t * 1.7) * 10.0, sin(t * 2.3) * 7.0)
	if global_position.distance_to(goal) > 500.0:
		global_position = goal
	global_position = global_position.lerp(goal, clampf(delta * 3.5, 0.0, 1.0))
	queue_redraw()

func _draw() -> void:
	draw_pet(self, kind, GameState.cos.item(kind).get("c", Color.WHITE), t)

# Dessin d'un familier (aussi utilisé par l'aperçu de la tailleuse). base : repère de dessin
# du support (les familiers qui pivotent le combinent au lieu de l'écraser).
static func draw_pet(ci: CanvasItem, kind: String, c: Color, t: float, base := Transform2D.IDENTITY) -> void:
	match kind:
		"pet_luciole":
			DU.glow(ci, Vector2.ZERO, 14.0, c, 0.35)
			var w := sin(t * 40.0) * 3.0
			ci.draw_colored_polygon(DU.ellipse(Vector2(-3, -3 + w * 0.3), Vector2(4, 2)), Color(1, 1, 1, 0.5))
			ci.draw_colored_polygon(DU.ellipse(Vector2(3, -3 - w * 0.3), Vector2(4, 2)), Color(1, 1, 1, 0.5))
			ci.draw_circle(Vector2.ZERO, 2.6, Color(0.2, 0.2, 0.15))
			ci.draw_circle(Vector2(0, 2), 2.4 + sin(t * 5.0) * 0.5, c)
		"pet_papillon":
			var fl := absf(sin(t * 9.0))
			for s in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s * 9.0 * fl, -7), Vector2(s * 11.0 * fl, 0), Vector2(s * 6.0 * fl, 6)]), c)
				ci.draw_circle(Vector2(s * 6.0 * fl, -2), 1.5, c.darkened(0.4))
			ci.draw_line(Vector2(0, -4), Vector2(0, 5), Color(0.2, 0.18, 0.25), 2.0)
			DU.glow(ci, Vector2.ZERO, 12.0, c, 0.15)
		"pet_follet":
			DU.glow(ci, Vector2.ZERO, 18.0, c, 0.35)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 3), Vector2(sin(t * 6.0) * 2.5, -12 - sin(t * 9.0) * 2.0), Vector2(5, 3), Vector2(0, 6)]), Color(c, 0.9))
			ci.draw_circle(Vector2(0, 1), 3.0, Color(1, 1, 1))
		"pet_lanterne":
			DU.glow(ci, Vector2.ZERO, 18.0, c, 0.35)
			var sw := sin(t * 2.5) * 0.25
			ci.draw_set_transform_matrix(base * Transform2D(sw, Vector2.ZERO))
			ci.draw_arc(Vector2(0, -8), 3.0, PI, TAU, 8, Color(0.3, 0.25, 0.2), 1.5)
			DU.box(ci, Rect2(-4.5, -6, 9, 11), Color(0.32, 0.26, 0.18))
			ci.draw_rect(Rect2(-3, -4.5, 6, 8), Color(1.0, 0.9, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -6), Vector2(0, -10), Vector2(6, -6)]), Color(0.26, 0.2, 0.14))
			ci.draw_set_transform_matrix(base)
		"pet_guepe":
			var w2 := sin(t * 50.0) * 2.0
			ci.draw_colored_polygon(DU.ellipse(Vector2(-2, -5 + w2 * 0.3), Vector2(5, 2.2)), Color(1, 1, 1, 0.45))
			ci.draw_colored_polygon(DU.ellipse(Vector2(3, -5 - w2 * 0.3), Vector2(5, 2.2)), Color(1, 1, 1, 0.45))
			ci.draw_colored_polygon(DU.ellipse(Vector2.ZERO, Vector2(6, 3.6)), c)
			ci.draw_line(Vector2(-1, -3.4), Vector2(-1, 3.4), Color(0.12, 0.1, 0.08), 1.6)
			ci.draw_line(Vector2(2.5, -3), Vector2(2.5, 3), Color(0.12, 0.1, 0.08), 1.6)
			ci.draw_circle(Vector2(-6, 0), 2.4, Color(0.15, 0.12, 0.1))
			ci.draw_line(Vector2(6, 0), Vector2(9, 1), Color(0.15, 0.12, 0.1), 1.2)
		"pet_chauvesouris":
			var fl2 := sin(t * 14.0)
			for sgn in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sgn * 12.0, -6 - fl2 * 5.0), Vector2(sgn * 9.0, 1), Vector2(sgn * 6.0, -1), Vector2(sgn * 4.0, 3)]), c.darkened(0.45))
			ci.draw_circle(Vector2.ZERO, 3.6, c.darkened(0.55))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, -3), Vector2(-2, -7), Vector2(-0.5, -3)]), c.darkened(0.55))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(3, -3), Vector2(2, -7), Vector2(0.5, -3)]), c.darkened(0.55))
			ci.draw_circle(Vector2(-1.3, -0.5), 0.8, Color(1.0, 0.6, 0.2))
			ci.draw_circle(Vector2(1.3, -0.5), 0.8, Color(1.0, 0.6, 0.2))
		"pet_coeur":
			var pu := 1.0 + 0.12 * sin(t * 6.0)
			DU.glow(ci, Vector2.ZERO, 13.0, c, 0.25)
			ci.draw_circle(Vector2(-3, -1.5) * pu, 3.6 * pu, c)
			ci.draw_circle(Vector2(3, -1.5) * pu, 3.6 * pu, c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6.3, 0.2) * pu, Vector2(6.3, 0.2) * pu, Vector2(0, 7.5) * pu]), c)
		"pet_poussin":
			var hop2 := absf(sin(t * 5.0)) * 2.0
			ci.draw_circle(Vector2(0, -hop2), 5.5, c)
			ci.draw_circle(Vector2(3, -6 - hop2), 3.8, c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(6, -6 - hop2), Vector2(9.5, -5 - hop2), Vector2(6, -4 - hop2)]), Color(1.0, 0.55, 0.15))
			ci.draw_circle(Vector2(4.2, -7 - hop2), 0.8, Color(0.1, 0.08, 0.05))
			ci.draw_line(Vector2(-1, 5 - hop2), Vector2(-1, 8), Color(1.0, 0.55, 0.15), 1.2)
			ci.draw_line(Vector2(2, 5 - hop2), Vector2(2, 8), Color(1.0, 0.55, 0.15), 1.2)
		"pet_flocon":
			DU.glow(ci, Vector2.ZERO, 14.0, c, 0.3)
			for j in 3:
				var d := Vector2.from_angle(j * PI / 3.0 + t * 0.8) * 7.0
				ci.draw_line(-d, d, c, 1.6)
				ci.draw_line(d * 0.6, d * 0.6 + d.rotated(0.9) * 0.3, c, 1.0)
				ci.draw_line(-d * 0.6, -d * 0.6 - d.rotated(0.9) * 0.3, c, 1.0)
			ci.draw_circle(Vector2.ZERO, 1.6, Color(1, 1, 1))

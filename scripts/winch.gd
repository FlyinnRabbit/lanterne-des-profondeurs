extends Node2D
# Treuil au pied d'un puits (grotte ou passage entre strates) : une corde pend du haut du puits ;
# {haut} près du crochet hisse le héros jusqu'en haut en ~1,5 s, sans contrôle.
# position = pied de la corde (sol du bas) ; top = haut du puits ; arrive = où l'on est déposé.
const DU = preload("res://scripts/draw_util.gd")
var main
var top := Vector2.ZERO
var arrive := Vector2.ZERO
var t := 0.0
var pulling := 0.0      # > 0 pendant la montée : la corde vibre et le tambour tourne

func _ready() -> void:
	z_index = -1

func _process(delta: float) -> void:
	t += delta
	pulling = maxf(pulling - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var tp := to_local(top)
	var rope := Color(0.62, 0.48, 0.3)
	var rope_d := Color(0.36, 0.26, 0.16)
	# corde : légère oscillation, plus forte pendant la montée
	var sway := sin(t * 1.7) * 1.5 + (sin(t * 23.0) * 2.0 if pulling > 0.0 else 0.0)
	var pts := PackedVector2Array()
	var n := 16
	for i in n + 1:
		var k := float(i) / n
		pts.append(Vector2(sway * sin(k * PI), lerpf(tp.y + 10.0, -26.0, k)))
	draw_polyline(pts, rope_d, 4.0)
	draw_polyline(pts, rope, 2.0)
	# torsades de la corde
	for i in range(1, n, 2):
		var p: Vector2 = pts[i]
		draw_line(p + Vector2(-1.5, -2), p + Vector2(1.5, 2), rope_d, 1.0)
	# crochet et poignée en bas
	var hk := pts[n]
	draw_arc(hk + Vector2(0, 6), 5.0, -0.3, PI + 0.3, 10, Color(0.55, 0.55, 0.6), 2.5)
	draw_rect(Rect2(hk + Vector2(-7, -2), Vector2(14, 4)), Color(0.45, 0.32, 0.2))
	# tambour du treuil en haut, sur deux montants
	var dc := tp + Vector2(0, 2)
	draw_rect(Rect2(dc + Vector2(-26, -4), Vector2(5, 26)), Color(0.32, 0.23, 0.15))
	draw_rect(Rect2(dc + Vector2(21, -4), Vector2(5, 26)), Color(0.32, 0.23, 0.15))
	draw_rect(Rect2(dc + Vector2(-22, -2), Vector2(44, 12)), Color(0.42, 0.3, 0.19))
	draw_rect(Rect2(dc + Vector2(-22, -2), Vector2(44, 3)), Color(0.55, 0.4, 0.26))
	var rot := t * (9.0 if pulling > 0.0 else 0.0)
	for i in 4:
		var a := rot + i * PI / 2.0
		draw_line(dc + Vector2(28, 4), dc + Vector2(28, 4) + Vector2.from_angle(a) * 9.0, Color(0.5, 0.42, 0.3), 2.0)
	draw_circle(dc + Vector2(28, 4), 3.0, Color(0.7, 0.6, 0.4))
	# petite lanterne au pied, pour repérer la remontée dans le noir
	var lp := Vector2(16, -8)
	DU.glow(self, lp, 26.0, Color(1.0, 0.8, 0.45), 0.25 + 0.05 * sin(t * 3.0))
	draw_rect(Rect2(lp + Vector2(-4, -6), Vector2(8, 10)), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(lp + Vector2(-3, -5), Vector2(6, 8)), Color(1.0, 0.82, 0.5))
	draw_line(lp + Vector2(0, -6), lp + Vector2(0, 8), Color(0.3, 0.22, 0.15), 1.0)

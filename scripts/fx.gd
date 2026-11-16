extends Node2D
# Effets visuels courts, dessinés en code : impacts, mort des ennemis, éclats qui volent
# vers le joueur, poussière d'atterrissage, images rémanentes de la ruée.

const DU = preload("res://scripts/draw_util.gd")

var main
var kind := "hit"
var t := 0.0
var life := 0.3
var dir := Vector2.RIGHT
var color := Color(1, 1, 1)
var facing := 1
var seed_v := 0
var parts := []        # morceaux / éclats : [position, vitesse, rotation, taille]

func _ready() -> void:
	z_index = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	match kind:
		"hit":
			life = 0.22
		"death":
			life = 0.9
			for i in 10:
				var a := rng.randf_range(0.0, TAU)
				parts.append([Vector2.ZERO, Vector2.from_angle(a) * rng.randf_range(80.0, 260.0) + Vector2(0, -120), rng.randf_range(0.0, TAU), rng.randf_range(2.5, 5.5)])
		"shards":
			life = 1.4
			for i in clampi(int(dir.x), 1, 8):
				var a := rng.randf_range(-PI * 0.9, -PI * 0.1)
				parts.append([Vector2.ZERO, Vector2.from_angle(a) * rng.randf_range(120.0, 220.0), rng.randf_range(0.0, TAU), rng.randf_range(3.0, 4.5)])
		"dust":
			life = 0.45
		"after":
			life = 0.22
			z_index = -1

func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
		return
	match kind:
		"death":
			for p in parts:
				p[1].y += 700.0 * delta
				p[0] += p[1] * delta
				p[2] += delta * 8.0
		"shards":
			# jaillissent, puis filent vers le joueur
			var target: Vector2 = main.player.global_position - global_position if main and main.player else Vector2.ZERO
			for p in parts:
				if t < 0.35:
					p[1].y += 500.0 * delta
					p[1] *= 0.96
				else:
					var to: Vector2 = target - p[0]
					p[1] = p[1].lerp(to.normalized() * 700.0, minf(delta * 8.0, 1.0))
					if to.length() < 18.0:
						p[3] = 0.0
				p[0] += p[1] * delta
				p[2] += delta * 6.0
	queue_redraw()

func _draw() -> void:
	var k := 1.0 - t / life
	match kind:
		"hit":
			# éclair d'impact : étoile de rayons, anneau, point blanc
			var r := 10.0 + 26.0 * (1.0 - k)
			DU.glow(self, Vector2.ZERO, 26.0, color, 0.6 * k)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(color, 0.7 * k), 2.0 * k + 0.5)
			for i in 6:
				var a := dir.angle() + (i - 2.5) * 0.45
				var l := (18.0 + (i % 2) * 10.0) * (0.6 + 0.6 * (1.0 - k))
				draw_line(Vector2.from_angle(a) * 4.0, Vector2.from_angle(a) * l, Color(1, 1, 1, k), 2.0 * k + 0.5)
			draw_circle(Vector2.ZERO, 5.0 * k, Color(1, 1, 1, k))
		"death":
			# anneau, fumée qui monte, morceaux du corps, petite âme qui s'élève
			var u := 1.0 - k
			draw_arc(Vector2.ZERO, 12.0 + 40.0 * u, 0.0, TAU, 28, Color(color.lightened(0.4), 0.6 * k), 3.0 * k)
			for i in 5:
				var a := i * TAU / 5.0 + 0.4
				var sp := Vector2.from_angle(a) * 18.0 * u + Vector2(0, -30.0 * u)
				draw_circle(sp, 6.0 + 10.0 * u, Color(0.2, 0.18, 0.22, 0.35 * k))
			for p in parts:
				var pc: Vector2 = p[0]
				var sz: float = p[3]
				DU.flat(self, PackedVector2Array([pc + Vector2.from_angle(p[2]) * sz, pc + Vector2.from_angle(p[2] + 2.2) * sz * 0.8, pc + Vector2.from_angle(p[2] + 4.0) * sz]), Color(color, k))
			var soul := Vector2(sin(t * 9.0) * 4.0, -60.0 * u)
			DU.glow(self, soul, 14.0, Color(0.8, 0.9, 1.0), 0.6 * k)
			draw_circle(soul, 3.0 * k, Color(1, 1, 1, k))
		"shards":
			for p in parts:
				var sz: float = p[3]
				if sz <= 0.0:
					continue
				var pc: Vector2 = p[0]
				DU.glow(self, pc, sz * 3.0, Color(0.7, 0.85, 1.0), 0.4)
				var rot: float = p[2]
				var pts := PackedVector2Array([pc + Vector2(0, -sz * 1.4).rotated(rot), pc + Vector2(sz, 0).rotated(rot), pc + Vector2(0, sz * 1.2).rotated(rot), pc + Vector2(-sz, 0).rotated(rot)])
				draw_colored_polygon(pts, Color(0.72, 0.86, 1.0))
				draw_line(pts[0], pts[2], Color(1, 1, 1, 0.8), 1.0)
		"dust":
			var u := 1.0 - k
			for side in [-1.0, 1.0]:
				for i in 3:
					var x: float = side * (6.0 + i * 8.0 + 22.0 * u)
					var y := -2.0 - i * 2.0 - 6.0 * u
					draw_circle(Vector2(x, y), (3.0 + i) * (0.6 + u), Color(color, 0.5 * k))
		"after":
			# silhouette de cape qui s'efface
			var c := Color(color.r, color.g, color.b, 0.45 * k)
			var f := float(facing)
			draw_colored_polygon(PackedVector2Array([Vector2(-8 * f, -26), Vector2(8 * f, -26), Vector2(12 * f, -3), Vector2(0, 0), Vector2(-13 * f, -3)]), c)
			draw_colored_polygon(DU.ellipse(Vector2(0, -33), Vector2(10, 9)), c)

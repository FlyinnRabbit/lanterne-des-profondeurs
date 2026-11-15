extends Node2D
# Arrière-plan en parallaxe : piliers et racines lointaines dans la brume bleutée.

var main
var layers := []   # [facteur, Node2D]

class Layer extends Node2D:
	var factor := 0.5
	var col := Color()
	var seed_v := 0
	var width := 0.0
	var height := 0.0
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v
		var x := -2000.0
		while x < width + 2000.0:
			var w := rng.randf_range(40.0, 120.0) * (1.2 - factor)
			var top := rng.randf_range(-200.0, height * 0.35)
			var bottom := height + 400.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, bottom), Vector2(x + w * 0.15, top + 80), Vector2(x + w * 0.5, top),
				Vector2(x + w * 0.85, top + 60), Vector2(x + w, bottom)]), col)
			# stalactites suspendues
			var sx := x + w + rng.randf_range(30.0, 160.0)
			var sl := rng.randf_range(80.0, 360.0)
			draw_colored_polygon(PackedVector2Array([Vector2(sx - 22, -400), Vector2(sx + 22, -400), Vector2(sx, sl)]), col)
			x += w + rng.randf_range(80.0, 260.0)

func _ready() -> void:
	z_index = -10
	var w: float = main.map_size.x * main.TILE
	var h: float = main.map_size.y * main.TILE
	var p: Dictionary = main.pal
	var sd: int = int(main.level.get("seed", 0))
	var specs := [[0.8, p["far"], 7 + sd], [0.6, p["mid"], 13 + sd], [0.35, p["near"], 21 + sd]]
	for i in specs.size():
		var l := Layer.new()
		l.factor = specs[i][0]
		l.col = specs[i][1]
		l.seed_v = specs[i][2]
		l.width = w
		l.height = h
		l.z_index = i
		add_child(l)
		layers.append(l)

func _process(_delta: float) -> void:
	var cam: Camera2D = main.camera
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	for l in layers:
		l.position = c * l.factor

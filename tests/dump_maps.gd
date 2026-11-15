extends SceneTree
func _initialize() -> void:
	var gs = root.get_node_or_null("GameState")
	var Biomes = load("res://scripts/biomes.gd")
	var LevelGen = load("res://scripts/levelgen.gd")
	var f := FileAccess.open("user://maps.txt", FileAccess.WRITE)
	for bi in Biomes.all().size():
		for s in 25:
			for depth in [1, 3, 5]:
				var g = LevelGen.new()
				var boss := "K" if depth == 3 else ("Q" if depth == 5 else "")
				var m: Array = g.generate(Biomes.all()[bi], s * 101 + bi, depth, boss, depth == 5, {"count": 1.6, "variety": 3.0})
				f.store_line("MAP %s %d %d" % [Biomes.all()[bi]["id"], s, depth])
				for r in m:
					f.store_line(r)
	f.close()
	print(ProjectSettings.globalize_path("user://maps.txt"))
	quit()

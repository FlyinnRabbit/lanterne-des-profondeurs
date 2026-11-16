extends SceneTree
func _initialize() -> void:
	var Biomes = load("res://scripts/biomes.gd")
	var LevelGen = load("res://scripts/levelgen.gd")
	for id in ["jardins", "cristal"]:
		var b: Dictionary
		for bb in Biomes.all():
			if bb["id"] == id:
				b = bb
		var gen = LevelGen.new()
		var m: Array = gen.generate(b, 4242, 3, "K", false, {"count": 1.0, "variety": 1.0})
		print("=== %s : %d x %d" % [id, m[0].length(), m.size()])
		for r in m:
			print(r)
	quit()

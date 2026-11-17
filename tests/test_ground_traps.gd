extends SceneTree
# Pièges au sol par biome : présents, espacés (jamais deux dangers à moins de 9 cases), et
# le totem se retourne vers le héros.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	for b in Biomes.all():
		var counts := {}
		var too_close := 0
		for sd in 6:
			var gen := LevelGen.new()
			var map: Array = gen.generate(b, 900 + sd * 37, 3 + sd, "K" if sd % 2 == 0 else "", false, gs.DIFFS[1].duplicate())
			var pts := []
			for y in map.size():
				var row: String = map[y]
				for x in row.length():
					if "kqvyxzaod".contains(row[x]):
						counts[row[x]] = int(counts.get(row[x], 0)) + 1
						pts.append(Vector2i(x, y))
			for p in pts:
				for y in range(maxi(p.y - 5, 0), mini(p.y + 6, map.size())):
					var row2: String = map[y]
					for x in range(maxi(p.x - 9, 0), mini(p.x + 10, row2.length())):
						if Vector2i(x, y) != p and "^ZUVkqvyxzaod".contains(row2[x]):
							too_close += 1
		print(b["id"], " ", counts, " too_close=", too_close)
		if counts.is_empty() or too_close > 0: ok = false
	# totem qui pivote
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	pl.sitting = false
	var tr = main._make_trap("dart", pl.global_position + Vector2(100, 20), {"dir": 1.0})
	await _f(60)
	print("totem dir after 1s with player on its left: ", tr.dir)
	if tr.dir != -1.0: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

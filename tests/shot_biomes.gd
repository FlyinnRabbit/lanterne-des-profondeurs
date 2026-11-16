extends SceneTree
# Captures de chaque biome (comparaison graphique). Usage : -s tests/shot_biomes.gd -- <prefixe>
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var pre := "now"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		pre = args[0]
	var only := -1
	if args.size() > 1:
		only = int(args[1])
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	var all: Array = Biomes.all()
	for i in all.size():
		if only >= 0 and i != only:
			continue
		var b: Dictionary = all[i]
		gs.run_seed = 4242
		var key := "%d-%d-%d" % [gs.run_seed, 1, 1]
		var gen := LevelGen.new()
		var diff: Dictionary = gs.DIFFS[1].duplicate()
		diff["count"] = 3
		gs._cache[key] = {"name": b["name"], "map": gen.generate(b, 1000 + i * 17, 3, "", false, diff),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 1000 + i * 17}
		gs.mode = "descent"
		gs.palier = 1
		gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame   # le changement de scène est différé
		await process_frame
		paused = false
		await _frames(4)
		var main = current_scene
		main.player.global_position.x += 520
		await _frames(70)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_%s.png" % [pre, b["id"]])
		print("ok ", b["id"])
	quit()

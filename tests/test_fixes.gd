extends SceneTree
# Combo par arme, taux d'élites, totems près du boss.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	# --- taux d'élites réel (même tirage que le jeu)
	gs.mode = "descent"
	for dn in gs.DIFFS.size():
		gs.difficulty = dn
		var line := "élites %-10s" % gs.DIFFS[dn]["name"]
		for palier in [1, 2, 3, 5, 7, 10]:
			gs.palier = palier
			var el := 0
			var tot := 0
			for step in [1, 2]:
				gs.step = step
				var ch: float = gs.elite_chance()
				for sd in 30:
					for x in range(5, 60, 3):
						for y in range(3, 20, 4):
							var r := RandomNumberGenerator.new()
							r.seed = 1000 + sd * 7919 + x * 977 + y * 31
							tot += 1
							if r.randf() < ch:
								el += 1
			line += "  P%d %3d%%" % [palier, roundi(100.0 * el / tot)]
		print(line)
	gs.difficulty = 1
	# --- totems à fléchettes près de l'arène du boss
	var near := 0
	var lv := 0
	for sd in 40:
		for b in Biomes.all():
			var gen := LevelGen.new()
			var map: Array = gen.generate(b, 7000 + sd * 13, 4, "K", false, gs.DIFFS[2].duplicate())
			lv += 1
			var bx := -1
			for row in map:
				var i: int = String(row).find("K")
				if i >= 0:
					bx = i
			for row in map:
				var rs := String(row)
				for x in rs.length():
					if rs[x] == "Z" and bx >= 0 and absi(x - bx) < 55:
						near += 1
	print("niveaux de boss générés : %d, totems à moins de 55 cases du boss : %d" % [lv, near])
	# --- combo de chaque arme : trois appuis dès que possible
	gs.palier = 1
	gs.step = 1
	var b0: Dictionary = Biomes.all()[0]
	var gen2 := LevelGen.new()
	var d2: Dictionary = gs.DIFFS[1].duplicate()
	d2["count"] = 0
	gs.run_seed = 77
	gs._cache["77-1-1"] = {"name": b0["name"], "map": gen2.generate(b0, 4321, 1, "", false, d2), "music": b0["music"], "boss_id": "", "boss_music": "", "palette": b0["pal"], "seed": 4321}
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(60)
	for w in ["aiguille", "fouet", "marteau", "shuriken"]:
		gs.prog["weapon"] = w
		await _frames(120)
		var kinds := []
		for i in 3:
			var guard := 0
			while main.player.attack_cd > 0.0 and guard < 400:
				await physics_frame
				guard += 1
			await _frames(6)      # temps de réaction du joueur : 50 ms
			Input.action_press("attack")
			await _frames(2)
			Input.action_release("attack")
			kinds.append(main.player.attack_kind)
		print("combo %-9s : %s" % [w, " > ".join(kinds)])
	quit()

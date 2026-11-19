extends SceneTree
# Treuils : chaque grotte et chaque passage entre strates a une corde ; on s'y accroche, on monte et on
# descend à volonté ({haut} / {bas}), on peut sauter ou lâcher en route, et d'en haut on redescend par elle.
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
	var total := 0
	for bid in ["jardins", "cristal", "ruche", "glace"]:
		gs.difficulty = 1
		gs.mode = "descent"
		gs.palier = 2
		gs.step = 1
		gs.curse = ""
		gs.run_seed = 777
		gs._cache.clear()
		var LevelGen = load("res://scripts/levelgen.gd")
		var Biomes = load("res://scripts/biomes.gd")
		var b: Dictionary
		for bb in Biomes.all():
			if bb["id"] == bid:
				b = bb
		var gen = LevelGen.new()
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, 9100, 3, "", false, {"count": 1.0}),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 9100}
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(10)
		var main = current_scene
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		var winches := []
		for it in main.interactables:
			if it[1] == "winch":
				winches.append(it[0])
		var res := []
		for w in winches:
			total += 1
			var pl = main.player
			pl.global_position = w.position + Vector2(10, -18)
			pl.velocity = Vector2.ZERO
			await _f(30)
			Input.action_press("up")
			await _f(2)
			var grabbed: bool = pl.rope == w
			# on tient {haut} jusqu'en haut
			var n := 0
			while (pl.rope != null or not pl.hoist_path.is_empty()) and n < 1500:
				await physics_frame
				n += 1
			Input.action_release("up")
			await _f(60)
			var d: float = pl.global_position.distance_to(w.arrive)
			var good: bool = grabbed and d < 24.0 and pl.is_on_floor()
			# d'en haut : {bas} au bord du puits pour redescendre, puis lâcher à mi-hauteur avec {saut}
			var down_ok := false
			var mid_ok := false
			if good:
				Input.action_press("down")
				await _f(3)
				var on_rope: bool = pl.rope == w
				await _f(18)
				Input.action_release("down")
				var y_mid: float = pl.global_position.y
				Input.action_press("jump")
				await _f(2)
				Input.action_release("jump")
				mid_ok = on_rope and pl.rope == null and y_mid > w.top.y + 30.0 and y_mid < w.position.y - 40.0
				await _f(90)
				# raccroche en bas et descend jusqu'au sol
				pl.global_position = w.position + Vector2(0, -60)
				pl.velocity = Vector2.ZERO
				await _f(1)
				main.call("_grab_winch", w, pl.global_position.y)
				Input.action_press("down")
				var m := 0
				while pl.rope != null and m < 1500:
					await physics_frame
					m += 1
				Input.action_release("down")
				await _f(5)
				down_ok = pl.rope == null and absf(pl.global_position.y - (w.position.y - pl.SIZE.y / 2.0)) < 6.0
			good = good and mid_ok and down_ok
			if not good:
				print("   prise %s, arrivée %.0f px, lâcher en route %s, descente au sol %s" % [grabbed, d, mid_ok, down_ok])
			res.append("%s(%.0f)" % ["✔" if good else "✗", d])
			if not good:
				ok = false
		print("%-12s : %d treuils  %s  taille %dx%d" % [bid, winches.size(), " ".join(res), main.map_size.x, main.map_size.y])
		if winches.size() < 2:
			ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC", " (", total, " treuils)")
	quit()

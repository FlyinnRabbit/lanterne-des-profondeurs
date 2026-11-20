extends SceneTree
# Ennemis signature des biomes : chacun apparaît dans son biome, vit, attaque et meurt sans erreur.
# --shots : galerie /tmp/shots/foes.png (élites comprises)
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
const FOES := {"profondeurs": ["<", "angler"], "jardins": [";", "puffball"], "citadelle": [">", "drowned"], "cristal": ["=", "turtle"],
	"forge": ["!", "imp"], "bibliotheque": ["?", "tome"], "glace": [":", "golem"], "ossuaire": ["/", "skeleton"]}
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	var only := OS.get_environment("ONLY")
	for bid in FOES:
		if only != "" and bid != only:
			continue
		var b: Dictionary = {}
		for x in Biomes.all():
			if x["id"] == bid:
				b = x
		# présence dans les niveaux générés
		var found := 0
		for sd in 4:
			var m: Array = LevelGen.new().generate(b, 200 + sd, 4, "", false, gs.DIFFS[1])
			for row in m:
				found += String(row).count(FOES[bid][0])
		gs.run_seed = 31
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": LevelGen.new().generate(b, 99, 3, "", false, gs.DIFFS[1]),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 99}
		gs.mode = "descent"; gs.palier = 2; gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		for i in 10: await physics_frame
		var main = current_scene
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		var pl = main.player
		var foes := []
		for k in 2:
			var e := CharacterBody2D.new()
			e.set_script(load("res://scripts/%s.gd" % FOES[bid][1]))
			e.main = main
			e.elite = k == 1
			e.position = pl.global_position + Vector2(90 + k * 70, -10 if not FOES[bid][0] in ["<", "?"] else -60)
			main.add_child(e)
			foes.append(e)
		pl.invuln_t = 99.0
		for i in 180: await physics_frame
		var alive := 0
		for e in foes:
			if is_instance_valid(e) and not e.dead:
				alive += 1
				# on l'achève : coups répétés de dessus
				for j in 12:
					if is_instance_valid(e) and not e.dead:
						e.stun_t = 1.0
						if "flipped_t" in e:
							e.flipped_t = 1.0
						e.take_hit(2, Vector2.DOWN)
						if "pile_t" in e and e.pile_t > 0.0:
							e.take_hit(1, Vector2.DOWN)
						await physics_frame
		var dead_all := true
		for e in foes:
			if is_instance_valid(e) and not e.dead:
				dead_all = false
		print("%s (%s) : dans %d cases sur 4 niveaux ; vivants après 3 s : %d ; tués : %s" % [FOES[bid][1], bid, found, alive, dead_all])
		ok = ok and found > 0 and dead_all
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
# Champions des biomes (mini-boss) : chacun apparaît en grand, garde sa barre de vie en bas
# de l'écran, rapporte un butin une fois vaincu et ne revient pas après un repos au banc.
# --shots : capture de chaque champion dans /tmp/shots/champ_<biome>.png
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	RenderingServer.render_loop_enabled = shots
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	var n := 0
	for b in Biomes.all():
		var map := []
		var sd := 0
		for s in range(1, 300):
			map = LevelGen.new().generate(b, s, 4, "", false, gs.DIFFS[1])
			if "".join(map).contains("`"):
				sd = s
				break
		if sd == 0:
			print("ÉCHEC pas de champion généré pour ", b["id"])
			ok = false
			continue
		gs.run_seed = 900 + n
		gs._cache.clear()
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": map, "music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": sd}
		gs.mode = "descent"; gs.palier = 2; gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		var main = current_scene
		for i in 10: await physics_frame
		var c = main.champ
		if c == null or not is_instance_valid(c):
			print("ÉCHEC champion absent : ", b["id"])
			ok = false
			continue
		var pl = main.player
		pl.global_position = c.global_position + Vector2(-260, 0)
		if shots:
			main.hud.message_t = 0.0
			for i in 90: await physics_frame
			pl.hp = pl.max_hp
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("/tmp/shots/champ_%s.png" % b["id"])
		for i in 20:
			pl.hp = pl.max_hp
			pl.invuln_t = 0.5
			await physics_frame
		var hp0: int = c.hp
		var geo0: int = pl.geo
		var nm: String = c.champion
		if c.get("state") == "hidden":
			c.state = "walk"     # le Noyé se cache dans sa flaque : on le fait surgir
			c.set("rise", 1.0)
		for k in 4:               # le Squelette s'effondre d'abord en tas, puis le tas cède
			if is_instance_valid(c) and not c.dead:
				c.take_hit(99999, Vector2.RIGHT)
			for i in 12: await physics_frame
		var gained: int = pl.geo - geo0
		main.respawn_enemies()
		await physics_frame
		var back := main.champ != null and is_instance_valid(main.champ)
		print("%-14s %-24s pv %d  échelle %.1f  éclats +%d  revient : %s" % [b["id"], nm, hp0, c.scale.x if is_instance_valid(c) else 1.7, gained, back])
		ok = ok and hp0 >= 20 and gained > 60 and not back
		n += 1
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

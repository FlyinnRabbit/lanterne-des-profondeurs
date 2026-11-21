extends SceneTree
# Champions en conditions réelles : chacun combat 12 s (--shots : capture en plein combat) un héros immobile à côté de lui (vie
# remise à fond). On vérifie qu'il ne reste pas coincé dans la roche, ne tombe pas hors du
# niveau, bouge et frappe.
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
		for attempt in 1:
			var map := []
			var sd := 0
			for s in range(1 + attempt * 300, 300 + attempt * 300):
				map = LevelGen.new().generate(b, s, 4, "", false, gs.DIFFS[1])
				if "".join(map).contains("`"):
					sd = s
					break
			gs.run_seed = 700 + n
			n += 1
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
				print("ÉCHEC pas de champion ", b["id"])
				ok = false
				continue
			# les autres ennemis à l'écart
			for e in get_nodes_in_group("enemies"):
				if e != c:
					e.queue_free()
			var pl = main.player
			pl.max_hp = 999
			pl.hp = 999
			pl.global_position = c.global_position + Vector2(-140, -10)
			var start: Vector2 = c.global_position
			var maxd := 0.0
			var stuck_frames := 0
			var hurt0 := int(gs.j_get("hurt", 0))
			var fell := false
			for f in 720:
				if not is_instance_valid(c) or c.dead:
					break
				pl.hp = 999
				if f % 120 == 0:
					pl.global_position = c.global_position + Vector2(-140 if f % 240 == 0 else 140, -10)
				maxd = maxf(maxd, c.global_position.distance_to(start))
				if f == 300 and shots:
					await RenderingServer.frame_post_draw
					root.get_viewport().get_texture().get_image().save_png("/tmp/shots/champlive_%s.png" % b["id"])
				if main.is_solid_at(c.global_position) and c.visible:
					stuck_frames += 1
				if c.global_position.y > main.map_size.y * main.TILE + 100:
					fell = true
				await physics_frame
			var hits := int(gs.j_get("hurt", 0)) - hurt0
			var line := "%-13s %-24s déplacement max %4d px  coups portés %2d  dans la roche %3d images%s" % [b["id"], c.champion if is_instance_valid(c) else "?", int(maxd), hits, stuck_frames, "  TOMBÉ" if fell else ""]
			var bad := fell or stuck_frames > 30 or (hits == 0 and maxd < 20.0)
			print(("PROBLÈME " if bad else "ok       ") + line)
			if bad:
				ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
# Économie par palier : éclats et âme à gagner en tuant tous les ennemis, selon la difficulté et la profondeur.
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	print("diff     palier  ennemis  élites  éclats(ennemis)  boss  coups_pour_tuer(aiguille)  âme_gagnée  soins_possibles")
	for diff in 4:
		for pal in [1, 3, 6]:
			var tot_e := 0
			var tot_el := 0
			var tot_geo := 0
			var tot_hits := 0
			var seeds := 3
			for sd in seeds:
				for st in [1, 2]:
					gs.difficulty = diff
					gs.mode = "descent"
					gs.palier = pal
					gs.step = st
					gs.curse = ""
					gs.run_seed = 1000 + sd * 7
					gs._cache.clear()
					change_scene_to_file("res://main.tscn")
					await process_frame
					await process_frame
					await process_frame
					for e in get_nodes_in_group("enemies"):
						if e.is_boss or e.get_script() == current_scene.DummyScript:
							continue
						tot_e += 1
						if e.elite:
							tot_el += 1
						tot_geo += gs.kill_geo(int(e.geo_value))
						tot_hits += int(ceil(float(e.hp) / 1.0))
			var soul_hit: int = roundi(11 * float(gs.DIFFS[diff]["soul"]))
			var boss: int = gs.boss_geo()
			var n := float(seeds)
			var hits: float = tot_hits / n
			print("%-9s %d   %6.0f  %6.0f  %15.0f  %4d  %25.0f  %10.0f  %15.1f" % [gs.DIFFS[diff]["name"], pal, tot_e / n, tot_el / n, tot_geo / n, boss, hits, hits * soul_hit, hits * soul_hit / 33.0])
	quit()

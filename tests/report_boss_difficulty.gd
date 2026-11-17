extends SceneTree
# Rapport de difficulté des boss : Normal vs Cauchemar, à leur palier habituel.
# Héros immobile au centre de l'arène (vie très haute) : coups reçus par minute, et plus courte
# préparation d'attaque (« windup ») observée = la fenêtre pour réagir.
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	print("%-26s %-9s %3s %5s %6s %8s %10s" % ["boss", "diff.", "pal", "PV", "vitesse", "coups/min", "préparation min (s)"])
	for id in ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre", "cerbere", "centaure", "oeil"]:
		for diff in [1, 3]:
			gs.difficulty = diff
			var pal := 1
			for p in range(1, 8):
				if gs.boss_for(p) == id:
					pal = p
					break
			if id in gs.FINALS:
				pal = 7
				for sd in range(1, 400):
					gs.run_seed = sd
					gs._cache.clear()
					if gs.boss_for(7) == id:
						break
			gs.mode = "descent"
			gs.palier = pal
			gs.step = 2
			gs.curse = ""
			change_scene_to_file("res://main.tscn")
			await process_frame
			await process_frame
			paused = false
			for i in 4:
				await process_frame
			var main = current_scene
			var boss = main.boss
			var pl = main.player
			pl.max_hp = 9999
			pl.hp = 9999
			pl.global_position = Vector2(boss.home.x - 260.0, boss.home.y - 20.0)
			var hits := 0
			var last_hp: int = pl.hp
			var min_wind := 99.0
			var wind_t := -1.0
			var prev_state := ""
			var secs := 15.0
			var frames := int(secs * 120)
			for f in frames:
				if not is_instance_valid(boss) or not is_instance_valid(pl):
					break
				if f == frames / 2:
					boss.take_hit(boss.hp - boss.max_hp / 2 + 1, Vector2.RIGHT)   # phase 2 pour la seconde moitié
				if pl.hp < last_hp:
					hits += 1
				last_hp = pl.hp
				var st: String = boss.state
				if st != prev_state:
					if prev_state.begins_with("windup") and wind_t >= 0.0:
						min_wind = minf(min_wind, wind_t)
					wind_t = 0.0 if st.begins_with("windup") else -1.0
					prev_state = st
				elif wind_t >= 0.0:
					wind_t += 1.0 / 120.0
				await physics_frame
			var name: String = boss.boss_name if is_instance_valid(boss) else id
			print("%-26s %-9s %3d %5d %6.2f %8.1f %10.2f" % [name, gs.DIFFS[diff]["name"], pal, boss.max_hp if is_instance_valid(boss) else 0,
				gs.scaled("speed"), hits * 60.0 / secs, min_wind])
			if is_instance_valid(boss):
				boss.take_hit(99999, Vector2.RIGHT)
			for i in 3:
				await process_frame
	print("FIN")
	quit()

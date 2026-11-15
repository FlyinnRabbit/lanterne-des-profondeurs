extends SceneTree
# Combat automatique contre chaque boss (joueur invincible) : états visités, projectiles, erreurs.
# Avec --shots, prend une capture de chaque boss en pleine attaque.
var shots := false

func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()

func _wait(n := 3) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	for id in ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre"]:
		var pal := 1
		for p in range(1, 8):
			if gs.boss_for(p) == id:
				pal = p
				break
		gs.mode = "descent"
		gs.palier = pal
		gs.step = 2
		change_scene_to_file("res://main.tscn")
		paused = false
		Engine.time_scale = 1.0
		await _wait(4)
		var main = current_scene
		var boss = main.boss
		var pl = main.player
		pl.global_position = boss.global_position + Vector2(-300, -40)
		var states := {}
		var max_proj := 0
		var pillars := 0
		var shot_taken := false
		for f in 1500:
			if not is_instance_valid(pl):
				break
			pl.hp = pl.max_hp
			pl.invuln_t = 0.5
			if f % 40 == 0 and is_instance_valid(boss):
				# reste dans l'arène (les grilles empêchent d'en sortir en vrai jeu)
				var tx: float = clampf(boss.global_position.x - 220.0 * (1 if f % 80 == 0 else -1), boss.home.x - 800.0, boss.home.x + 150.0)
				pl.global_position = Vector2(tx, boss.home.y - 20.0)
			if is_instance_valid(boss):
				states[boss.state] = true
				if f == 900:
					boss.take_hit(boss.hp - boss.max_hp / 2 + 1, Vector2.RIGHT)   # passe en phase 2
			max_proj = maxi(max_proj, get_nodes_in_group("projectiles").size())
			for c in main.get_children():
				if c.get_script() == main.PillarScript:
					pillars += 1
			if shots and not shot_taken and f > 300 and is_instance_valid(boss) and (get_nodes_in_group("projectiles").size() > 3 or boss.state.begins_with("windup")):
				await RenderingServer.frame_post_draw
				root.get_viewport().get_texture().get_image().save_png("/tmp/boss_%s.png" % id)
				shot_taken = true
			await physics_frame
		var name: String = boss.boss_name if is_instance_valid(boss) else "?"
		var ph = boss.get("phase") if is_instance_valid(boss) else 0
		if is_instance_valid(boss):
			boss.take_hit(99999, Vector2.RIGHT)
		await _wait(3)
		print("%-24s palier %d | états : %s | projectiles max %d | piliers %d | phase %s | vaincu : %s" % [name, pal, ", ".join(PackedStringArray(states.keys())), max_proj, pillars, str(ph), main.boss_dead])
	print("TEST BOSS TERMINÉ")
	quit()

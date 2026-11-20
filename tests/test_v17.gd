extends SceneTree
# v1.8 : ombre, carte, salles spéciales, défi des boss, descente du jour, malédictions,
# habitants du Sanctuaire, succès, boss final. --shots : captures.
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _frames(n: int) -> void:
	await process_frame   # laisse passer un éventuel changement de scène différé
	for i in n:
		await physics_frame
func _shot(n: String) -> void:
	if shots:
		for cam in current_scene.find_children("*", "Camera2D", true, false):
			cam.reset_smoothing()
			cam.force_update_scroll()
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % n)
func _scene() -> void:
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	Engine.time_scale = 1.0
	await _frames(5)
func _find(main, ch: String) -> Vector2i:
	if ch == "$T":
		# salle au trésor : la cachette est sous une dalle fissurée (le coffre du caveau des leviers
		# et celui de la chambre secrète ne comptent pas)
		for y in range(2, main.MAP.size()):
			var row: String = main.MAP[y]
			for x in row.length():
				if row[x] == "$" and x < (main.MAP[y - 2] as String).length() and main.MAP[y - 2][x] == "W":
					return Vector2i(x, y)
		return Vector2i(-1, -1)
	for y in main.MAP.size():
		var x: int = (main.MAP[y] as String).find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)
func _level_with(gs, ch: String):
	for p in range(1, 10):
		for st in [1, 2]:
			gs.mode = "descent"
			gs.palier = p
			gs.step = st
			gs.curse = ""
			await _scene()
			var c := _find(current_scene, ch)
			if c.x >= 0:
				return c
	return Vector2i(-1, -1)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ach = root.get_node("Achievements")
	gs.show_title = false
	gs.run_seed = 4242
	gs.record = 7
	gs.unlocked = 8
	gs.prog["geo"] = 100
	gs.snapshot = gs.prog.duplicate(true)
	# --- ombre
	gs.mode = "descent"; gs.palier = 1; gs.step = 1
	await _scene()
	var main = current_scene
	main.player.geo = 180
	var dpos: Vector2 = main.player.global_position + Vector2(200, 0)
	gs.die_in_descent(main.player.geo, dpos)
	await _frames(5)
	print("ombre enregistrée : ", gs.prog.get("shade", {}), " | message : ", gs.pending_message)
	gs.start_descent(1, null)
	await _frames(6)
	main = current_scene
	print("ombre présente : ", main.shade_node != null)
	await _frames(20)
	main.player.global_position = main.shade_node.global_position + Vector2(-120, 0)
	await _frames(10)
	await _shot("v17_shade")
	var g0: int = main.player.geo
	main.shade_node.take_hit(99, Vector2.RIGHT)
	await _frames(3)
	print("ombre vaincue : +%d éclats, ombre effacée : %s, succès : %s" % [main.player.geo - g0, not gs.prog.has("shade"), ach.done.has("shade")])
	# --- carte
	await _frames(30)
	var seen := 0
	for b in main.explored:
		seen += b
	main.map_view.toggle()
	await _frames(3)
	print("carte ouverte : %s, cases vues : %d / %d" % [main.map_view.visible, seen, main.explored.size()])
	await _shot("v17_map")
	main.map_view.toggle()
	await _frames(3)
	await _shot("v17_minimap")
	# --- salle au trésor
	var c = await _level_with(gs, "$T")
	main = current_scene
	var lid = null
	for n in main.get_children():
		if n.get_script() == main.PlatformScript and n.kind == "breakable" and absf(n.position.x - c.x * 32) < 80:
			lid = n
	main.player.global_position = Vector2(lid.position.x + 16, lid.position.y - 18)
	await _frames(10)
	await _shot("v17_treasure")
	for n in get_nodes_in_group("breakables"):
		n.hit(3)
	await _frames(40)
	var g1: int = main.player.geo
	main.player.global_position = Vector2(c.x * 32 + 16, c.y * 32 + 14)
	await _frames(10)
	print("trésor : +%d éclats" % (main.player.geo - g1))
	# --- défi chronométré
	c = await _level_with(gs, "S")
	main = current_scene
	main.player.global_position = main.challenge_start.position + Vector2(0, -18)
	await _frames(5)
	print("défi lancé : %.1f s" % main.challenge_t)
	await _shot("v17_challenge")
	var g2: int = main.player.geo
	main.player.global_position = main.challenge_goal.position + Vector2(0, -18)
	await _frames(5)
	print("défi réussi : %s, +%d éclats" % [main.challenge_done, main.player.geo - g2])
	# --- arène d'élites
	c = await _level_with(gs, "R")
	main = current_scene
	for it in main.interactables:
		if it[1] == "altar":
			main.player.global_position = it[0].position + Vector2(-40, -18)
			await _frames(5)
			main._start_altar(it[0])
	await _frames(30)
	await _shot("v17_altar")
	print("élites invoquées : ", main.altar_foes.size(), " élites : ", main.altar_foes.all(func(e): return e.elite))
	var g3: int = main.player.geo
	for e in main.altar_foes:
		e.take_hit(999, Vector2.RIGHT)
	await _frames(5)
	print("arène : ", main.altar_state, " +%d éclats" % (main.player.geo - g3))
	# --- malédictions
	gs.mode = "hub"
	await _scene()
	gs.start_descent(2, current_scene.player, "dark")
	await _frames(6)
	main = current_scene
	await _shot("v17_dark")
	print("malédiction obscurité : ", gs.curse, " multiplicateur éclats ", gs.geo_mult())
	gs.curse = "fragile"
	main.player.hp = 2
	main.player.soul = 99
	Input.action_press("focus")
	await _frames(240)
	Input.action_release("focus")
	print("fragilité : pv %d (pas de soin attendu)" % main.player.hp)
	gs.abandon_descent()
	await _frames(6)
	# --- descente du jour
	var seed0: int = gs.run_seed
	gs.start_daily(current_scene.player)
	await _frames(6)
	print("descente du jour : graine %d (jour %d), palier %d" % [gs.run_seed, gs.today_seed(), gs.palier])
	await _shot("v17_daily")
	gs.die_in_descent(0, Vector2.ZERO)
	await _frames(6)
	print("après la descente du jour : graine restaurée %s, mode %s" % [gs.run_seed == seed0, gs.mode])
	# --- défi des boss
	gs.start_rush(current_scene.player)
	await _frames(6)
	main = current_scene
	print("défi des boss : boss 1 = ", main.boss.boss_name)
	await _shot("v17_rush")
	for i in 7:
		gs.go_next_level(current_scene.player)
		await _frames(6)
	print("défi terminé : mode %s, succès %s" % [gs.mode, ach.done.has("rush")])
	print("message : ", gs.pending_message.split("\n")[0])
	# --- boss final : balayage
	gs.mode = "descent"; gs.palier = 7; gs.step = 2
	await _scene()
	main = current_scene
	var b = main.boss
	main.boss_started = true
	main.entry_gate.set_closed(true)
	b.wake()
	main.player.global_position = b.home + Vector2(-200, 120)
	b.go("windup_sweep", 0.4)
	await _frames(30)
	print("boss final : ", b.state, " annonce ", b.telegraph())
	await _frames(40)
	await _shot("v17_final")
	# --- Sanctuaire : habitants, arsenal amélioré, succès
	gs.mode = "hub"
	await _scene()
	main = current_scene
	var npcs := []
	for it in main.interactables:
		npcs.append(it[1])
	print("habitants : ", npcs)
	main.player.geo = 2000
	main.player.global_position = Vector2(36 * 32, 16 * 32)
	await _frames(20)
	await _shot("v17_hub")
	main.hub_ui.open_npc("elder")
	await _frames(3)
	await _shot("v17_elder")
	main.hub_ui.close_all()
	gs.prog["weapons_owned"] = ["fouet", "marteau", "shuriken"]
	main.hub_ui.open_arsenal()
	main.hub_ui._smith_upgrade("shuriken")
	await _frames(3)
	await _shot("v17_arsenal")
	print("amélioration : étoiles niv.", gs.weapon_level("shuriken"))
	main.hub_ui.close_all()
	main.menu.open()
	main.menu._open_achievements()
	await _frames(3)
	await _shot("v17_achievements")
	print("succès : %d / %d" % [ach.done.size(), ach.LIST.size()])
	quit()

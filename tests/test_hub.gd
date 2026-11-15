extends SceneTree
# Teste la boucle hub → ascenseur → descente → boss → hub, la boutique, la mort et la sauvegarde.
func _initialize() -> void:
	_run()

func _wait(n := 3) -> void:
	for i in n:
		await process_frame

func _scene():
	await _wait()
	return current_scene

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save.cfg"))
	gs.show_title = false
	change_scene_to_file("res://main.tscn")
	await _wait()
	gs.new_game(true, 1)
	var main = await _scene()
	print("1. mode=", gs.mode, " niveau=", main.level["name"], " marchand/ascenseur=", main.interactables.size())
	main.player.geo = 1000
	main.hub_ui.open_shop()
	await _wait()
	print("   boutique : ", main.hub_ui.shop_list.get_child_count(), " articles")
	print("   achat vie : '", gs.buy("hp", 0, main.player), "' max_hp=", main.player.max_hp)
	print("   achat encoche : '", gs.buy("notch", 0, main.player), "' encoches=", gs.prog["notches"])
	print("   achat emblème 0 : '", gs.buy("charm", 0, main.player), "' possédé=", gs.owns(0), " geo=", main.player.geo)
	main.hub_ui.close_all()
	main.hub_ui.open_elevator()
	await _wait()
	print("   ascenseur : ", main.hub_ui.lift_list.get_child_count(), " palier(s)")
	main.hub_ui._descend(1)
	main = await _scene()
	print("2. mode=", gs.mode, " palier ", gs.palier, " niveau ", gs.step, " : ", main.level["name"], " boss=", main.boss != null)
	gs.go_next_level(main.player)
	main = await _scene()
	print("   palier ", gs.palier, " niveau ", gs.step, " : ", main.level["name"], " boss=", main.boss != null, " (", main.boss.boss_name if main.boss else "", ")")
	main.boss.wake()
	main.boss.take_hit(99999, Vector2.RIGHT)
	await _wait()
	print("   boss vaincu, éclats=", main.player.geo)
	gs.go_next_level(main.player)
	main = await _scene()
	print("3. retour : mode=", gs.mode, " débloqué=", gs.unlocked, " record=", gs.record)
	var geo_before: int = main.player.geo
	gs.start_descent(2, main.player)
	main = await _scene()
	print("4. palier ", gs.palier, " : ", main.level["name"], " ; je ramasse 500 éclats puis je meurs")
	main.player.geo += 500
	gs.add_charm(5)
	main.player.take_damage(99, main.player.global_position.x - 5)
	await create_timer(2.5).timeout
	main = await _scene()
	print("   après la mort : mode=", gs.mode, " geo=", main.player.geo, " (avant descente ", geo_before, ") emblème 5 perdu=", not gs.owns(5), " max_hp=", main.player.max_hp)
	print("   message : ", main.hud.message.replace("\n", " / "))
	print("5. sauvegarde : ", gs.has_save(), " -> ", gs.save_summary())
	gs.unlocked = 1
	gs.load_game()
	print("   rechargement : débloqué=", gs.unlocked, " emblème 0=", gs.owns(0), " vie bonus=", gs.max_hp_bonus())
	gs.continue_game()
	main = await _scene()
	print("   continuer -> ", gs.mode, " ", main.level["name"])
	# échelle de difficulté
	gs.mode = "descent"
	for p in [1, 3, 6, 10]:
		gs.palier = p
		print("   palier ", p, " : vie x", snappedf(gs.scaled("hp"), 0.01), " vitesse x", snappedf(gs.scaled("speed"), 0.01), " élites ", snappedf(gs.scaled("elite"), 0.01))
	gs.mode = "hub"
	print("TEST HUB TERMINÉ")
	quit()

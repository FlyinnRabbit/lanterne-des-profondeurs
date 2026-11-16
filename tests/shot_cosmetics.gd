extends SceneTree
# Captures : tailleuse, garde-robe, tenues, ultimes. Usage : -- <prefixe>   (LANTERNE_NOEL=1 pour le décor de Noël)
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _snap(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s.png" % name)
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "cos"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	gs.record = 5
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	var cos = gs.cos
	for id in cos.ITEMS:
		cos.owned[id] = true
	await _frames(40)
	var tailor = null
	var tree = null
	for it in main.interactables:
		if it[1] == "tailor":
			tailor = it[0]
		if it[1] == "gift":
			tree = it[0]
	main.player.global_position = tailor.position + Vector2(-70, -18)
	main.player.facing = 1
	await _frames(40)
	await _snap(pre + "_tailleuse")
	if tree:
		main.player.global_position = tree.position + Vector2(90, -18)
		main.player.facing = -1
		var ev: String = gs.CosmeticsScript.current_event()
		cos.equipped = {"noel": {"cape": "cape_noel", "scarf": "scarf_guirlande", "hat": "hat_bonnet", "trail": "trail_flocons", "pet": "pet_flocon", "ult": "ult_etoile"},
			"halloween": {"cape": "cape_halloween", "scarf": "scarf_violette", "hat": "hat_citrouille", "trail": "trail_citrouille", "pet": "pet_chauvesouris", "ult": "ult_nuee"},
			"valentin": {"cape": "cape_rose", "scarf": "scarf_ecarlate", "hat": "hat_coeurs", "trail": "trail_coeurs", "pet": "pet_coeur", "ult": "ult_coeur"},
			"paques": {"cape": "cape_pastel", "scarf": "scarf_doree", "hat": "hat_lapin", "trail": "trail_ombre", "pet": "pet_poussin", "ult": "ult_eclosion"}}[ev]
		cos.changed.emit()
		await _frames(60)
		await _snap(pre + "_sapin")
		main.ultimate_blast(main.player.global_position)
		await _frames(30)
		await _snap(pre + "_fete_ult")
		await _frames(90)
		main.player.global_position = tailor.position + Vector2(-70, -18)
	# tenues
	var looks := [
		{"cape": "cape_ombre", "scarf": "scarf_sarcelle", "hat": "hat_none", "trail": "trail_ombre", "pet": "pet_none", "ult": "ult_or"},
		{"cape": "cape_braise", "scarf": "scarf_braise", "hat": "hat_cornes", "trail": "trail_braise", "pet": "pet_follet", "ult": "ult_brasier"},
		{"cape": "cape_givre", "scarf": "scarf_blanche", "hat": "hat_aureole", "trail": "trail_givre", "pet": "pet_luciole", "ult": "ult_givre"},
		{"cape": "cape_or", "scarf": "scarf_doree", "hat": "hat_couronne", "trail": "trail_or", "pet": "pet_lanterne", "ult": "ult_eclipse"},
		{"cape": "cape_nuit", "scarf": "scarf_violette", "hat": "hat_plume", "trail": "trail_spectre", "pet": "pet_papillon", "ult": "ult_essaim"},
		{"cape": "cape_noel", "scarf": "scarf_guirlande", "hat": "hat_bonnet", "trail": "trail_flocons", "pet": "pet_flocon", "ult": "ult_etoile"},
		{"cape": "cape_mousse", "scarf": "scarf_ecarlate", "hat": "hat_fleurs", "trail": "trail_regard", "pet": "pet_guepe", "ult": "ult_or"},
		{"cape": "cape_amethyste", "scarf": "scarf_sarcelle", "hat": "hat_renne", "trail": "trail_ombre", "pet": "pet_none", "ult": "ult_or"},
		{"cape": "cape_os", "scarf": "scarf_ecarlate", "hat": "hat_bougie", "trail": "trail_ombre", "pet": "pet_none", "ult": "ult_or"},
	]
	main.player.global_position = Vector2(30 * 32, main.player.global_position.y)
	main.player.facing = 1
	for i in looks.size():
		cos.equipped = looks[i]
		cos.changed.emit()
		await _frames(50)
		await _snap("%s_look_%d" % [pre, i])
		if i == 0:
			print("pos ", main.player.get_global_transform_with_canvas().origin)
		if i in [0, 1, 2, 3, 4, 5]:
			main.ultimate_blast(main.player.global_position)
			await _frames(26)
			await _snap("%s_ult_%d" % [pre, i])
			await _frames(80)
	# garde-robe
	cos.equipped = looks[1]
	cos.changed.emit()
	main.hub_ui.open_wardrobe()
	await _snap(pre + "_garde_robe")
	main.hub_ui._ward_tab("hat")
	await _snap(pre + "_garde_robe_hat")
	main.hub_ui._ward_tab("ult")
	await _snap(pre + "_garde_robe_ult")
	main.hub_ui.close_all()
	cos.load_data()
	print("ok cos")
	quit()

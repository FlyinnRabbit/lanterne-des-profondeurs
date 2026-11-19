extends SceneTree
# Cosmétiques : achat, port, récompenses de succès, butin de boss, cadeau de Noël.
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ach = root.get_node("Achievements")
	var cos = gs.cos
	# état propre pour le test (sans toucher aux fichiers du joueur)
	cos.owned = {}
	for k in cos.DEFAULTS:
		cos.owned[cos.DEFAULTS[k]] = true
	cos.equipped = cos.DEFAULTS.duplicate()
	cos.gifts = {}
	ach.done = {}
	ach.counters = {}
	var ok := true
	gs.show_title = false
	gs.unlocked = 5
	gs.record = 5
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(30)
	var kinds := []
	for it in main.interactables:
		kinds.append(it[1])
	print("habitants du Sanctuaire : ", kinds)
	ok = ok and ("tailor" in kinds)
	# achat refusé sans éclats, accepté avec
	main.player.geo = 10
	main.hub_ui.open_wardrobe()
	main.hub_ui._ward_pick("cape_braise")
	var refused: bool = not cos.has("cape_braise")
	main.player.geo = 500
	main.hub_ui._ward_pick("cape_braise")
	main.hub_ui._ward_buy()       # confirmation « Acheter »
	print("achat : refusé sans éclats %s, acheté %s, porté %s, éclats restants %d" % [refused, cos.has("cape_braise"), cos.eq("cape") == "cape_braise", main.player.geo])
	ok = ok and refused and cos.has("cape_braise") and cos.eq("cape") == "cape_braise" and main.player.geo == 420
	# objet de succès : pas achetable
	main.hub_ui._ward_pick("hat_couronne")
	ok = ok and not cos.has("hat_couronne")
	# objet de saison : selon la date
	main.hub_ui._ward_pick("cape_noel")
	main.hub_ui._ward_buy()
	var ev: String = gs.CosmeticsScript.current_event()
	print("fête en cours : '%s', cape de Noël achetée : %s" % [ev, cos.has("cape_noel")])
	ok = ok and cos.has("cape_noel") == (ev == "noel")
	main.hub_ui.close_all()
	# succès -> cosmétique
	ach.unlock("rich")
	print("succès Trésor -> couronne : ", cos.has("hat_couronne"))
	ok = ok and cos.has("hat_couronne")
	# butin de boss : le tirage finit par tomber, une seule fois
	main.level["boss_id"] = "colosse"
	var tries := 0
	while not cos.has("hat_cornes") and tries < 200:
		main._boss_cosmetic()
		tries += 1
	print("butin du Colosse après %d victoires : %s, succès Trophée : %s" % [tries, cos.has("hat_cornes"), ach.done.has("trophy")])
	ok = ok and cos.has("hat_cornes") and ach.done.has("trophy") and tries > 0
	# garde-robe : 10 cosmétiques
	for id in ["scarf_doree", "scarf_blanche", "hat_plume", "trail_givre", "pet_luciole", "ult_givre", "cape_mousse", "cape_givre"]:
		ach.give_cosmetic(id)
	print("cosmétiques possédés : %d, succès Garde-robe : %s" % [cos.owned_count(), ach.done.has("wardrobe")])
	ok = ok and ach.done.has("wardrobe")
	for id in ["scarf_doree", "hat_plume", "trail_givre", "pet_luciole", "ult_givre"]:
		cos.equip(id)
	ach.check_wardrobe()
	print("succès Sur son trente-et-un : ", ach.done.has("fashion"))
	ok = ok and ach.done.has("fashion")
	# cadeau de la fête en cours
	if ev != "":
		var tree = null
		for it in main.interactables:
			if it[1] == "gift":
				tree = it[0]
		var g0: int = main.player.geo
		var gift_id: String = gs.CosmeticsScript.EVENTS[ev]["gift"]
		main._open_gift(tree)
		print("cadeau de %s : %s obtenu %s, +%d éclats, cadeau encore là %s" % [ev, gift_id, cos.has(gift_id), main.player.geo - g0, tree.lit])
		ok = ok and cos.has(gift_id) and main.player.geo - g0 == 50 and not tree.lit and cos.gift_open(ev)
	else:
		ok = ok and not ("gift" in kinds)
	# dates des fêtes
	var C = gs.CosmeticsScript
	print("Pâques 2026 : %s, 2027 : %s" % [C.easter(2026), C.easter(2027)])
	ok = ok and C.easter(2026) == [4, 5] and C.easter(2027) == [3, 28]
	print("TEST COSMÉTIQUES : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
# Discord : bouton sur l'écran-titre, panneau, et familier « Tube néon » donné quand le Worker
# accepte le code du jour (posté par webhook sur le serveur ; réponse simulée).
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10:
		await physics_frame
	var menu = current_scene.menu
	var ok := true
	var has_item := false
	for b in menu.title_items:
		if b is Button and b.text == "Discord":
			has_item = true
	print("bouton Discord sur l'écran-titre : ", has_item)
	ok = ok and has_item
	var cos = gs.cos
	cos.owned.erase("pet_neon")
	menu._open_discord()
	await process_frame
	print("panneau ouvert : ", menu._holder(menu.discord_panel).visible, " ; bouton Valider actif : ", not menu.discord_link_btn.disabled)
	ok = ok and menu._holder(menu.discord_panel).visible and not menu.discord_link_btn.disabled
	menu.discord.redeem("ab")
	print("code trop court : ", menu.discord_status.text)
	ok = ok and menu.discord.status == "bad_code"
	menu.discord.on_answer({"ok": false})
	print("mauvais code : ", menu.discord_status.text, " ; familier : ", cos.has("pet_neon"))
	ok = ok and not cos.has("pet_neon")
	print("nettoyage du code : ", menu.discord.clean(" s8r7-zafu "))
	ok = ok and menu.discord.clean(" s8r7-zafu ") == "S8R7ZAFU"
	menu.discord.on_answer({"ok": true})
	print("bon code : ", menu.discord_status.text, " ; familier : ", cos.has("pet_neon"), " porté : ", cos.eq("pet") == "pet_neon")
	ok = ok and cos.has("pet_neon") and cos.eq("pet") == "pet_neon" and menu.discord_link_btn.disabled
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

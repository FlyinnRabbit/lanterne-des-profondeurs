extends SceneTree
# Mémoires de l'Ancien : menu à onglets, mémoires débloquées en jouant, éclats à la première écoute,
# paroles des habitants consignées, bulle « ! » quand il reste des mémoires à écouter.
# --shots : captures /tmp/elder_*.png
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _shot(n: String) -> void:
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/elder_%s.png" % n)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 4
	gs.prog.erase("lore_read")
	gs.prog.erase("talk")
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10:
		await physics_frame
	var main = current_scene
	var Lore = load("res://scripts/lore.gd")
	var ok := true
	var unread0: int = Lore.unread_count()
	print("mémoires débloquées : ", Lore.unlocked_count(), " / ", Lore.entries().size(), " ; à écouter : ", unread0)
	ok = ok and unread0 > 0
	# paroles : la forgeronne et le marchand
	main.hub_ui.open_npc("smith")
	main.hub_ui.close_all()
	main.hub_ui.open_shop()
	main.hub_ui.close_all()
	print("paroles : ", Lore.talk().keys())
	ok = ok and Lore.talk().has("La forgeronne") and Lore.talk().has("Le marchand")
	var geo0: int = main.player.geo
	main.elder_ui.open()
	for i in 3:
		await process_frame
	print("ouvert sur l'onglet ", main.elder_ui.page, " ligne ", main.elder_ui.sel, " ; éclats +", main.player.geo - geo0, " ; ", main.elder_ui.toast)
	ok = ok and main.player.geo - geo0 == Lore.REWARD and paused
	await _shot("chroniques")
	main.elder_ui._set_sel(3)
	main.elder_ui._set_sel(7)     # palier 7 : verrouillé
	await process_frame
	await _shot("verrou")
	main.elder_ui._set_page(1)
	main.elder_ui._set_sel(4)     # la forgeronne (deux parties au palier 4)
	for i in 3:
		await process_frame
	await _shot("habitants")
	main.elder_ui._set_page(2)
	for i in 3:
		await process_frame
	await _shot("gardiens")
	main.elder_ui._set_page(3)
	for i in 3:
		await process_frame
	await _shot("paroles")
	var geo1: int = main.player.geo
	main.elder_ui._set_page(0)
	main.elder_ui._set_sel(1)
	main.elder_ui._set_sel(0)     # déjà écoutée : rien de plus
	print("réécoute : éclats +", main.player.geo - geo1)
	ok = ok and main.player.geo == geo1 + Lore.REWARD   # c1 était nouvelle, c0 déjà lue
	main.elder_ui.close()
	print("fermé ; jeu en pause : ", paused, " ; à écouter : ", Lore.unread_count(), " (avant : ", unread0, ")")
	ok = ok and not paused and Lore.unread_count() < unread0
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

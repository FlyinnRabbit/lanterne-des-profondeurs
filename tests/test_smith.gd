extends SceneTree
# Les améliorations d'armes se font chez la forgeronne (plus à l'arsenal).
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 1
	gs.unlocked = 2
	gs.prog["weapon_lv"] = {}
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	main.player.geo = 5000
	main.hub_ui.open_arsenal()
	await process_frame
	var ars_up := 0
	for line in main.hub_ui.ars_list.get_children():
		for b in line.get_children():
			if b is Button and (String(b.text).find("Améliorer") >= 0 or String(b.text).find("Upgrade") >= 0):
				ars_up += 1
	main.hub_ui.close_all()
	main.hub_ui.open_npc("smith")
	await process_frame
	var labels := []
	var up_btn: Button = null
	for b in main.hub_ui.npc_buttons.get_children():
		labels.append(b.text)
		if up_btn == null and not b.disabled and b.get_index() == 0:
			up_btn = b
	print("boutons forgeronne : ", labels)
	var found := up_btn != null
	up_btn.pressed.emit()
	await process_frame
	print("après : ", main.hub_ui.npc_text.text, "")
	print("arme=", gs.weapon(), " lv=", gs.prog.get("weapon_lv"))
	print("RÉSULTAT : ", "OK" if ars_up == 0 and found and gs.weapon_level(gs.weapon()) == 2 else "ÉCHEC (arsenal=%d)" % ars_up)
	quit()

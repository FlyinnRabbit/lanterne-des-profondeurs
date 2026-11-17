extends SceneTree
# Niveaux d'arme 1 à 5 : prérequis (palier terminé, arme possédée), prix, bonus selon l'arme
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	var W = load("res://scripts/weapons.gd")
	var ok := true
	pl.geo = 99999
	gs.record = 0
	gs.prog["weapon_lv"] = {}
	gs.prog["weapons_owned"] = ["griffes"]
	var e1: String = gs.upgrade_weapon("aiguille", pl)
	print("palier 0 -> niv2 : '", e1, "'")
	if e1 == "": ok = false
	gs.record = 1
	var e_own: String = gs.upgrade_weapon("marteau", pl)
	print("arme non possédée : '", e_own, "'")
	if e_own == "": ok = false
	print("niv2 : '", gs.upgrade_weapon("aiguille", pl), "' lv=", gs.weapon_level("aiguille"))
	var e3: String = gs.upgrade_weapon("aiguille", pl)
	print("niv3 sans palier 2 : '", e3, "'")
	if e3 == "" or gs.weapon_level("aiguille") != 2: ok = false
	gs.record = 5
	for i in 3:
		gs.upgrade_weapon("aiguille", pl)
	print("aiguille lv=", gs.weapon_level("aiguille"), " max : '", gs.upgrade_weapon("aiguille", pl), "'")
	if gs.weapon_level("aiguille") != 5: ok = false
	gs.prog["weapon"] = "aiguille"
	var w: Dictionary = pl.weapon()
	var base: Dictionary = W.get_w("aiguille")
	print("aiguille niv5 : cd ", base["cd"], " -> ", w["cd"], " crit ", w["crit"], " dmg ", base["dmg"], " -> ", w["dmg"])
	if not (w["cd"] < base["cd"] and w["crit"] > 0.0 and w["dmg"] == base["dmg"] + 1): ok = false
	# griffes niv 5 : critique ×2, vitesse
	for i in 4:
		gs.upgrade_weapon("griffes", pl)
	gs.prog["weapon"] = "griffes"
	var wg: Dictionary = pl.weapon()
	print("griffes niv", gs.weapon_level("griffes"), " crit ", wg["crit"], " cd ", wg["cd"])
	if absf(float(wg["crit"]) - 0.16) > 0.001: ok = false
	# prix croissants
	print("prix faux : ", W.up_price("faux", 2), " ", W.up_price("faux", 3), " ", W.up_price("faux", 4), " ", W.up_price("faux", 5))
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

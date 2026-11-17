extends SceneTree
# Niveaux d'emblème (1 à 3) : prérequis, prix, effets renforcés
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
	var C = load("res://scripts/charms.gd")
	var ok := true
	pl.geo = 99999
	gs.prog["owned"] = [C.GLASS_HEART, C.MIRROR]
	gs.prog["equipped"] = [C.GLASS_HEART, C.MIRROR]
	gs.prog["charm_lv"] = {}
	pl.apply_equipment()
	var hp1: int = pl.max_hp
	gs.record = 1
	var e: String = gs.upgrade_charm(C.GLASS_HEART, pl)
	print("palier 1 -> niv2 : '", e, "'")
	if e == "": ok = false
	gs.record = 4
	print("niv2 : '", gs.upgrade_charm(C.GLASS_HEART, pl), "' niv3 : '", gs.upgrade_charm(C.GLASS_HEART, pl), "' max : '", gs.upgrade_charm(C.GLASS_HEART, pl), "'")
	print("Cœur de Verre : max_hp ", hp1, " -> ", pl.max_hp)
	if pl.max_hp != hp1 + 2: ok = false
	print("parade niv1 ", pl.parry_window())
	gs.upgrade_charm(C.MIRROR, pl)
	print("parade niv2 ", pl.parry_window())
	if absf(pl.parry_window() - 0.42) > 0.001: ok = false
	print("non possédé : '", gs.upgrade_charm(C.BRUTE, pl), "'")
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

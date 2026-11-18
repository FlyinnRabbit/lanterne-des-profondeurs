extends SceneTree
# Captures du Scriptorium : les 5 pages, avec des registres d'exemple.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await process_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	var lang: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "fr"
	st.set_value("language", ["", "fr", "en", "es", "de"].find(lang))
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 5
	gs.unlocked = 6
	gs.prog["owned"] = [0, 2, 4, 5, 7, 9, 11, 13, 14, 16, 17, 18, 19, 20, 21, 23, 25, 28, 30, 33, 36, 38, 40, 41]
	gs.prog["equipped"] = [7, 19]
	gs.journal = {"c": {"kills": 1284, "elites": 97, "bosses": 11, "damage": 6930, "crits": 412, "parries": 305, "perfect": 88,
		"heals": 140, "spells": 63, "ults": 21, "hurt": 389, "deaths": 14, "jumps": 8512, "dashes": 2931, "pogos": 604,
		"thrusts": 233, "pushes": 171, "plunges": 58, "descents": 9, "chests": 41, "winches": 17, "geo_in": 5420, "geo_out": 4780,
		"time": 11520.0, "flawless": 2},
		"w": {"griffes": 2210, "aiguille": 1030, "marteau": 380, "fouet": 190},
		"mobs": {"crawler": {"k": 412, "e": 31, "hurt": 40, "b": ["Les Jardins Fongiques", "L'Ossuaire"]}, "flyer": {"k": 288, "e": 22, "hurt": 55, "b": []},
			"spitter": {"k": 190, "e": 14, "hurt": 31, "b": []}, "hopper": {"k": 156, "e": 9, "hurt": 12, "b": []},
			"guard": {"k": 97, "e": 11, "hurt": 23, "b": ["La Forge Ardente", "L'Ossuaire"]}, "bomber": {"k": 64, "e": 0, "hurt": 8, "b": []},
			"weaver": {"k": 41, "e": 6, "hurt": 9, "b": []}, "lancer": {"k": 36, "e": 4, "hurt": 14, "b": []}},
		"bosses": {"gardien": {"w": 3, "l": 1, "best": 72.0, "nohit": true}, "colosse": {"w": 1, "l": 2, "best": 198.0, "nohit": false}, "cerbere": {"w": 1, "l": 0, "best": 250.0, "nohit": false}},
		"charms": {"20": {"p": 4, "b": "Les Mines de Cristal", "t": 4300.0}, "7": {"p": 0, "b": "", "t": 6000.0}, "19": {"p": 2, "b": "La Ruche Bourdonnante", "t": 0.0}},
		"rec": {"kills_run": 212, "dmg_run": 1340, "crits_run": 61, "fast_palier": 431.0, "streak": 7}}
	change_scene_to_file("res://main.tscn")
	await _f(3)
	paused = false
	var main = current_scene
	var sc = main.scriptorium
	print("ouverture")
	sc.open()
	print("ouvert")
	await _f(5)
	for p in 5:
		print("page ", p)
		sc._set_page(p)
		if p == 2:
			sc._set_sel(4)
		if p == 3:
			sc._set_sel(7)
		if p == 4:
			sc._set_sel(40)
		sc.focus_grid = p >= 2
		await _f(8)
		root.get_viewport().get_texture().get_image().save_png("/tmp/journal/scr_page%d_%s.png" % [p, lang])
	sc.close()
	quit()

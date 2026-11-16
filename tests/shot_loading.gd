extends SceneTree
# Captures des écrans de chargement (lancement, boutique, ascenseur aller et retour) et du son des chaînes.
var LoadingScript  # chargé au lancement (les autoloads doivent exister)
func _initialize() -> void:
	_run()
func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout
func _snap(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/load_%s.png" % name)
func _run() -> void:
	await process_frame
	LoadingScript = load("res://scripts/loading.gd")
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _wait(1.0)
	# lancement
	LoadingScript.launched = false
	LoadingScript.launch(self)
	for k in [0.25, 0.75, 1.6, 2.25, 2.4]:
		var ks := [0.25, 0.75, 1.6, 2.25, 2.4]
		var i := ks.find(k)
		if k == 2.4:
			for c in root.get_children():
				if c.get_script() == LoadingScript:
					c.t = 2.2      # image finale (titre entièrement allumé), indépendamment de la lenteur de l'écran virtuel
		await _wait(k - (0.0 if i == 0 else ks[i - 1]))
		await _snap("launch_%d" % int(k * 100))
	await _wait(1.0)
	# boutique
	LoadingScript.shop(self, "shop", "Marchand")
	main.hub_ui.open_shop()
	var last := 0.0
	for k in [0.06, 0.3, 0.55, 0.72]:
		await _wait(k - last)
		last = k
		await _snap("shop_%d" % int(k * 100))
	await _wait(0.6)
	await _snap("shop_after")
	main.hub_ui.close_all()
	for sk in [["smith", "Forgeronne"], ["tailor", "Tailleuse"], ["cartographer", "Cartographe"], ["arsenal", "Arsenal"], ["elder", "Ancien"]]:
		LoadingScript.shop(self, sk[0], sk[1])
		await _wait(0.3)
		await _snap("shop_" + sk[0])
		await _wait(0.8)
	# ascenseur : descente
	main.hub_ui.open_elevator()
	await _wait(0.2)
	main.hub_ui._descend(2)
	last = 0.0
	for k in [0.3, 1.0, 1.8]:
		await _wait(k - last)
		last = k
		await _snap("lift_%d" % int(k * 100))
	var tt := 1.8
	while tt < 6.0:
		await _wait(0.1)
		tt += 0.1
		var alive := false
		for c in root.get_children():
			if c.get_script() == LoadingScript:
				alive = true
				if int(tt * 10) % 5 == 0:
					print("  t=%.2f vitesse=%d arrêt=%.2f sortie=%s fondu=%.2f scène changée=%s" % [c.t, c.speed, c.stop_t, c.leaving, c.fade, current_scene != c.scene_at_start])
				if c.stop_t >= 0.0 and not c.has_meta("snapped"):
					c.set_meta("snapped", true)
					await _snap("lift_stop")
		if not alive:
			break
	print("ascenseur terminé après %.1f s, scène : %s, mode %s, palier %d" % [tt, current_scene.name, gs.mode, gs.palier])
	await _wait(0.5)
	await _snap("lift_after")
	# remontée
	LoadingScript.lift(self, 2, true, func(): pass)
	await _wait(1.0)
	await _snap("lift_up")
	print("ok chargement")
	quit()

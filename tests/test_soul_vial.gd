extends SceneTree
# Le flacon d'âme doit rester visible à toutes les hauteurs et à tout moment de l'ondulation
# (avant : le polygone ondulé échouait parfois à se trianguler et le liquide disparaissait).
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
	var main = current_scene
	var hud = main.hud
	var pl = main.player
	var bad := 0
	var total := 0
	for soul in [11, 20, 33, 45, 50, 66, 80, 99]:
		pl.soul = soul
		hud.shown_soul = float(soul)
		for k in 40:
			hud.t = k * 0.137
			hud.shown_soul = float(soul)
			hud.queue_redraw()
			await process_frame
			var img: Image = root.get_viewport().get_texture().get_image()
			# pixel au fond du flacon (centre 72,72, rayon 36) : doit être bleu clair
			var px: Color = img.get_pixel(72, 72 + 33)
			total += 1
			if px.b < 0.5:
				bad += 1
	for soul in [0, 33, 66, 99]:
		pl.soul = soul
		hud.shown_soul = float(soul)
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 220, 150)).save_png("/tmp/vial_%d.png" % soul)
	print("images sans liquide : %d / %d" % [bad, total])
	print("RÉSULTAT : ", "OK" if bad == 0 else "ÉCHEC")
	quit()

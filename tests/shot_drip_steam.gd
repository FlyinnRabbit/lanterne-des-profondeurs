extends SceneTree
# Aperçu zoomé : goutte acide (pousse, alerte, chute) et jet de vapeur (alerte, actif)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _snap(path: String) -> void:
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(path)
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
	pl.sitting = false
	var feet: float = pl.get_rect().end.y
	var base := Vector2(pl.global_position.x + 60, feet)
	pl.visible = false
	var dr1 = main._make_trap("drip", base + Vector2(-90, -120), {})
	var dr2 = main._make_trap("drip", base + Vector2(-30, -120), {})
	var st1 = main._make_trap("steam", base + Vector2(30, 0), {"dir": 1.0})
	main.spawn_projectile(base + Vector2(-60, -60), Vector2(0, 420), {"kind": "drop", "radius": 6.0, "gravity": 0.0, "life": 5.0})
	var st2 = main._make_trap("steam", base + Vector2(30, 70), {"dir": 1.0})
	# palette de la Citadelle Engloutie pour les pièges (aperçu)
	for bb in load("res://scripts/biomes.gd").all():
		if bb["id"] == "citadelle": main.pal = bb["pal"]
	var cam: Camera2D = main.camera
	cam.zoom = Vector2(3, 3)
	cam.offset = Vector2(60, -40)
	for i in 4:
		dr1.t = dr1.CYCLE["drip"][0] * 0.6
		dr2.t = dr2.CYCLE["drip"][0] + dr2.CYCLE["drip"][1] * 0.5
		st1.t = st1.CYCLE["steam"][0] + st1.CYCLE["steam"][1] * 0.6
		for p in get_nodes_in_group("projectiles"):
			p.vel = Vector2(0, 420)
			p.global_position = base + Vector2(-60, -60)
		await process_frame
	await _snap("/tmp/ds1.png")
	for i in 4:
		st1.t = st1.CYCLE["steam"][0] + st1.CYCLE["steam"][1] + st1.CYCLE["steam"][2] * 0.4
		await process_frame
	await _snap("/tmp/ds2.png")
	quit()

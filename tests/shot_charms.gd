extends SceneTree
# Captures des emblèmes : inventaire, marchand, emblème au sol. Usage : -s tests/shot_charms.gd -- <prefixe>
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	await process_frame
	for i in n:
		await physics_frame
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s.png" % n)
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["owned"] = range(42)
	gs.prog["equipped"] = [0, 6, 23]
	gs.prog["notches"] = 6
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _frames(10)
	var main = current_scene
	main.player.sitting = true
	main.inventory.open()
	await _frames(6)
	await _snap(pre + "_inventaire")
	main.inventory.close()
	paused = false
	await _frames(4)
	gs.prog["owned"] = []
	gs.prog["equipped"] = []
	main.player.geo = 900
	main.hub_ui.open_shop()
	await _frames(6)
	await _snap(pre + "_marchand")
	main.hub_ui.close_all()
	paused = false
	await _frames(4)
	main.hud.visible = false
	var pp: Vector2 = main.player.global_position
	for k in 4:
		var p = main._make_prop("charm", pp + Vector2(60 + k * 50, -40), gs.charm(k * 3)["color"], 1.6)
		p.color = gs.charm(k * 3)["color"]
		p.charm_id = k * 3
	main.camera.zoom = Vector2(3.0, 3.0)
	await _frames(20)
	await _snap(pre + "_emblemes_sol")
	print("ok charms")
	quit()

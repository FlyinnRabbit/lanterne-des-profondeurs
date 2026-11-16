extends SceneTree
# Captures des coups (aiguille, finisher, marteau, tourbillon) et des armes tenues. Usage : -- <prefixe>
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10:
		await physics_frame
	var main = current_scene
	main.hud.visible = false
	var p = main.player
	p.global_position = Vector2(24 * 32, p.global_position.y)
	await _frames(20)
	main.camera.zoom = Vector2(3.5, 3.5)
	var shots := [["aiguille", "slash", 2], ["aiguille", "slash", 4], ["aiguille", "finisher", 4], ["marteau", "slash", 3], ["aiguille", "spin", 6], ["fouet", "idle", 0], ["marteau", "idle", 0], ["shuriken", "idle", 0], ["aiguille", "idle", 0]]
	var i := 0
	for sh in shots:
		gs.trial_weapon = sh[0]
		p.facing = 1
		await _frames(2)
		if sh[1] != "idle":
			p._start_attack(sh[1], Vector2(1, 0))
			await _frames(sh[2])
		paused = true
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_atk_%d.png" % [pre, i])
		paused = false
		p.attack_t = 0.0
		await _frames(12)
		i += 1
	print("ok attacks ", i)
	quit()

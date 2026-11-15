extends SceneTree
class Dbg extends Node2D:
	var pl
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if pl.attack_t > 0.0:
			draw_rect(pl.attack_rect(), Color(1, 0, 0, 0.8), false, 2.0)
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["weapon"] = "fouet"
	change_scene_to_file("res://main.tscn")
	paused = false
	for i in 10:
		await physics_frame
	var main = current_scene
	var pl = main.player
	var d := Dbg.new()
	d.pl = pl
	d.z_index = 50
	main.add_child(d)
	var n := 0
	for spot in [Vector2(28 * 32, 16 * 32), Vector2(3 * 32, 16 * 32)]:
		pl.global_position = spot
		pl.facing = 1 if n == 0 else -1
		for i in 40:
			await physics_frame
		pl.attack_cd = 0.0
		Input.action_press("attack"); await physics_frame; await physics_frame; Input.action_release("attack")
		await physics_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/whip_%d.png" % n)
		print("zone de coup : ", pl.attack_rect())
		n += 1
		for i in 60:
			await physics_frame
	quit()

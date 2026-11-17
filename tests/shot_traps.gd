extends SceneTree
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
	pl.sitting = false
	var base: Vector2 = Vector2(roundf(pl.global_position.x / 32.0) * 32.0 + 16.0, roundf((pl.global_position.y + 20) / 32.0) * 32.0)
	pl.global_position.x -= 400
	var specs := [["drip", {}, 1], ["steam", {"dir": 1.0}, 2], ["crystal", {}, 2], ["book", {}, 1], ["hand", {}, 9]]
	var trs := []
	for i in specs.size():
		var off := Vector2(-300 + i * 150, -150 if specs[i][0] == "drip" else 0)
		var tr = main._make_trap(specs[i][0], base + off, specs[i][1])
		trs.append(tr)
	for frame in 3:
		for i in trs.size():
			var tr = trs[i]
			if specs[i][2] == 9:
				tr.hand_state = "grab"
				tr.hand_t = 0.5
			elif specs[i][2] >= 0:
				var c: Array = tr.CYCLE[tr.kind]
				tr.t = c[0] + (c[1] * 0.6 if specs[i][2] == 1 else c[1] + c[2] * 0.45)
			else:
				tr.turn_t = 0.12
		await process_frame
	get_root().get_texture().get_image().save_png("/tmp/traps.png")
	quit()

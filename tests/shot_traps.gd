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
	var specs := [["spikes", {}, 2], ["spikes", {}, 1], ["gas", {}, 2], ["geyser", {"element": "fire"}, 2], ["geyser", {"element": "ice"}, 2], ["dart", {"dir": 1.0}, -1]]
	var trs := []
	for i in specs.size():
		var tr = main._make_trap(specs[i][0], base + Vector2(-260 + i * 110, 0), specs[i][1])
		trs.append(tr)
	for frame in 3:
		for i in trs.size():
			var tr = trs[i]
			if specs[i][2] >= 0:
				var c: Array = tr.CYCLE[tr.kind]
				tr.t = c[0] + (c[1] * 0.6 if specs[i][2] == 1 else c[1] + c[2] * 0.4)
			else:
				tr.turn_t = 0.12
		await process_frame
	get_root().get_texture().get_image().save_png("/tmp/traps.png")
	quit()

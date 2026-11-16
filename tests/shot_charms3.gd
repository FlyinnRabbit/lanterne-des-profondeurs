extends SceneTree
# Capture de l'inventaire avec les 20 emblèmes.
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
	gs.prog["owned"] = range(gs.charm_count())
	gs.prog["equipped"] = [12, 16, 19]
	gs.prog["notches"] = 8
	var main = current_scene
	main.player.sitting = true
	for i in 20:
		await process_frame
	main.inventory.open()
	for i in 10:
		await process_frame
	var inv = main.inventory
	if "slots" in inv and inv.slots.size() > 19:
		inv.slots[19].grab_focus()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/charms3.png")
	quit()

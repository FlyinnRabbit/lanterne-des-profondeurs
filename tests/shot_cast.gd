extends SceneTree
# Galerie rapprochée du héros et des ennemis. Usage : -s tests/shot_cast.gd -- <prefixe>
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var pre := "now"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		pre = args[0]
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	await _frames(4)
	var main = current_scene
	main.hud.visible = false
	var p = main.player
	p.global_position = Vector2(30 * 32, p.global_position.y)
	await _frames(20)
	var base: Vector2 = p.global_position
	var names := ["crawler", "hopper", "spitter", "guard", "bomber", "lancer", "flyer", "weaver", "wraith"]
	var i := 0
	var made := []
	for n in names:
		var e := CharacterBody2D.new()
		e.set_script(load("res://scripts/%s.gd" % n))
		e.main = main
		var fly: bool = n in ["flyer", "weaver", "wraith"]
		e.position = base + Vector2(70 + (i if not fly else i - 6) * 62, -70.0 if fly else -10.0)
		main.add_child(e)
		made.append(e)
		i += 1
	await _frames(25)
	for e in made:
		e.set_physics_process(false)
	p.set_physics_process(false)
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2(1.9, 1.9)
	main.camera.global_position = base + Vector2(300, -40)
	main.camera.limit_right = 100000
	await _frames(6)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_cast.png" % pre)
	print("ok cast")
	quit()

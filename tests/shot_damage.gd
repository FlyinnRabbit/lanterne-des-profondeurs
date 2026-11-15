extends SceneTree
# Capture : barres de vie des ennemis et journal des dégâts
func _initialize() -> void:
	_run()
func _f(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	paused = false
	await _f(6)
	var main = current_scene
	var pl = main.player
	pl.global_position = Vector2(36 * 32, 16 * 32)
	await _f(10)
	var foes := []
	for spec in [[main.CrawlerScript, 60, false], [main.LancerScript, 150, true], [main.SpitterScript, 230, false]]:
		var e := CharacterBody2D.new()
		e.set_script(spec[0])
		e.main = main
		e.elite = spec[2]
		e.position = pl.global_position + Vector2(spec[1], -10)
		main.add_child(e)
		foes.append(e)
	await _f(10)
	for e in foes:
		e.set_physics_process(false)
	foes[0].take_hit(1, Vector2.RIGHT)
	await _f(30)
	foes[1].take_hit(2, Vector2.RIGHT)
	await _f(10)
	pl.attack_kind = "finisher"
	pl.attack_t = 0.1
	foes[1].take_hit(2, Vector2.RIGHT)
	pl.attack_kind = "spin"
	pl.attack_t = 0.1
	foes[2].take_hit(4, Vector2.RIGHT)
	await _f(8)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/damage.png")
	quit()

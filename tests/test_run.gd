extends SceneTree
var DIFFS_TO_TEST := [1, 3]
var FRAMES := 400
# Test automatique : charge chaque niveau dans plusieurs difficultés et simule des entrées.
# Lancer : godot --headless -s res://tests/test_run.gd

func _initialize() -> void:
	_run()

func _press(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var stages := [["tutorial", 1, 1], ["hub", 1, 1], ["descent", 1, 1], ["descent", 1, 2], ["descent", 2, 2], ["descent", 4, 1], ["descent", 6, 2]]
	for diff in DIFFS_TO_TEST:
		for st in stages:
			gs.difficulty = diff
			gs.show_title = false
			gs.mode = st[0]
			gs.palier = st[1]
			gs.step = st[2]
			change_scene_to_file("res://main.tscn")
			await process_frame
			await process_frame
			var main = current_scene
			print("== diff %d %s palier %d niveau %d : %s (%d x %d)" % [diff, st[0], st[1], st[2], main.level["name"], main.map_size.x, main.map_size.y])
			if gs.show_title:
				main.menu._open_difficulty()
				main.menu._open_options()
				main.menu._back_to_pause()
				main.menu.close()
				paused = false
			for f in FRAMES:
				if not is_instance_valid(main):
					print("   (passage au niveau suivant atteint)")
					break
				_press("move_right", true)
				_press("jump", f % 50 < 20)
				_press("attack", f % 16 == 0)
				_press("down", f % 100 > 80)
				_press("dash", f % 90 == 0)
				_press("parry", f % 70 == 5)
				_press("focus", false)
				if f == 200:
					main.player.ult = 100
					_press("ultimate", true)
				if f == 201:
					_press("ultimate", false)
				if f % 120 == 60 and not main.player.dead:
					# avance par téléportation pour couvrir tout le niveau
					var tx: float = main.player.global_position.x + 600.0
					main.player.global_position = Vector2(tx, 10 * 32)
				if f == 500 and main.boss and is_instance_valid(main.boss):
					main.player.global_position = main.boss.global_position + Vector2(-260, -20)
				if f == 700 and main.boss and is_instance_valid(main.boss):
					main.boss.take_hit(99999, Vector2.RIGHT)
				await physics_frame
			for a in ["move_right", "jump", "attack", "down", "dash", "parry", "ultimate"]:
				_press(a, false)
			await process_frame
			main = current_scene
			if main == null:
				await process_frame
				main = current_scene
			main.inventory.open()
			await process_frame
			main.inventory._toggle(0)
			main.inventory.close()
			main.menu.open()
			main.menu._open_controls()
			main.menu._open_options()
			main.menu._open_difficulty()
			main.menu.close()
			var enemies = get_nodes_in_group("enemies").size()
			print("   ennemis vivants: %d, joueur hp %d/%d, mort: %s, geo %d" % [enemies, main.player.hp, main.player.max_hp, main.player.dead, main.player.geo])
			await create_timer(0.1).timeout
	print("TEST TERMINÉ")
	quit()

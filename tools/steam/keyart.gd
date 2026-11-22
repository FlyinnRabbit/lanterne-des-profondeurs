extends SceneTree
# Illustrations pour la page Steam (rendu 4K) : titre sans menu, combats de boss, vues de biomes.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
var gs
func _initialize() -> void:
	_run()
func _f(n: int) -> void:
	for i in n:
		await process_frame
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/keyart/%s.png" % name)
	print("shot ", name)
func _hero(main) -> void:
	var c = gs.cos
	var want := {"cape": "cape_champion", "hat": "hat_cornes", "scarf": "scarf_memoire"}
	for k in want:
		c.owned[want[k]] = true
		c.equipped[k] = want[k]
	main.hud.visible = false
	main.player.max_hp = 999
	main.player.hp = 999
func _load(m: String, palier: int, step: int) -> Node:
	gs.mode = m; gs.palier = palier; gs.step = step
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(3)
	_hero(current_scene)
	return current_scene
func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	var S = root.get_node("Settings")
	S.show_hints = false
	S.gfx_quality = 0
	var args: Array = OS.get_cmdline_user_args()
	# --- titre sans menu
	if args.is_empty() or "title" in args:
		S.zoom = 1.25
		var main = await _load("hub", 1, 1)
		main.menu.open_title()
		await _f(60)
		main.menu.title_wrap.visible = false
		for k in 4:
			await _f(25)
			await _shot("title_%d" % k)
		main.menu.visible = false
		paused = false
	# --- combats de boss
	for id in ["chevalier", "cerbere", "ombre", "gardien", "reine", "oeil"]:
		if not args.is_empty() and not (id in args):
			continue
		S.zoom = 1.6
		gs.run_seed = 4242
		gs._cache.clear()
		var pal := 7
		if id in gs.FINALS:
			gs.prog["finals_drawn"] = {"7": id}
		else:
			for p in range(1, 7):
				if gs.boss_for(p) == id:
					pal = p
		var main = await _load("descent", pal, 2)
		var boss = main.boss
		var pl = main.player
		pl.global_position = boss.global_position + Vector2(-260, -10)
		main.camera.position_smoothing_enabled = false
		for f in 60:
			pl.hp = 999
			pl.invuln_t = 1.0
			await process_frame
		main.camera.position_smoothing_enabled = true
		for f in 200:
			pl.hp = 999
			var dx: float = boss.global_position.x - pl.global_position.x
			Input.action_release("move_left"); Input.action_release("move_right")
			if absf(dx) > 140.0:
				Input.action_press("move_right" if dx > 0 else "move_left")
			if f % 18 == 2: Input.action_press("attack")
			if f % 18 == 4: Input.action_release("attack")
			if f % 50 == 25: Input.action_press("jump")
			if f % 50 == 36: Input.action_release("jump")
			await process_frame
			if f % 40 == 39:
				await _shot("boss_%s_%d" % [id, f / 40])
		for a in ["move_left", "move_right", "attack", "jump"]:
			Input.action_release(a)
	# --- vues de biomes (plans larges)
	var n := 0
	for b in Biomes.all():
		if not args.is_empty() and not (b["id"] in args) and not ("biomes" in args):
			continue
		S.zoom = 1.1
		gs.run_seed = 900 + n
		n += 1
		var map: Array = LevelGen.new().generate(b, 1234 + n, 3, "", false, gs.DIFFS[1])
		gs._cache.clear()
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": map, "music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 1234 + n}
		var main = await _load("descent", 2, 1)
		var pl = main.player
		for ch in main.get_children():
			if ch.get_script() and ch.get_script().resource_path.ends_with("midground.gd") and ch.scenes.size() > 0:
				var s0 = ch.scenes[mini(1, ch.scenes.size() - 1)]
				pl.global_position = s0.position / (1.0 - ch.FACTOR) + Vector2(-140, -30)
		pl.velocity = Vector2.ZERO
		main.camera.position_smoothing_enabled = false
		await _f(40)
		await _shot("biome_%s" % b["id"])
	quit()

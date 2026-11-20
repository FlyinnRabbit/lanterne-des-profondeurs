extends SceneTree
# Salle des leviers : un mauvais ordre relève les leviers, le bon ordre (runes de la plaque)
# ouvre la herse du caveau ; en descente, l'énigme résolue le reste au retour.
# --shots : captures /tmp/shots/levers_*.png
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _shot(n: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/shots/levers_%s.png" % n)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var b: Dictionary = {}
	for x in Biomes.all():
		if x["id"] == "antique":
			b = x
	var map := []
	var sd := 0
	var gen := LevelGen.new()
	for s in range(1, 400):
		map = gen.generate(b, s, 3, "", false, gs.DIFFS[1])
		if "".join(map).contains("0"):
			sd = s
			break
	print("graine avec salle des leviers : ", sd)
	var ok := sd > 0
	gs.run_seed = 77
	gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": map,
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": sd}
	gs.mode = "descent"; gs.palier = 2; gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 20: await physics_frame
	var main = current_scene
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var lv := []
	for o in main.levers:
		if o.kind == "lever":
			lv.append(o)
	lv.sort_custom(func(a, c): return int(a.get_meta("rune")) < int(c.get_meta("rune")))
	print("leviers : ", lv.size(), "  ordre : ", main.lever_order, "  herse fermée : ", main.lever_gate.closed)
	ok = ok and lv.size() == 3 and main.lever_gate.closed
	var pl = main.player
	pl.global_position = lv[1].position + Vector2(-20, -30)
	for i in 30: await physics_frame
	await _shot("avant")
	# mauvais ordre : on commence par une rune qui n'est pas la première
	var wrong: int = main.lever_order[1]
	main._pull_lever(lv[wrong])
	print("mauvais levier → relève prévue : ", main.lever_reset_t > 0.0)
	ok = ok and main.lever_reset_t > 0.0
	for i in 600:
		await process_frame
		if current_scene.lever_reset_t <= 0.0:
			break
	await process_frame
	var all_up := true
	for o in lv:
		all_up = all_up and not o.lit
	print("leviers relevés : ", all_up, "  herse fermée : ", main.lever_gate.closed)
	ok = ok and all_up and main.lever_gate.closed
	for r in main.lever_order:
		main._pull_lever(lv[r])
		for i in 5: await physics_frame
	print("bon ordre → herse fermée : ", main.lever_gate.closed)
	ok = ok and not main.lever_gate.closed
	for i in 50: await process_frame
	pl.global_position = main.lever_gate.rect.get_center() + Vector2(-60, 20)
	for i in 30: await physics_frame
	await _shot("ouvert")
	print("énigme notée comme résolue : ", gs.is_collected(main.lever_key))
	ok = ok and gs.is_collected(main.lever_key)
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

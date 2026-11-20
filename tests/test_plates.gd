extends SceneTree
# Plaque de glace : on y glisse (l'élan se garde) ; dalle de cristal : armée en marchant dessus,
# puis des éclats jaillissent et blessent. Gouttes et spores prennent la couleur du biome.
# --shots : captures /tmp/shots/trap_*.png
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _load(gs, bid: String) -> Node:
	var b: Dictionary = {}
	for x in Biomes.all():
		if x["id"] == bid:
			b = x
	gs.run_seed = 99
	var gen := LevelGen.new()
	gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, 555, 3, "", false, gs.DIFFS[1]),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 555}
	gs.mode = "descent"; gs.palier = 2; gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 30: await physics_frame
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	return current_scene
func _floor_spot(main) -> Vector2:
	var pl = main.player
	return Vector2(pl.global_position.x, pl.get_rect().end.y)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	# --- glace
	var main = await _load(gs, "glace")
	var pl = main.player
	var f := _floor_spot(main)
	var plate = main._make_trap("iceplate", f + Vector2(120, 0), {})
	pl.global_position.x = f.x + 60
	Input.action_press("move_right")
	for i in 40: await physics_frame
	Input.action_release("move_right")
	var vx0: float = pl.velocity.x
	for i in 12: await physics_frame
	var vx1: float = pl.velocity.x
	print("glace : vitesse en lâchant ", int(vx0), " → 0,1 s plus tard ", int(vx1), " (sur la plaque : ", pl.ice_t > 0.0, ")")
	ok = ok and vx1 > 100.0
	if shots:
		pl.global_position.x = f.x + 20
		for i in 20: await physics_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/shots/trap_glace.png")
	# --- cristal
	main = await _load(gs, "cristal")
	pl = main.player
	f = _floor_spot(main)
	var cp = main._make_trap("crystalplate", f + Vector2(0, 0), {})
	var hp0: int = pl.hp
	pl.invuln_t = 0.0
	for i in 130: await physics_frame
	print("cristal : état ", cp.plate_state, " ; vie ", hp0, " → ", pl.hp)
	ok = ok and pl.hp < hp0
	if shots:
		var cp2 = main._make_trap("crystalplate", f + Vector2(150, 0), {})
		cp2.plate_state = "burst"; cp2.plate_t = 0.25
		var cp3 = main._make_trap("crystalplate", f + Vector2(-150, 0), {})
		cp3.plate_state = "arm"; cp3.plate_t = 10.0
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/shots/trap_cristal.png")
	# --- couleurs
	for bid in ["ruche", "jungle", "profondeurs"]:
		main = await _load(gs, bid)
		f = _floor_spot(main)
		var dx := 230.0
		var cy: float = f.y - 40.0
		while cy > f.y - 400.0 and not main.is_solid_at(Vector2(f.x + dx, cy - 2.0)):
			cy -= 4.0
		var d = main._make_trap("drip", Vector2(f.x + dx, cy), {"floor_y": f.y})
		d.t = 2.75
		var g = main._make_trap("gas", f + Vector2(110, 0), {})
		g.t = 2.9
		print(bid, " : goutte ", d._drip_col(), " ; spores ", g._gas_cols()[1])
		if shots:
			for i in 8: await physics_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("/tmp/shots/trap_%s.png" % bid)
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

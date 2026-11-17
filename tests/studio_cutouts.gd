extends SceneTree
# « Studio » : rend chaque créature seule, sur fond transparent, en grand (zoom ×3),
# pour les PDF et la bande-annonce.  godot --path . -s tests/studio_cutouts.gd -- <dossier>
# Sortie : <dossier>/mob_<id>.png, boss_<id>.png, hero.png (rognés au contenu)
var out := "/tmp/cutouts"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()

func _f(n: int) -> void:
	for i in n:
		await process_frame

# cache tout sauf les nœuds gardés ; plus de voile sombre ni de lumières
func _isolate(main, keep: Array) -> void:
	# on garde aussi l'ancêtre direct (sous main) de chaque nœud gardé
	var k2 := keep.duplicate()
	for n in keep:
		var a = n
		while a and a.get_parent() and a.get_parent() != main:
			a = a.get_parent()
		if a and not a in k2:
			k2.append(a)
	keep = k2
	for c in main.get_children():
		if c in keep:
			continue
		if c is CanvasModulate:
			c.color = Color(1, 1, 1)
		elif c is CanvasItem:
			c.visible = false
		elif c is CanvasLayer:
			c.visible = false
	root.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))

func _snap(main, target: Node2D, name: String, zoom := 3.0, offset := Vector2(0, -10)) -> void:
	if not is_instance_valid(target):
		return
	var cam: Camera2D = main.camera
	cam.position_smoothing_enabled = false
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	cam.global_position = target.global_position + offset
	cam.zoom = Vector2(zoom, zoom)
	if "shake_amt" in main:
		main.shake_amt = 0.0
	cam.offset = Vector2.ZERO
	await _f(3)
	if not is_instance_valid(target):
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	# rognage au contenu en ignorant les pixels presque transparents (poussière, halos)
	var mask: Image = img.duplicate()
	for y in mask.get_height():
		for x in mask.get_width():
			if mask.get_pixel(x, y).a < 0.35:
				mask.set_pixel(x, y, Color(0, 0, 0, 0))
	var r: Rect2i = mask.get_used_rect()
	if r.size.x > 4 and r.size.y > 4:
		img = img.get_region(r.grow(6).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	img.save_png("%s/%s.png" % [out, name])
	print("capture ", name, " ", img.get_size())

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	st.show_hints = false
	st.enemy_bars = false
	gs.show_title = false
	gs.difficulty = 1
	var only_bosses: bool = OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "bosses"
	var only_new: bool = OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "new"
	# --- héros et ennemis ordinaires, au Sanctuaire (sol invisible mais solide)
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	pl.global_position = Vector2(30 * 32, 16 * 32)
	await _f(30)
	_isolate(main, [pl])
	await _snap(main, pl, "hero", 4.0, Vector2(0, -6))
	pl.visible = false
	pl.max_hp = 9999
	pl.hp = 9999
	var spot: Vector2 = pl.global_position
	var mobs := {"crawler": main.CrawlerScript, "flyer": main.FlyerScript, "spitter": main.SpitterScript, "hopper": main.HopperScript,
		"guard": main.GuardScript, "bomber": main.BomberScript, "weaver": main.WeaverScript, "lancer": main.LancerScript, "wraith": main.WraithScript,
		"monkey": main.MonkeyScript, "mimic": main.MimicScript, "moth": main.MothScript, "mole": main.MoleScript}
	var ids: Array = ["monkey", "mimic", "moth", "mole"] if only_new else ([] if only_bosses else mobs.keys())
	for id in ids:
		for elite in [false, true]:
			if elite and not id in ["crawler", "flyer", "spitter", "hopper", "guard"]:
				continue
			var e := CharacterBody2D.new()
			e.set_script(mobs[id])
			e.main = main
			e.elite = elite
			pl.invuln_t = 9999.0
			pl.hp = 9999
			e.position = spot + Vector2(0, -20 if id in ["flyer", "wraith"] else -4)
			main.add_child(e)
			await _f(4 if id == "bomber" else 25)
			if not is_instance_valid(e):
				continue
			e.set_physics_process(false)
			# portraits : la mimique réveillée, la taupe sortie de terre
			if id == "mimic":
				e.state = "hop"
			elif id == "mole":
				e.state = "exposed"
			elif id == "moth":
				e.display = true      # n'assombrit plus l'écran pendant la photo
				main.moth_dim = 0.0
				if main.dark_rect:
					main.dark_rect.visible = false
			e.queue_redraw()
			# la poussière d'apparition retombe ; projectiles effacés
			for pr in get_nodes_in_group("projectiles"):
				pr.queue_free()
			for c in main.get_children():
				if c.get_script() == main.FxScript or c is GPUParticles2D or c is CPUParticles2D:
					c.queue_free()
			await _f(40)
			if not is_instance_valid(e):
				print("disparu : ", id)
				continue
			if "facing" in e:
				e.facing = -1
			if "dir" in e:
				e.dir = -1
			await _f(2)
			if not is_instance_valid(e):
				continue
			await _snap(main, e, "mob_%s%s" % [id, "_elite" if elite else ""], 4.0, Vector2(0, -12))
			e.queue_free()
			await _f(2)
	if only_new:
		quit()
		return
	# --- boss, chacun dans son arène
	for id in ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre", "cerbere", "centaure", "oeil"]:
		var pal := 1
		for p in range(1, 8):
			if gs.boss_for(p) == id:
				pal = p
				break
		if id in gs.FINALS:
			pal = 7
			for sd in range(1, 400):
				gs.run_seed = sd
				gs._cache.clear()
				if gs.boss_for(7) == id:
					break
		gs.mode = "descent"
		gs.palier = pal
		gs.step = 2
		root.transparent_bg = false
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(20)
		main = current_scene
		var boss = main.boss
		boss.set_physics_process(false)
		for e in get_nodes_in_group("enemies"):
			if e != boss:
				e.queue_free()
		# la caméra suit le héros : on le pose (invisible, invulnérable) sur le boss
		main.player.invuln_t = 9999.0
		main.player.max_hp = 9999
		main.player.hp = 9999
		main.player.set_physics_process(false)
		main.player.global_position = boss.global_position
		_isolate(main, [boss])
		var big: bool = id in ["colosse", "cerbere", "centaure", "oeil", "ombre"]
		await _snap(main, boss, "boss_%s" % id, 2.0 if big else 2.6, Vector2(0, -50 if big else -24))
	print("FIN STUDIO")
	quit()

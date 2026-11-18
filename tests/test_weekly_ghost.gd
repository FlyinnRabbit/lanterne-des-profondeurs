extends SceneTree
# Défi de la semaine (règles imposées), fantôme (enregistrement + silhouette), semaine ISO
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	root.get_node("Settings").board_online = false
	var ok := true
	var ws: int = gs.week_seed()
	print("week_seed=", ws)
	if ws < 202001 or ws > 209953: ok = false
	var r: Dictionary = gs.weekly_rules(ws)
	print("rules ", r)
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	gs.start_weekly(current_scene.player)
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	print("mode=", gs.mode, " weekly=", gs.weekly, " curse=", gs.curse, " weapon=", gs.weapon(), " palier=", gs.palier)
	if not (gs.weekly and gs.curse == r["curse"] and gs.weapon() == r["weapon"] and gs.palier == r["palier"]): ok = false
	# fantôme : on lui donne un parcours, il doit apparaître et bouger
	var p0: Vector2 = main.player.global_position
	gs.ghost_play = {"1": "%d,%d,1;%d,%d,1;%d,%d,1" % [p0.x, p0.y, p0.x + 50, p0.y, p0.x + 100, p0.y]}
	gs.ghost_name = "Champion"
	await _f(30)
	var rec: PackedStringArray = gs.ghost_rec.get("1", PackedStringArray())
	print("recorded frames=", rec.size(), " ghost node=", main._ghost_node != null, " ghost at ", main._ghost_node.position if main._ghost_node else Vector2.ZERO)
	if rec.size() < 3 or main._ghost_node == null: ok = false
	var j: String = gs.ghost_json()
	print("ghost json length=", j.length())
	if not j.begins_with("{"): ok = false
	gs.abandon_descent()
	await _f(5)
	print("after abandon weekly=", gs.weekly, " weapon=", gs.weapon())
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

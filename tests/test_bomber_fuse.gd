extends SceneTree
# Bulbe : un coup qui ne le tue pas allume la mèche ; il explose ensuite tout seul, même repoussé.
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
	var main = current_scene
	await _f(30)
	var pl = main.player
	pl.sitting = false
	var ok := true
	# bulbe loin du héros (la mèche ne s'allume pas d'elle-même)
	var b := CharacterBody2D.new()
	b.set_script(main.BomberScript)
	b.main = main
	b.position = pl.global_position + Vector2(300, -20)
	main.add_child(b)
	await _f(10)
	b.stun_t = 10.0      # immobile : il ne s'approche pas
	print("mèche avant coup : ", b.fuse)
	if b.fuse >= 0.0: ok = false
	b.take_hit(1, Vector2.RIGHT)
	print("après un coup : hp ", b.hp, " mèche ", b.fuse)
	if b.dead or b.fuse < 0.0: ok = false
	var f0: float = b.fuse
	b.take_hit(0, Vector2.RIGHT)   # un 2e coup ne relance pas la mèche
	if b.fuse > f0: ok = false
	await _f(150)
	print("explosé : ", not is_instance_valid(b) or b.dead)
	if is_instance_valid(b) and not b.dead: ok = false
	# tué d'un coup : pas d'explosion (éclate sans danger)
	var b2 := CharacterBody2D.new()
	b2.set_script(main.BomberScript)
	b2.main = main
	b2.position = pl.global_position + Vector2(-300, -20)
	main.add_child(b2)
	await _f(5)
	var hp_p: int = pl.hp
	b2.take_hit(5, Vector2.LEFT)
	print("tué d'un coup : mort=", b2.dead, " mèche ", b2.fuse)
	if b2.fuse >= 0.0: ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

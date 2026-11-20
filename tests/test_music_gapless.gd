extends SceneTree
# Playlist : le morceau suivant démarre en fondu avant la fin du précédent (pas de blanc).

func _init() -> void:
	await process_frame
	var A = root.get_node("Audio")
	var paths := ["res://music/jungle_canopee_noyee.ogg", "res://music/sanctuaire.ogg"]
	A.play_playlist(paths, false)
	await process_frame
	var first: String = A.current_path
	var p: AudioStreamPlayer = A.players[A.active]
	var len: float = p.stream.get_length()
	p.seek(len - 1.0)   # moins d'un fondu avant la fin
	for i in 5:
		await process_frame
	var ok := true
	if A.current_path == first:
		push_error("le morceau suivant n'a pas démarré avant la fin"); ok = false
	if p.stream.get_length() - p.get_playback_position() > 1.2 and A.players[1 - A.active] == p and not p.playing:
		push_error("l'ancien morceau a été coupé net"); ok = false
	# un seul enchaînement, pas une cascade
	var second: String = A.current_path
	for i in 10:
		await process_frame
	if A.current_path != second:
		push_error("enchaînements en cascade"); ok = false
	# morceau seul : il boucle sans passer par le fondu
	A.play_playlist(["res://music/sanctuaire.ogg"])
	await process_frame
	if not A.players[A.active].stream.loop:
		push_error("morceau seul non bouclé"); ok = false
	print("OK" if ok else "FAIL")
	quit(0 if ok else 1)

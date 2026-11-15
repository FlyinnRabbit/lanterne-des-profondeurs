extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var c = root.get_node("Controls")
	var st = root.get_node("Settings")
	var old: int = st.kb_layout
	for lay in [1, 2, 3]:
		st.kb_layout = lay
		var names := []
		for a in ["up", "move_left", "move_right", "down", "attack", "map"]:
			names.append(c.label_all(a))
		print(c.LAYOUT_LABELS[lay], " : ", names)
	st.kb_layout = old
	quit()

extends SceneTree
# Écrans de chargement dans chaque langue. Usage : -- <indice de langue> <code>
var LoadingScript  # chargé au lancement (les autoloads doivent exister)
func _initialize() -> void:
	_run()
func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout
func _snap(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/lang_%s.png" % name)
func _run() -> void:
	await process_frame
	LoadingScript = load("res://scripts/loading.gd")
	var a := OS.get_cmdline_user_args()
	var st = root.get_node("Settings")
	st.language = int(a[0])
	root.get_node("Lang").apply() if root.get_node("Lang").has_method("apply") else null
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _wait(0.8)
	LoadingScript.launched = false
	LoadingScript.launch(self)
	await _wait(2.3)
	await _snap(a[1] + "_launch")
	await _wait(1.0)
	LoadingScript.shop(self, "shop", tr("Marchand"))
	await _wait(0.3)
	await _snap(a[1] + "_shop")
	await _wait(1.0)
	LoadingScript.lift(self, 3, false, func(): pass)
	await _wait(1.0)
	await _snap(a[1] + "_lift")
	LoadingScript.lift(self, 3, true, func(): pass)
	await _wait(1.0)
	await _snap(a[1] + "_up")
	quit()

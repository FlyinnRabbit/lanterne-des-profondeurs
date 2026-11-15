extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GameState")
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", 2)
	cfg.set_value("game", "tutorial_done", true)
	cfg.set_value("game", "prog", {"geo": 777})
	gs.delete_slot(1)
	cfg.save("user://save.cfg")
	gs._migrate_old_save()
	print("ancien fichier : ", FileAccess.file_exists("user://save.cfg"), " -> emplacement 1 : ", gs.save_summary(1))
	quit()

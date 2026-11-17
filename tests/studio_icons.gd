extends SceneTree
# Rend les 20 médaillons d'emblèmes et les 5 icônes d'armes, en grand, sur fond transparent.
const CI = preload("res://scripts/charm_icon.gd")
const Charms = preload("res://scripts/charms.gd")
const Weapons = preload("res://scripts/weapons.gd")
var out := "/tmp/icons"
var what := ""
var id_c := 0
var id_w := ""
class Canvas extends Node2D:
	var fn: Callable
	func _draw() -> void:
		fn.call(self)
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	_run()
func _run() -> void:
	root.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var cv := Canvas.new()
	root.add_child(cv)
	for i in Charms.CHARMS.size():
		var col: Color = Charms.CHARMS[i]["color"]
		cv.fn = func(ci): CI.draw(ci, Vector2(128, 128), 110.0, i, col, false, 0.6)
		cv.queue_redraw()
		await _shot("charm_%02d" % i)
	for w in Weapons.ORDER:
		cv.fn = func(ci): CI.draw_weapon(ci, Vector2(128, 128), 110.0, w, 0.6)
		cv.queue_redraw()
		await _shot("weapon_%s" % w)
	quit()
func _shot(name: String) -> void:
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image().get_region(Rect2i(0, 0, 256, 256))
	img.save_png("%s/%s.png" % [out, name])

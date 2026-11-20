extends Node2D
# Voile de roche sur une chambre secrète : la chambre reste invisible depuis le couloir
# tant que la dalle fissurée tient et que le héros n'y est pas entré. Il s'efface ensuite.
var main
var cells: Array = []        # cases (Vector2i) de la chambre
var walls: Array = []        # dalles fissurées (plateformes « breakable ») qui la ferment
var rect := Rect2()
var alpha := 1.0
var opened := false
var art

func set_art(a) -> void:
	art = a
	queue_redraw()

func _ready() -> void:
	z_index = 30
	var T: int = main.TILE
	for c in cells:
		var r := Rect2(Vector2(c * T), Vector2(T, T))
		rect = r if rect.size == Vector2.ZERO else rect.merge(r)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/rock.gdshader")
	var STYLE: Dictionary = preload("res://scripts/level_art.gd").STYLE
	m.set_shader_parameter("style", STYLE.get(String(main.pal.get("id", "profondeurs")), 0))
	m.set_shader_parameter("accent", main.pal["moss"])
	material = m
	_lights(false)

# les lueurs du trésor caché trahiraient la chambre : éteintes tant qu'elle est voilée
func _lights(on: bool) -> void:
	for n in main.get_children():
		if n is Node2D and n != self and rect.grow(8).has_point(n.position):
			for l in n.get_children():
				if l is PointLight2D:
					l.visible = on

func _process(delta: float) -> void:
	if not opened:
		var p: Vector2 = main.player.global_position
		if rect.grow(4).has_point(p):
			opened = true
		else:
			for w in walls:
				if not is_instance_valid(w) or w.state == "gone":
					opened = true
	if opened and alpha == 1.0 and art != null:
		# la chambre redevient de l'air : ses faces reprennent leurs bords et leur végétation
		for c in cells:
			main.veiled.erase(c)
		art.redraw_all()
	if opened and alpha == 1.0:
		_lights(true)
	if opened:
		alpha = move_toward(alpha, 0.0, delta * 2.5)
		modulate.a = alpha
		if alpha <= 0.0:
			queue_free()

func _draw() -> void:
	var T: int = main.TILE
	var rock: Color = main.pal["rock"]
	var deep := rock.darkened(0.62)
	for c in cells:
		var p := Vector2(c * T)
		# rangée du bas : déborde un peu sur le sol pour cacher le pied des objets posés dessus
		var lo := 8.0 if not cells.has(c + Vector2i(0, 1)) else 0.0
		var q := PackedVector2Array([p, p + Vector2(T, 0), p + Vector2(T, T + lo), p + Vector2(0, T + lo)])
		if art == null:
			draw_colored_polygon(q, deep)
			continue
		# mêmes couleurs de coin que la roche (dégradé continu, la jonction ne se voit pas)
		draw_polygon(q, PackedColorArray([art._corner(c.x, c.y, rock, deep), art._corner(c.x + 1, c.y, rock, deep),
			art._corner(c.x + 1, c.y + 1, rock, deep), art._corner(c.x, c.y + 1, rock, deep)]))

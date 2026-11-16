extends CanvasLayer
# Écrans de chargement animés, tout dessinés en code :
#   « launch » : au lancement du jeu — une lanterne s'allume dans le noir, le titre apparaît ;
#   « shop »   : en entrant chez un habitant du Sanctuaire — deux battants de bois cerclés de laiton
#                se referment sur l'enseigne de la boutique puis s'ouvrent sur le comptoir ;
#   « lift »   : en prenant l'ascenseur — la cage descend (ou remonte) le puits, chaînes qui
#                cliquettent, plaque gravée du palier ; elle s'arrête avec un choc une fois le niveau prêt.
#
# Le calque est attaché à la racine de l'arbre (et non à la scène) : il survit au rechargement de
# la scène pendant que le niveau suivant se construit. Ce n'est PAS un autoload (un patch de mise à
# jour ne peut pas en ajouter) : on l'appelle par LoadingScript.launch(), .shop(), .lift().
# Toute touche accélère l'animation. LANTERNE_NO_LOADING=1 la désactive (captures et tests).

const DU = preload("res://scripts/draw_util.gd")

const WOOD := Color(0.13, 0.095, 0.07)
const BRASS := Color(0.85, 0.7, 0.35)
const ROCK := Color(0.16, 0.2, 0.32)
const GLOW := Color(1.0, 0.82, 0.48)
const INK := Color(0.02, 0.025, 0.05)

static var launched := false
static var _chain_wav: AudioStreamWAV
static var _clang_wav: AudioStreamWAV

var kind := "launch"
var t := 0.0
var length := 2.0       # durée minimale
var fade := 0.0         # 0 -> 1 pendant la sortie
var leaving := false
var title := ""
var shop_kind := ""
var palier := 1
var going_up := false
var on_middle := Callable()   # lift : appelé quand la cage a pris de la vitesse (lance le chargement)
var middle_done := false
var scene_at_start: Node
var stop_t := -1.0       # lift : instant de l'arrêt (choc)
var depth := 0.0         # lift : défilement du puits
var speed := 0.0
var skip := false
var tip := ""
var view: Control
var chain_player: AudioStreamPlayer

class View extends Control:
	var o
	func _draw() -> void:
		o.draw_screen(self)

static func enabled() -> bool:
	return OS.get_environment("LANTERNE_NO_LOADING") != "1" and DisplayServer.get_name() != "headless"

static func _make(tree: SceneTree, k: String) -> CanvasLayer:
	for c in tree.root.get_children():
		if c.get_script() == load("res://scripts/loading.gd"):
			c.queue_free()
	var l := CanvasLayer.new()
	l.set_script(load("res://scripts/loading.gd"))
	l.kind = k
	tree.root.add_child(l)
	return l

# Au lancement : lanterne qui s'allume et titre. On ne la montre qu'une fois.
static func launch(tree: SceneTree) -> void:
	if launched:
		return
	launched = true
	if not enabled():
		return
	var l = _make(tree, "launch")
	l.length = 2.4

# En entrant dans une boutique / chez un habitant du Sanctuaire.
static func shop(tree: SceneTree, shop_id: String, name: String) -> void:
	if not enabled():
		return
	var l = _make(tree, "shop")
	l.shop_kind = shop_id
	l.title = name
	l.length = 0.78

# L'ascenseur. middle : lance le chargement du niveau (appelé une fois la cage en mouvement).
static func lift(tree: SceneTree, to_palier: int, up: bool, middle: Callable) -> void:
	if not enabled():
		middle.call()
		return
	var l = _make(tree, "lift")
	l.palier = to_palier
	l.going_up = up
	l.on_middle = middle
	l.length = 2.6

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	scene_at_start = get_tree().current_scene
	view = View.new()
	view.o = self
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(view)
	var tips := [
		"Astuce : parer au tout dernier moment rend le coup suivant critique.",
		"Astuce : s'asseoir sur un banc soigne et fait revenir les ennemis.",
		"Astuce : bas + Ruée en l'air déclenche un piqué qui rebondit sur les ennemis.",
		"Astuce : accroupi, les attaques hautes passent au-dessus de toi.",
		"Astuce : ton ombre garde les éclats perdus là où tu es tombé.",
		"Astuce : frapper pendant la Ruée donne un estoc qui traverse tout.",
		"Astuce : la tailleuse du Sanctuaire change l'apparence du héros.",
	]
	tip = tr(tips[randi() % tips.size()])
	if kind == "launch":
		var wp := AudioStreamPlayer.new()
		wp.bus = "SFX"
		wp.stream = embers_sound()
		wp.volume_db = -5.0
		add_child(wp)
		wp.play()
	if kind == "lift":
		chain_player = AudioStreamPlayer.new()
		chain_player.bus = "SFX"
		# vraies chaînes (sfx/lift_chains.ogg) ; repli sur le son synthétisé si le fichier manque
		var start := 0.0
		if ResourceLoader.exists("res://sfx/lift_chains.ogg"):
			var ogg := load("res://sfx/lift_chains.ogg") as AudioStreamOggVorbis
			ogg.loop = true
			chain_player.stream = ogg
			chain_player.volume_db = -4.0
			start = randf() * 7.0
		else:
			chain_player.stream = chain_variant(CHAIN_STYLE)
			chain_player.volume_db = -6.0
		add_child(chain_player)
		chain_player.play(start)
		Audio.sfx("door", 0.0, -2.0)

func _input(event: InputEvent) -> void:
	# l'écran avale les touches (pas d'achat ni de saut à l'aveugle) ; une touche l'accélère
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed():
		if t > 0.25:
			skip = true
	if not leaving or fade < 0.5:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	var sp := 2.5 if skip else 1.0
	t += delta * sp
	match kind:
		"lift":
			_tick_lift(delta * sp)
		_:
			if t >= length:
				leaving = true
	if leaving:
		fade = minf(1.0, fade + delta * (5.0 if kind == "shop" else 3.0))
		if fade >= 1.0:
			queue_free()
	view.queue_redraw()

func _tick_lift(delta: float) -> void:
	# accélération, croisière, puis arrêt avec choc quand le niveau est prêt
	if stop_t < 0.0:
		speed = minf(speed + delta * 900.0, 520.0)
		if t > 0.55 and not middle_done:
			middle_done = true
			if on_middle.is_valid():
				on_middle.call()
		var ready: bool = middle_done and get_tree().current_scene != null and get_tree().current_scene != scene_at_start \
			and get_tree().current_scene.is_node_ready()
		if ready and t >= length:
			stop_t = t
	else:
		speed = maxf(0.0, speed - delta * 2200.0)
		if speed <= 0.0 and chain_player and chain_player.playing:
			var cp := chain_player
			chain_player = null
			var tw := create_tween()
			tw.tween_property(cp, "volume_db", -40.0, 0.2)
			tw.tween_callback(cp.stop)
			var c := AudioStreamPlayer.new()
			c.bus = "SFX"
			c.stream = clang_sound()
			c.volume_db = -3.0
			add_child(c)
			c.play()
		if t - stop_t > 0.55:
			leaving = true
	depth += speed * delta

# ------------------------------------------------------------------ dessin
func draw_screen(v: Control) -> void:
	var a := 1.0 - fade
	v.modulate = Color(1, 1, 1, a)
	match kind:
		"launch":
			_draw_launch(v)
		"shop":
			_draw_shop(v)
		"lift":
			_draw_lift(v)

func _text(v: Control, pos: Vector2, s: String, size: int, col: Color, width := -1.0) -> void:
	var f := ThemeDB.fallback_font
	v.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER if width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, width, size, 5, Color(0, 0, 0, 0.75))
	v.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER if width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, width, size, col)

# Barre de progression : une rangée de braises qui s'allument une à une.
func _embers(v: Control, c: Vector2, k: float) -> void:
	var n := 12
	for i in n:
		var p := c + Vector2((i - (n - 1) / 2.0) * 22.0, 0)
		var on := clampf(k * n - i, 0.0, 1.0)
		v.draw_circle(p, 5.0, Color(0.08, 0.06, 0.05))
		v.draw_arc(p, 5.0, 0.0, TAU, 12, Color(BRASS, 0.5), 1.2)
		if on > 0.0:
			DU.glow(v, p, 12.0 * on, GLOW, 0.35 * on)
			v.draw_circle(p, 3.6 * on, GLOW.lerp(Color(1, 1, 0.9), 0.4))

# ---------------- lancement : une lanterne s'allume dans le noir
func _draw_launch(v: Control) -> void:
	var sz := v.size
	v.draw_rect(Rect2(Vector2.ZERO, sz), INK)
	var c := sz / 2.0 + Vector2(0, -40)
	var k := clampf(t / length, 0.0, 1.0)
	var lit := clampf((t - 0.35) / 0.6, 0.0, 1.0)          # la flamme prend
	var flick := 0.92 + 0.08 * sin(t * 17.0) * sin(t * 7.3)
	# halo et rayons
	DU.glow(v, c, 260.0 * lit, GLOW, 0.22 * lit * flick)
	for i in 10:
		var ang := -PI / 2.0 + (i - 4.5) * 0.22 + sin(t * 0.7 + i) * 0.03
		var d := Vector2.from_angle(ang + PI)
		v.draw_colored_polygon(PackedVector2Array([c, c + d.rotated(-0.04) * 420.0, c + d.rotated(0.04) * 420.0]), Color(GLOW, 0.035 * lit))
	# chaîne et anneau
	v.draw_line(Vector2(c.x, 0), c + Vector2(0, -70), Color(0.3, 0.26, 0.22), 3.0)
	for i in 8:
		var y := c.y - 74.0 - i * 16.0
		v.draw_arc(Vector2(c.x, y), 5.0, 0.0, TAU, 10, Color(0.42, 0.36, 0.28), 2.0)
	# corps de la lanterne
	var body := Rect2(c + Vector2(-30, -44), Vector2(60, 84))
	DU.flat(v, PackedVector2Array([c + Vector2(-38, -44), c + Vector2(0, -72), c + Vector2(38, -44)]), Color(0.22, 0.17, 0.11))
	v.draw_arc(c + Vector2(0, -76), 9.0, PI, TAU, 10, BRASS.darkened(0.3), 3.0)
	v.draw_rect(body, Color(0.06, 0.05, 0.05))
	var glass := body.grow(-7)
	v.draw_rect(glass, Color(0.12, 0.1, 0.08).lerp(Color(1.0, 0.86, 0.55), 0.85 * lit * flick))
	# flamme
	if lit > 0.0:
		var fc := c + Vector2(0, 14)
		var h := 30.0 * lit * flick
		v.draw_colored_polygon(PackedVector2Array([fc + Vector2(-9, 0), fc + Vector2(-3, -h * 0.6), fc + Vector2(sin(t * 9.0) * 2.0, -h), fc + Vector2(3, -h * 0.6), fc + Vector2(9, 0), fc + Vector2(0, 6)]), Color(1.0, 0.65, 0.2))
		v.draw_colored_polygon(PackedVector2Array([fc + Vector2(-4, 0), fc + Vector2(0, -h * 0.65), fc + Vector2(4, 0), fc + Vector2(0, 4)]), Color(1.0, 0.95, 0.75))
	elif fmod(t, 0.18) < 0.09:     # étincelle avant que la flamme prenne
		v.draw_circle(c + Vector2(4, 12), 2.0, Color(1.0, 0.8, 0.4))
	# montants de laiton
	for x: float in [-30.0, 30.0]:
		v.draw_line(c + Vector2(x, -44), c + Vector2(x, 40), BRASS.darkened(0.15), 4.0)
	v.draw_line(c + Vector2(0, -44), c + Vector2(0, 40), Color(BRASS.darkened(0.25), 0.8), 2.0)
	DU.box(v, Rect2(c + Vector2(-36, 40), Vector2(72, 10)), Color(0.22, 0.17, 0.11))
	# braises qui montent
	for i in 14:
		var s := fposmod(t * (0.25 + fposmod(i * 0.137, 0.2)) + i * 0.31, 1.0)
		var p := c + Vector2(sin(i * 3.1 + t * 1.3) * (30.0 + i * 6.0), -40.0 - s * 260.0)
		v.draw_circle(p, 1.8 * (1.0 - s), Color(1.0, 0.7, 0.3, (1.0 - s) * lit))
	# titre
	var ta := clampf((t - 0.7) / 0.6, 0.0, 1.0)
	_text(v, Vector2(0, c.y + 130), tr("Lanterne des Profondeurs"), 44, Color(1.0, 0.88, 0.6, ta), sz.x)
	_text(v, Vector2(0, c.y + 162), tip, 15, Color(0.62, 0.68, 0.8, ta), sz.x)
	_embers(v, Vector2(sz.x / 2.0, c.y + 200), k)

# ---------------- boutique : battants de bois qui se ferment sur l'enseigne, puis s'ouvrent
func _draw_shop(v: Control) -> void:
	var sz := v.size
	var close_k := clampf(t / 0.12, 0.0, 1.0)                    # apparition rapide
	var open_k := clampf((t - 0.42) / 0.36, 0.0, 1.0)            # ouverture
	open_k = open_k * open_k * (3.0 - 2.0 * open_k)
	var half := sz.x / 2.0
	var shift := half * open_k
	v.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.55 * close_k * (1.0 - open_k)))
	for side: float in [-1.0, 1.0]:
		var x0: float = (0.0 if side < 0.0 else half) + side * shift
		var r := Rect2(x0, 0, half, sz.y)
		var pk := 1.0 - 0.25 * open_k          # perspective : le battant pivote
		var pts := PackedVector2Array()
		if side < 0.0:
			pts = PackedVector2Array([r.position, Vector2(r.end.x, sz.y * (1.0 - pk) / 2.0), Vector2(r.end.x, sz.y - sz.y * (1.0 - pk) / 2.0), Vector2(r.position.x, sz.y)])
		else:
			pts = PackedVector2Array([Vector2(r.position.x, sz.y * (1.0 - pk) / 2.0), Vector2(r.end.x, 0), Vector2(r.end.x, sz.y), Vector2(r.position.x, sz.y - sz.y * (1.0 - pk) / 2.0)])
		var wood := WOOD.lightened(0.06) if side < 0.0 else WOOD.lightened(0.03)
		v.draw_colored_polygon(pts, Color(wood, close_k))
		# planches et ferrures
		for i in range(1, 6):
			var px := r.position.x + i * half / 6.0
			v.draw_line(Vector2(px, 0), Vector2(px, sz.y), Color(0, 0, 0, 0.35 * close_k), 2.0)
		for fy: float in [0.18, 0.5, 0.82]:
			var y: float = sz.y * fy
			v.draw_rect(Rect2(r.position.x, y - 9, half, 18), Color(0.22, 0.2, 0.2, close_k))
			v.draw_line(Vector2(r.position.x, y - 9), Vector2(r.end.x, y - 9), Color(BRASS, 0.4 * close_k), 1.5)
			for i in 7:
				var sx := r.position.x + 22.0 + i * (half - 44.0) / 6.0
				DU.ball(v, Vector2(sx, y), 3.5, Color(BRASS, close_k))
		# poignée en anneau près de la jointure
		var hx: float = (r.end.x - 34.0) if side < 0.0 else (r.position.x + 34.0)
		v.draw_arc(Vector2(hx, sz.y / 2.0 + 30.0), 14.0, 0.0, TAU, 20, Color(BRASS, close_k), 3.5)
	# enseigne au centre (sur la jointure, disparaît à l'ouverture)
	var ea := close_k * (1.0 - clampf(open_k * 3.0, 0.0, 1.0))
	if ea > 0.0:
		var c := sz / 2.0 + Vector2(0, -20)
		var sw := sin(t * 6.0) * 0.06 * (1.0 - clampf(t / 0.4, 0.0, 1.0))
		v.draw_set_transform(c, sw, Vector2(1.4, 1.4))
		v.draw_line(Vector2(-70, -110), Vector2(-60, -64), Color(0.35, 0.3, 0.25, ea), 2.0)
		v.draw_line(Vector2(70, -110), Vector2(60, -64), Color(0.35, 0.3, 0.25, ea), 2.0)
		var plank := Rect2(-150, -64, 300, 128)
		v.draw_rect(plank, Color(0.2, 0.14, 0.09, ea))
		v.draw_rect(plank, Color(BRASS, ea), false, 3.0)
		v.draw_rect(plank.grow(-6), Color(BRASS.darkened(0.4), 0.6 * ea), false, 1.5)
		DU.glow(v, Vector2(0, -16), 48.0, GLOW, 0.2 * ea)
		_emblem(v, Vector2(0, -16), shop_kind, ea)
		_text(v, Vector2(-150, 46), title, 22, Color(1.0, 0.88, 0.6, ea), 300.0)
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Emblème de l'enseigne (dessiné à l'encre dorée)
func _emblem(v: Control, c: Vector2, id: String, a: float) -> void:
	var g := Color(1.0, 0.85, 0.45, a)
	var d := Color(0.5, 0.36, 0.16, a)
	match id:
		"shop":       # bourse d'éclats
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -6), c + Vector2(18, -6), c + Vector2(24, 18), c + Vector2(0, 26), c + Vector2(-24, 18)]), d)
			v.draw_line(c + Vector2(-12, -10), c + Vector2(12, -10), g, 3.0)
			DU.flat(v, DU.diamond(c + Vector2(0, -24), Vector2(7, 11)), Color(0.6, 0.85, 1.0, a))
			DU.flat(v, DU.diamond(c + Vector2(10, 6), Vector2(5, 8)), Color(0.6, 0.85, 1.0, a))
		"smith":      # enclume et marteau
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(-28, -4), c + Vector2(22, -4), c + Vector2(30, -12), c + Vector2(30, 2), c + Vector2(14, 6), c + Vector2(10, 18), c + Vector2(18, 24), c + Vector2(-18, 24), c + Vector2(-10, 18), c + Vector2(-14, 6), c + Vector2(-28, 2)]), g)
			v.draw_line(c + Vector2(-6, -34), c + Vector2(14, -12), d.lightened(0.3), 4.0)
			v.draw_rect(Rect2(c + Vector2(-16, -40), Vector2(16, 10)), g)
		"cartographer":   # carte roulée et plume
			v.draw_rect(Rect2(c + Vector2(-26, -14), Vector2(52, 34)), Color(0.85, 0.75, 0.55, a))
			v.draw_polyline(PackedVector2Array([c + Vector2(-18, 10), c + Vector2(-6, -2), c + Vector2(6, 6), c + Vector2(18, -6)]), d, 2.0)
			v.draw_circle(c + Vector2(18, -6), 3.0, Color(0.8, 0.2, 0.15, a))
			v.draw_line(c + Vector2(14, 22), c + Vector2(34, -26), g, 2.5)
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(34, -26), c + Vector2(22, -12), c + Vector2(28, -8)]), g)
		"elder":      # parchemin et bougie
			v.draw_rect(Rect2(c + Vector2(-24, -18), Vector2(40, 40)), Color(0.85, 0.75, 0.55, a))
			for i in 4:
				v.draw_line(c + Vector2(-18, -10 + i * 8), c + Vector2(10, -10 + i * 8), d, 1.5)
			v.draw_rect(Rect2(c + Vector2(22, -6), Vector2(8, 26)), Color(0.92, 0.9, 0.8, a))
			v.draw_colored_polygon(PackedVector2Array([c + Vector2(22, -6), c + Vector2(26, -18), c + Vector2(30, -6)]), Color(1.0, 0.75, 0.3, a))
		"tailor":     # aiguille et bobine
			v.draw_rect(Rect2(c + Vector2(-20, -14), Vector2(24, 30)), Color(0.85, 0.3, 0.35, a))
			v.draw_line(c + Vector2(-23, -14), c + Vector2(7, -14), g, 3.0)
			v.draw_line(c + Vector2(-23, 16), c + Vector2(7, 16), g, 3.0)
			v.draw_line(c + Vector2(14, 26), c + Vector2(30, -28), Color(0.9, 0.93, 1.0, a), 2.5)
			v.draw_polyline(PackedVector2Array([c + Vector2(28, -22), c + Vector2(20, -4), c + Vector2(8, 4)]), Color(0.85, 0.3, 0.35, a), 1.5)
		"arsenal":    # deux lames croisées
			for sgn: float in [-1.0, 1.0]:
				v.draw_line(c + Vector2(-24 * sgn, 24), c + Vector2(22 * sgn, -26), Color(0.88, 0.9, 0.98, a), 4.0)
				v.draw_line(c + Vector2(-16 * sgn, 10), c + Vector2(-8 * sgn, 20), g, 4.0)
			v.draw_circle(c, 5.0, g)

# ---------------- ascenseur : la cage descend le puits
func _draw_lift(v: Control) -> void:
	var sz := v.size
	var dir := -1.0 if going_up else 1.0
	var shake := Vector2.ZERO
	if stop_t >= 0.0 and t - stop_t < 0.35:
		shake = Vector2(0, sin((t - stop_t) * 60.0) * 6.0 * (1.0 - (t - stop_t) / 0.35))
	elif speed > 50.0:
		shake = Vector2(sin(t * 41.0), sin(t * 37.0)) * 1.2
	v.draw_rect(Rect2(Vector2.ZERO, sz), INK)
	var cx := sz.x / 2.0
	# paroi du fond (derrière la cage) : poutres et traverses de bois qui défilent lentement
	var far_off := fposmod(depth * 0.35 * dir, 170.0)
	for bx: float in [-150.0, -60.0, 60.0, 150.0]:
		v.draw_rect(Rect2(cx + bx - 7.0, 0, 14.0, sz.y), Color(0.09, 0.07, 0.06))
		v.draw_line(Vector2(cx + bx - 7.0, 0), Vector2(cx + bx - 7.0, sz.y), Color(0.16, 0.12, 0.09), 1.5)
	for k in range(-1, int(sz.y / 170.0) + 2):
		var y := k * 170.0 - far_off
		v.draw_rect(Rect2(cx - 230.0, y, 460.0, 10.0), Color(0.08, 0.065, 0.055))
		v.draw_line(Vector2(cx - 230.0, y), Vector2(cx + 230.0, y), Color(0.15, 0.11, 0.08), 1.0)
	# parois latérales : pierres de taille en quinconce, éclairées près du puits par la lanterne
	var row_h := 46.0
	var near_off := fposmod(depth * dir, row_h)
	var row0 := floori(depth * dir / row_h)
	for side: float in [-1.0, 1.0]:
		var edge: float = cx + side * 230.0
		var far_x: float = 0.0 if side < 0.0 else sz.x
		v.draw_rect(Rect2(minf(edge, far_x), 0, absf(far_x - edge), sz.y), ROCK.darkened(0.62))
		for k in range(-1, int(sz.y / row_h) + 2):
			var y := k * row_h - near_off
			var gk := k + row0
			var x := edge + side * (fposmod(gk * 37.0, 2.0) * 34.0 - 34.0)
			var bi := 0
			while (x - far_x) * side < 0.0 and bi < 20:
				var j := fposmod(sin(gk * 12.9898 + bi * 78.233 + side * 3.1) * 43758.5, 1.0)
				var bw := 62.0 + j * 50.0
				var r := Rect2(x if side > 0.0 else x - bw, y + 2.0, bw - 3.0, row_h - 4.0)
				var near_k: float = clampf(1.0 - absf(r.get_center().x - edge) / 260.0, 0.0, 1.0)
				var light: float = near_k * clampf(1.0 - absf(r.get_center().y - sz.y * 0.48) / (sz.y * 0.75), 0.0, 1.0)
				var col := ROCK.darkened(0.5 - j * 0.12).lerp(Color(0.45, 0.38, 0.3), 0.22 * light)
				v.draw_rect(r, col)
				v.draw_line(r.position, Vector2(r.end.x, r.position.y), Color(1, 1, 1, 0.06 + 0.08 * light), 1.5)
				v.draw_rect(r, Color(0, 0, 0, 0.45), false, 1.5)
				if j > 0.93 and bi < 3:       # cristal incrusté
					var cp := r.get_center()
					DU.glow(v, cp, 20.0, Color(0.5, 0.8, 1.0), 0.25)
					DU.flat(v, DU.diamond(cp, Vector2(4, 9)), Color(0.55, 0.85, 1.0))
				elif j < 0.05:                 # racine qui pend
					v.draw_polyline(PackedVector2Array([r.position + Vector2(bw * 0.5, row_h - 4.0), r.position + Vector2(bw * 0.5 + 4.0, row_h + 14.0), r.position + Vector2(bw * 0.5 - 2.0, row_h + 30.0)]), Color(0.2, 0.15, 0.1), 2.0)
				x += side * bw
				bi += 1
		# rebord du puits
		v.draw_rect(Rect2(edge - (8.0 if side > 0.0 else 0.0), 0, 8.0, sz.y), ROCK.darkened(0.3))
		v.draw_line(Vector2(edge, 0), Vector2(edge, sz.y), Color(ROCK.lightened(0.25), 0.6), 2.0)
	# pénombre vers les bords de l'écran
	for side: float in [-1.0, 1.0]:
		var e0: float = 0.0 if side < 0.0 else sz.x
		var e1: float = cx + side * 360.0
		v.draw_polygon(PackedVector2Array([Vector2(e0, 0), Vector2(e1, 0), Vector2(e1, sz.y), Vector2(e0, sz.y)]), PackedColorArray([Color(INK, 0.85), Color(INK, 0.0), Color(INK, 0.0), Color(INK, 0.85)]))
	DU.vgrad(v, Rect2(0, 0, sz.x, 130), Color(INK, 0.9), Color(INK, 0.0))
	DU.vgrad(v, Rect2(0, sz.y - 130, sz.x, 130), Color(INK, 0.0), Color(INK, 0.9))
	# lumière de la lanterne de la cage sur les parois
	var cage_c := Vector2(cx, sz.y * 0.48) + shake
	DU.glow(v, cage_c, 300.0, GLOW, 0.12)
	# chaînes : deux, maillons qui défilent
	for side: float in [-1.0, 1.0]:
		var x: float = cx + side * 70.0 + shake.x
		var off := fposmod(depth * dir, 22.0)
		for k in range(-1, int((cage_c.y - 96.0) / 22.0) + 2):
			var y := k * 22.0 - off
			if y > cage_c.y - 96.0:
				break
			if k % 2 == 0:
				v.draw_arc(Vector2(x, y + 11.0), 6.0, 0.0, TAU, 12, Color(0.45, 0.42, 0.4), 3.0)
			else:
				v.draw_line(Vector2(x, y + 2.0), Vector2(x, y + 20.0), Color(0.55, 0.5, 0.45), 4.0)
				v.draw_line(Vector2(x - 1.0, y + 4.0), Vector2(x - 1.0, y + 18.0), Color(0.8, 0.75, 0.65, 0.5), 1.0)
	# poulie au-dessus de la cage
	var top := cage_c + Vector2(0, -96)
	v.draw_line(top + Vector2(-70, 0), top + Vector2(70, 0), Color(0.3, 0.26, 0.22), 6.0)
	# cage : cadre de fer, barreaux, plancher, toit en pointe
	var cw := 170.0
	var ch := 180.0
	var cr := Rect2(cage_c + Vector2(-cw / 2.0, -96), Vector2(cw, ch))
	v.draw_colored_polygon(PackedVector2Array([cr.position, cr.position + Vector2(cw / 2.0, -30), cr.position + Vector2(cw, 0)]), Color(0.22, 0.17, 0.11))
	v.draw_polyline(PackedVector2Array([cr.position, cr.position + Vector2(cw / 2.0, -30), cr.position + Vector2(cw, 0)]), BRASS.darkened(0.2), 2.0)
	v.draw_rect(cr, Color(0.05, 0.045, 0.05, 0.6))
	# héros dans la cage (silhouette, écharpe, œil)
	var hp := Vector2(cx, cr.end.y - 10.0) + Vector2(shake.x, 0)
	var sway := sin(t * 3.0) * 2.0
	v.draw_set_transform(hp, 0.0, Vector2(2.0, 2.0))
	GameState.cos.draw_hero(v, 0.0, sway, t, false, false)
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# lanterne suspendue dans la cage
	var lp := cr.position + Vector2(cw / 2.0 + 44.0, 30.0 + sin(t * 2.2) * 2.0)
	v.draw_line(cr.position + Vector2(cw / 2.0 + 44.0, 0), lp, Color(0.3, 0.26, 0.22), 1.5)
	DU.glow(v, lp + Vector2(0, 10), 34.0, GLOW, 0.35)
	DU.box(v, Rect2(lp + Vector2(-6, 0), Vector2(12, 18)), Color(0.32, 0.26, 0.18))
	v.draw_rect(Rect2(lp + Vector2(-4, 2), Vector2(8, 13)), Color(1.0, 0.88, 0.55))
	for i in 8:
		var bx := cr.position.x + 8.0 + i * (cw - 16.0) / 7.0
		v.draw_line(Vector2(bx, cr.position.y), Vector2(bx, cr.end.y), Color(0.3, 0.3, 0.34), 3.0)
		v.draw_line(Vector2(bx - 1.0, cr.position.y), Vector2(bx - 1.0, cr.end.y), Color(0.6, 0.6, 0.66, 0.3), 1.0)
	v.draw_rect(cr, BRASS.darkened(0.25), false, 4.0)
	v.draw_line(Vector2(cr.position.x, cr.position.y + ch * 0.5), Vector2(cr.end.x, cr.position.y + ch * 0.5), Color(0.3, 0.3, 0.34), 3.0)
	DU.box(v, Rect2(cr.position.x - 8.0, cr.end.y, cw + 16.0, 14.0), Color(0.22, 0.17, 0.11))
	# plaque de laiton suspendue sous la cage : numéro du palier gravé en chiffres romains
	if not going_up:
		var pc := Vector2(cx + shake.x, cr.end.y + 34.0 + sin(t * 2.6) * 1.5)
		var num := _roman(palier)
		var pw := maxf(46.0, 18.0 + num.length() * 15.0)
		v.draw_line(Vector2(pc.x - pw * 0.3, cr.end.y + 14.0), pc + Vector2(-pw * 0.3, -14.0), Color(0.35, 0.3, 0.25), 1.5)
		v.draw_line(Vector2(pc.x + pw * 0.3, cr.end.y + 14.0), pc + Vector2(pw * 0.3, -14.0), Color(0.35, 0.3, 0.25), 1.5)
		var pr := Rect2(pc - Vector2(pw / 2.0, 14.0), Vector2(pw, 28.0))
		DU.glow(v, pc, 40.0, GLOW, 0.12)
		DU.box(v, pr, BRASS)
		v.draw_rect(pr.grow(-3.0), BRASS.darkened(0.5), false, 1.5)
		var f := ThemeDB.fallback_font
		v.draw_string(f, Vector2(pr.position.x, pc.y + 8.0), num, HORIZONTAL_ALIGNMENT_CENTER, pw, 22, Color(1.0, 0.95, 0.75, 0.5))
		v.draw_string(f, Vector2(pr.position.x, pc.y + 7.0), num, HORIZONTAL_ALIGNMENT_CENTER, pw, 22, Color(0.16, 0.09, 0.03))
	for i in 6:
		DU.ball(v, Vector2(cr.position.x + 6.0 + i * (cw - 12.0) / 5.0, cr.end.y + 7.0), 2.5, BRASS)
	# étincelles des chaînes sur la poulie
	if speed > 200.0:
		for i in 5:
			var s := fposmod(t * 3.0 + i * 0.2, 1.0)
			for side: float in [-1.0, 1.0]:
				var p: Vector2 = top + Vector2(side * 70.0, 0) + Vector2(side * s * 30.0, s * s * 40.0)
				v.draw_circle(p, 1.6 * (1.0 - s), Color(1.0, 0.75, 0.35, 1.0 - s))
	# textes
	var head := tr("Remontée vers le Sanctuaire") if going_up else (tr("Descente vers le palier %d") % palier)
	_text(v, Vector2(0, 64), head, 30, Color(1.0, 0.88, 0.6), sz.x)
	_text(v, Vector2(0, sz.y - 40), tip, 15, Color(0.62, 0.68, 0.8), sz.x)

static func _roman(n: int) -> String:
	var vals := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var out := ""
	for vv in vals:
		while n >= int(vv[0]):
			out += String(vv[1])
			n -= int(vv[0])
	return out

# ------------------------------------------------------------------ sons synthétisés
# Cliquetis de chaînes (boucle) : tintements métalliques irréguliers + grondement du treuil.
static func chain_sound() -> AudioStreamWAV:
	if _chain_wav:
		return _chain_wav
	var sr := 22050
	var dur := 2.0
	var n := int(sr * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# grondement : bruit filtré en basse fréquence ; on en génère un peu plus et on fond la fin
	# dans le début pour que la boucle ne claque pas au raccord
	var m := int(sr * 0.12)
	var rum := PackedFloat32Array()
	rum.resize(n + m)
	var lp := 0.0
	var lp2 := 0.0
	for i in n + m:
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.02
		lp2 += (lp - lp2) * 0.05
		var cyc := 0.6 + 0.4 * sin(TAU * i / float(n) * 8.0)    # le treuil tourne
		rum[i] = lp2 * 3.5 * cyc
	for i in n:
		buf[i] = rum[i]
	for i in m:
		var k := i / float(m)
		buf[i] = rum[i] * k + rum[n + i] * (1.0 - k)
	# tintements : maillons qui s'entrechoquent
	var tpos := 0.0
	while tpos < dur - 0.05:
		var big: bool = rng.randf() < 0.18
		var base := rng.randf_range(1900.0, 2600.0) * (0.6 if big else 1.0)
		var parts := [[1.0, 1.0], [1.47, 0.7], [2.09, 0.5], [2.76, 0.35], [3.51, 0.2]]
		var amp := rng.randf_range(0.18, 0.32) * (1.6 if big else 1.0)
		var dec := 38.0 if big else rng.randf_range(55.0, 80.0)
		var i0 := int(tpos * sr)
		var ln := int(sr * (0.18 if big else 0.1))
		for j in ln:
			var tt := j / float(sr)
			var s := 0.0
			for p: Array in parts:
				s += sin(TAU * base * float(p[0]) * tt) * float(p[1])
			s += rng.randf_range(-1.0, 1.0) * 0.4 * exp(-tt * 300.0)    # attaque
			var idx := (i0 + j) % n                                     # boucle sans coupure
			buf[idx] += s * amp * exp(-tt * dec)
		tpos += rng.randf_range(0.045, 0.13)
	_chain_wav = _to_wav(buf, sr, true)
	return _chain_wav

# Variantes de cliquetis (toutes synthétisées ici, aucune source extérieure) :
#   "treuil"   : treuil lourd — cliquet régulier, gros maillons qui cognent, moteur qui ronronne ;
#   "cage"     : la cage brinquebale — fer qui tremble, grincements de la nacelle qui se balance ;
#   "lointain" : puits profond — chocs espacés aux longues résonances et leur écho dans le puits.
static var _variants := {}
const CHAIN_STYLE := "mixte"

static func chain_variant(style: String) -> AudioStreamWAV:
	if style == "classique":
		return chain_sound()
	if _variants.has(style):
		return _variants[style]
	var sr := 22050
	var dur := 2.4
	var n := int(sr * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1931 + style.length()
	match style:
		"treuil":
			# ronronnement du moteur : deux sinus graves battants + bruit grave (fondu en boucle)
			_rumble(buf, sr, rng, 0.015, 2.6)
			for i in n:
				var tt := i / float(sr)
				buf[i] += (sin(TAU * 55.0 * tt) * 0.25 + sin(TAU * 110.4 * tt) * 0.12) * (0.8 + 0.2 * sin(TAU * tt / dur * 3.0))
			# cliquet : petits « tic » réguliers (8 par seconde)
			var k := 0
			var tick := 0.0
			while tick < dur:
				_hit(buf, sr, tick, rng.randf_range(3300.0, 3700.0), [[1.0, 1.0], [1.83, 0.5], [2.71, 0.3]], 0.22, 160.0, 0.05)
				tick += 0.125
				k += 1
			# gros maillons qui cognent sur la poulie, un sur trois plus fort
			var c := 0.06
			var j := 0
			while c < dur:
				var heavy := j % 3 == 0
				_hit(buf, sr, c, rng.randf_range(620.0, 760.0) * (0.8 if heavy else 1.0), [[1.0, 1.0], [1.51, 0.7], [2.32, 0.5], [3.17, 0.3], [4.4, 0.18]], 0.6 if heavy else 0.38, 18.0 if heavy else 26.0, 0.35)
				c += 0.4
				j += 1
		"cage":
			_rumble(buf, sr, rng, 0.02, 1.6)
			# fer qui tremble : nuée de petits chocs irréguliers
			var c2 := 0.0
			while c2 < dur:
				_hit(buf, sr, c2, rng.randf_range(1400.0, 3800.0), [[1.0, 1.0], [1.62, 0.6], [2.43, 0.35]], rng.randf_range(0.06, 0.2), rng.randf_range(70.0, 120.0), 0.08)
				c2 += rng.randf_range(0.02, 0.07)
			# grincements de la nacelle : frottement (train d'impulsions résonantes à hauteur variable)
			for g: float in [0.2, 1.4]:
				var gt: float = g
				var ge: float = g + 0.75
				while gt < ge:
					var u: float = (gt - g) / 0.75
					var a := sin(PI * u) * 0.12
					_hit(buf, sr, gt, 820.0 + 160.0 * sin(u * 3.0), [[1.0, 1.0], [1.7, 0.5]], a, 140.0, 0.0)
					gt += 1.0 / (95.0 + 45.0 * sin(u * PI * 1.5) + rng.randf_range(-6.0, 6.0))
		"mixte":
			# treuil + chaîne, plus réaliste : chaque choc excite des résonateurs métalliques (et non des
			# sinus purs) ; les maillons cognent par paires ; cliquet du treuil ; gros maillon sur la poulie
			_rumble(buf, sr, rng, 0.012, 0.8)
			# chaîne qui défile : maillons en paires rapprochées, hauteurs variées
			var c4 := 0.0
			while c4 < dur:
				var f1 := rng.randf_range(2300.0, 3400.0)
				_ring(buf, sr, c4, [f1, f1 * 1.37, f1 * 1.93, f1 * 2.61], rng.randf_range(0.16, 0.3), 0.9965, rng)
				_ring(buf, sr, c4 + rng.randf_range(0.012, 0.025), [f1 * 1.06, f1 * 1.52, f1 * 2.2], rng.randf_range(0.05, 0.1), 0.996, rng)
				c4 += rng.randf_range(0.07, 0.11)
			# cliquet du treuil : « tic » sec et régulier
			var tk := 0.03
			while tk < dur:
				_ring(buf, sr, tk, [4100.0, 5900.0, 7600.0], 0.1, 0.993, rng)
				tk += 0.15
			# gros maillon sur la poulie, un sur deux plus lourd
			var hv := 0.12
			var hj := 0
			while hv < dur:
				var heavy := hj % 2 == 0
				var f2 := rng.randf_range(540.0, 640.0) * (0.85 if heavy else 1.0)
				_ring(buf, sr, hv, [f2, f2 * 1.58, f2 * 2.31, f2 * 3.07, f2 * 4.2], 0.42 if heavy else 0.28, 0.99945, rng)
				hv += 0.6
				hj += 1
		"lointain":
			_rumble(buf, sr, rng, 0.01, 3.2)
			# chocs espacés à longue résonance, et leur écho dans le puits
			var c3 := 0.1
			while c3 < dur:
				var f0 := rng.randf_range(380.0, 520.0)
				var parts := [[1.0, 1.0], [1.47, 0.6], [2.13, 0.45], [2.89, 0.3], [3.97, 0.15]]
				_hit(buf, sr, c3, f0, parts, 0.5, 6.0, 0.25)
				_hit(buf, sr, c3 + 0.21, f0, parts, 0.2, 7.0, 0.05)
				_hit(buf, sr, c3 + 0.42, f0, parts, 0.08, 8.0, 0.0)
				# maillon léger entre deux chocs
				_hit(buf, sr, c3 + 0.3, rng.randf_range(2200.0, 2700.0), [[1.0, 1.0], [1.5, 0.5]], 0.12, 60.0, 0.05)
				c3 += 0.6
	var w := _to_wav(buf, sr, true)
	_variants[style] = w
	return w

# Grondement grave qui boucle sans raccord.
static func _rumble(buf: PackedFloat32Array, sr: int, rng: RandomNumberGenerator, cut: float, gain: float) -> void:
	var n := buf.size()
	var m := int(sr * 0.12)
	var rum := PackedFloat32Array()
	rum.resize(n + m)
	var lp := 0.0
	var lp2 := 0.0
	for i in n + m:
		lp += (rng.randf_range(-1.0, 1.0) - lp) * cut
		lp2 += (lp - lp2) * 0.05
		rum[i] = lp2 * gain
	for i in n:
		var k := clampf(i / float(m), 0.0, 1.0)
		buf[i] += rum[i] * k + (rum[n + i] * (1.0 - k) if i < m else 0.0)

# Un choc métallique (partiels inharmoniques), ajouté en boucle (la fin revient au début).
static func _hit(buf: PackedFloat32Array, sr: int, at: float, base: float, parts: Array, amp: float, dec: float, noise: float) -> void:
	var n := buf.size()
	var ln := int(sr * minf(4.0 / dec + 0.02, 1.5))
	var i0 := int(at * sr)
	var seed_n := int(base) * 31
	for j in ln:
		var tt := j / float(sr)
		var s := 0.0
		for p: Array in parts:
			s += sin(TAU * base * float(p[0]) * tt) * float(p[1])
		if noise > 0.0:
			s += (fposmod(sin((j + seed_n) * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0) * noise * exp(-tt * 300.0)
		buf[(i0 + j) % n] += s * amp * exp(-tt * dec)

# Choc métallique réaliste : un bref souffle de bruit excite des résonateurs (filtres à deux pôles)
# accordés sur des fréquences inharmoniques ; r (proche de 1) règle la durée de la résonance.
static func _ring(buf: PackedFloat32Array, sr: int, at: float, freqs: Array, amp: float, r: float, rng: RandomNumberGenerator) -> void:
	var n := buf.size()
	var ln := int(minf(log(0.001) / log(r), sr * 1.2))
	var i0 := int(at * sr)
	var burst := int(sr * 0.002)
	var out := PackedFloat32Array()
	out.resize(ln)
	for f in freqs:
		var w := TAU * float(f) / sr
		var c := 2.0 * r * cos(w)
		var r2 := r * r
		var y1 := 0.0
		var y2 := 0.0
		var g := (1.0 - r2) * 6.0 / sqrt(float(freqs.size()))
		for j in ln:
			var x := rng.randf_range(-1.0, 1.0) * (1.0 - j / float(burst)) if j < burst else 0.0
			var y := g * x + c * y1 - r2 * y2
			y2 = y1
			y1 = y
			out[j] += y
	for j in ln:
		buf[(i0 + j) % n] += out[j] * amp * 8.0

# Choc de l'arrivée : cage qui se pose (coup sourd + résonance de fer).
static func clang_sound() -> AudioStreamWAV:
	if _clang_wav:
		return _clang_wav
	var sr := 22050
	var n := int(sr * 1.1)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var lp := 0.0
	for i in n:
		var tt := i / float(sr)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.08
		var thud := sin(TAU * 62.0 * tt) * exp(-tt * 14.0) * 0.9 + lp * 2.0 * exp(-tt * 25.0)
		var ring := 0.0
		for p: Array in [[310.0, 0.5, 4.0], [487.0, 0.4, 5.0], [733.0, 0.3, 7.0], [1160.0, 0.2, 9.0], [1690.0, 0.12, 12.0]]:
			ring += sin(TAU * float(p[0]) * tt) * float(p[1]) * exp(-tt * float(p[2]))
		buf[i] = thud + ring * 0.6
	_clang_wav = _to_wav(buf, sr, false)
	return _clang_wav

# Braises qui crépitent pendant l'écran de lancement (petits tics, quelques éclats,
# grondement doux du feu). Synthétisé, aucun fichier.
static var _embers_wav: AudioStreamWAV
static func embers_sound() -> AudioStreamWAV:
	if _embers_wav:
		return _embers_wav
	var sr := 22050
	var dur := 3.2
	var n := int(sr * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var lpr := 0.0
	for i in n:
		var tt := i / float(sr)
		var w := rng.randf_range(-1.0, 1.0)
		# grondement doux du feu sous les braises
		lpr += (w - lpr) * 0.035
		var fl := 0.75 + 0.25 * sin(tt * 5.1) * sin(tt * 2.3 + 1.0)
		buf[i] = lpr * clampf(tt / 0.35, 0.0, 1.0) * 0.28 * fl
	# crépitements de braises : petits tics serrés et quelques éclats plus gros
	var at_s := 0.05
	while at_s < dur - 0.25:
		at_s += rng.randf_range(0.015, 0.11)
		var big := rng.randf() < 0.12
		var amp := rng.randf_range(0.35, 0.7) if big else rng.randf_range(0.06, 0.28)
		var length_s := 0.012 if big else 0.004
		var tau := sr * (0.003 if big else 0.0012)
		var lpc := 0.0
		var at := int(sr * at_s)
		var cut := rng.randf_range(0.25, 0.6)
		for j in int(sr * length_s):
			if at + j >= n:
				break
			var x := rng.randf_range(-1.0, 1.0)
			lpc += (x - lpc) * cut
			buf[at + j] += (x - lpc) * amp * exp(-j / tau)
		# un éclat est souvent suivi de deux ou trois petits tics
		if big:
			for q in rng.randi_range(1, 3):
				var at2 := at + int(sr * rng.randf_range(0.01, 0.05))
				var a2 := amp * 0.35
				for j in int(sr * 0.003):
					if at2 + j >= n:
						break
					buf[at2 + j] += rng.randf_range(-1.0, 1.0) * a2 * exp(-j / (sr * 0.0008))
	# fondu de fin
	for i in int(sr * 0.6):
		buf[n - 1 - i] *= pow(i / (sr * 0.6), 1.5)
	_embers_wav = _to_wav(buf, sr, false)
	return _embers_wav

static func _to_wav(buf: PackedFloat32Array, sr: int, loop: bool) -> AudioStreamWAV:
	var peak := 0.001
	for x in buf:
		peak = maxf(peak, absf(x))
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.85, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = sr
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w

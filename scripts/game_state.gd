extends Node
# Autoload « GameState » : partie en cours façon roguelite.
# Une partie = tutoriel (niveau 0) puis RUN_LENGTH niveaux générés, chacun dans un biome tiré
# au hasard parmi 9. Boss « Gardien » à la fin du niveau 3, boss final à la fin du dernier.

const Levels = preload("res://scripts/levels.gd")
const Charms = preload("res://scripts/charms.gd")
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")

const RUN_LENGTH := 5
const MID_BOSS_AT := 3

signal equipment_changed

# Difficultés. soul/ult : gain d'âme et d'ultime · speed : vitesse des ennemis et projectiles ·
# aggro : portée de détection et cadence d'attaque · hp : vie des ennemis · dmg : dégâts reçus ·
# count : nombre d'ennemis · elite : chance qu'un ennemi soit une version élite ·
# variety : fréquence des nouveaux ennemis (sauteur h, garde à bouclier g)
const DIFFS := [
	{"name": "Facile", "color": Color(0.55, 0.9, 0.6),
		"desc": "Âme et ultime se remplissent plus vite. Ennemis plus lents, plus fragiles et moins nombreux.",
		"soul": 1.35, "ult": 1.3, "speed": 0.85, "aggro": 0.8, "hp": 0.75, "boss_hp": 0.75, "dmg": 1, "count": 0.7, "elite": 0.0, "variety": 0.5},
	{"name": "Normal", "color": Color(0.7, 0.85, 1.0),
		"desc": "L'expérience prévue : exigeante mais juste.",
		"soul": 1.0, "ult": 1.0, "speed": 1.0, "aggro": 1.0, "hp": 1.0, "boss_hp": 1.0, "dmg": 1, "count": 1.0, "elite": 0.1, "variety": 1.0},
	{"name": "Difficile", "color": Color(1.0, 0.7, 0.4),
		"desc": "Âme et ultime plus lents à remplir. Ennemis plus vifs, plus agressifs, plus résistants, plus nombreux et plus variés.",
		"soul": 0.75, "ult": 0.8, "speed": 1.25, "aggro": 1.35, "hp": 1.35, "boss_hp": 1.3, "dmg": 1, "count": 1.35, "elite": 0.3, "variety": 2.0},
	{"name": "Cauchemar", "color": Color(1.0, 0.4, 0.4),
		"desc": "Comme Difficile, en pire : chaque coup reçu retire 2 fragments, les élites pullulent.",
		"soul": 0.6, "ult": 0.65, "speed": 1.4, "aggro": 1.6, "hp": 1.6, "boss_hp": 1.5, "dmg": 2, "count": 1.6, "elite": 0.5, "variety": 3.0},
]

var difficulty := 1
var show_title := true       # écran titre au lancement du jeu

# Valeur d'un paramètre de la difficulté en cours
func d(key: String):
	return DIFFS[difficulty][key]

func diff_name() -> String:
	return DIFFS[difficulty]["name"]

var level_index := 0
var run_seed := 0
var run_biomes: Array = []   # indices dans Biomes.all()
var prog := {}               # progression en direct
var snapshot := {}           # copie au début du niveau (pour « Recommencer le niveau »)
var _cache := {}             # niveaux déjà générés (même graine = même niveau)

func _ready() -> void:
	_new_run()

func _fresh() -> Dictionary:
	return {"geo": 0, "can_dash": false, "owned": [], "equipped": [], "notches": 3, "collected": []}

func _new_run() -> void:
	randomize()
	run_seed = randi() % 1000000
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var pool := range(Biomes.all().size())
	run_biomes = []
	for i in RUN_LENGTH:
		var j := rng.randi_range(0, pool.size() - 1)
		run_biomes.append(pool[j])
		pool.remove_at(j)
	_cache.clear()
	prog = _fresh()
	snapshot = prog.duplicate(true)

# ---------------------------------------------------------------- niveaux
func level_count() -> int:
	return 1 + RUN_LENGTH

func is_tutorial() -> bool:
	return level_index == 0

func is_last_level() -> bool:
	return level_index >= RUN_LENGTH

func current_level() -> Dictionary:
	if level_index == 0:
		var t: Dictionary = Levels.LEVELS[0].duplicate()
		t["music"] = ["res://music/tuto_premiers_pas.ogg"]
		return t
	if not _cache.has(level_index):
		var biome: Dictionary = Biomes.all()[run_biomes[level_index - 1]]
		var boss := ""
		if level_index == MID_BOSS_AT:
			boss = "K"
		elif level_index == RUN_LENGTH:
			boss = "Q"
		var gen := LevelGen.new()
		var seed_value := run_seed * 31 + level_index * 7919
		_cache[level_index] = {
			"name": biome["name"],
			"map": gen.generate(biome, seed_value, level_index, boss, level_index == RUN_LENGTH, DIFFS[difficulty]),
			"music": biome["music"],
			"boss_music": "res://music/boss_abbesse_engloutie.ogg" if boss == "Q" else "res://music/boss_gardien_du_puits.ogg",
			"palette": biome["pal"],
			"seed": seed_value,
		}
	return _cache[level_index]

func biome_names() -> Array:
	var out := []
	for b in run_biomes:
		out.append(Biomes.all()[b]["name"])
	return out

func go_next_level(player) -> void:
	if is_tutorial():
		prog["can_dash"] = true          # la Ruée apprise au tutoriel est conservée
	else:
		prog["geo"] = player.geo
		prog["can_dash"] = player.can_dash
	level_index = mini(level_index + 1, RUN_LENGTH)
	snapshot = prog.duplicate(true)
	_reload(true)

func restart_level() -> void:
	prog = snapshot.duplicate(true)
	_reload(false)

func new_game(skip_tutorial := false, diff := -1) -> void:
	if diff >= 0:
		difficulty = diff
	show_title = false
	_new_run()
	level_index = 1 if skip_tutorial else 0
	if skip_tutorial:
		prog["can_dash"] = true
		snapshot = prog.duplicate(true)
	_reload(false)

func _reload(deferred: bool) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if deferred:
		get_tree().call_deferred("reload_current_scene")
	else:
		get_tree().reload_current_scene()

# ---------------------------------------------------------------- emblèmes
func charm_count() -> int:
	return Charms.CHARMS.size()

func charm(id: int) -> Dictionary:
	return Charms.CHARMS[id]

func owns(id: int) -> bool:
	return prog["owned"].has(id)

func has_charm(id: int) -> bool:
	return prog["equipped"].has(id)

func notches_used() -> int:
	var n := 0
	for id in prog["equipped"]:
		n += int(Charms.CHARMS[id]["cost"])
	return n

func add_charm(id: int) -> void:
	if not owns(id):
		prog["owned"].append(id)

func add_notch(key: String) -> void:
	if not is_collected(key):
		prog["collected"].append(key)
		prog["notches"] = int(prog["notches"]) + 1

func is_collected(key: String) -> bool:
	return prog["collected"].has(key)

func toggle_equip(id: int) -> String:
	if not owns(id):
		return "Emblème inconnu."
	if has_charm(id):
		prog["equipped"].erase(id)
	else:
		if notches_used() + int(Charms.CHARMS[id]["cost"]) > int(prog["notches"]):
			return "Pas assez d'encoches."
		prog["equipped"].append(id)
	equipment_changed.emit()
	return ""

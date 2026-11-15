extends Node
# Autoload « GameState » : progression du joueur.
#  mode "tutorial" : le tutoriel (fait à la main)
#  mode "hub"      : le Sanctuaire (banc, marchand, ascenseur)
#  mode "descent"  : un palier = 2 niveaux générés, le 2e se termine par un boss.
#                    Palier terminé → retour au hub, palier suivant débloqué (paliers sans fin).
# Mort pendant une descente → retour au hub, le butin de la descente est perdu.
# La progression est sauvegardée dans save.cfg (user:// ou dossier « sauvegardes » en mode portable).

const WeaponsData = preload("res://scripts/weapons.gd")
const Levels = preload("res://scripts/levels.gd")
const Charms = preload("res://scripts/charms.gd")
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
const Paths = preload("res://scripts/paths.gd")
const SAVE_NAME := "save.cfg"   # voir paths.gd (mode portable)
const STEPS_PER_PALIER := 2
const MAX_BONUS_HP := 4

signal equipment_changed

# Boss : chaque palier se termine par l'un d'eux. Le Gardien ouvre toujours la marche,
# les autres arrivent dans un ordre propre à chaque partie, puis le cycle recommence (plus durs).
const BOSSES := {
	"gardien": {"name": "Gardien du Puits", "music": "res://music/boss_gardien_du_puits.ogg"},
	"abbesse": {"name": "L'Abbesse Engloutie", "music": "res://music/boss_abbesse_engloutie.ogg"},
	"reine": {"name": "La Reine Essaim", "music": "res://music/boss_reine_essaim.ogg"},
	"colosse": {"name": "Le Colosse d'Os", "music": "res://music/boss_colosse_d_os.ogg"},
	"ver": {"name": "Le Ver des Profondeurs", "music": "res://music/boss_ver_des_profondeurs.ogg"},
	"chevalier": {"name": "Le Chevalier Spectral", "music": "res://music/boss_chevalier_spectral.ogg"},
	"ombre": {"name": "L'Ombre de la Lanterne", "music": "res://music/boss_chevalier_spectral.ogg"},
}

func boss_for(p: int) -> String:
	if p % 7 == 0:
		return "ombre"     # boss final : palier 7, 14, 21…
	var rest := ["abbesse", "reine", "colosse", "ver", "chevalier"]
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed * 13 + 5
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = rest[i]
		rest[i] = rest[j]
		rest[j] = tmp
	var order := ["gardien"] + rest
	return order[(p - 1) % order.size()]

func boss_name_for_id(id: String) -> String:
	return tr(BOSSES[id]["name"])

func boss_name_for(p: int) -> String:
	return tr(BOSSES[boss_for(p)]["name"])

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

var mode := "tutorial"
var palier := 1              # palier en cours (descente)
var step := 1                # niveau dans le palier (1..STEPS_PER_PALIER)
var unlocked := 1            # plus haut palier accessible par l'ascenseur
var record := 0              # plus haut palier terminé
var run_seed := 0
var prog := {}               # progression : éclats, emblèmes, encoches, vie bonus…
var snapshot := {}           # état au départ de la descente (restauré à la mort)
var pending_message := ""    # message à afficher à l'arrivée dans la scène suivante
var _cache := {}

# Valeur d'un paramètre de la difficulté en cours
func d(key: String):
	return DIFFS[difficulty][key]

func diff_name() -> String:
	return tr(DIFFS[difficulty]["name"])

# Paramètre de difficulté ajusté à la profondeur : chaque palier rend les ennemis plus coriaces
func scaled(key: String) -> float:
	var base := float(d(key))
	var p := float(palier - 1) if mode in ["descent", "rush"] else 0.0
	if curse == "haste" and mode == "descent" and key in ["speed", "aggro"]:
		base *= 1.25 if key == "speed" else 1.15
	match key:
		"hp", "boss_hp":
			return base * (1.0 + 0.18 * p)
		"speed":
			return base * minf(1.0 + 0.05 * p, 1.5)
		"aggro":
			return base * minf(1.0 + 0.08 * p, 1.8)
		"count":
			return base * minf(1.0 + 0.1 * p, 2.0)
		"elite":
			return minf(base + 0.06 * p, 0.85)
	return base

func _ready() -> void:
	prog = _fresh()
	snapshot = prog.duplicate(true)
	randomize()
	run_seed = randi() % 1000000

func _fresh() -> Dictionary:
	return {"geo": 0, "can_dash": false, "owned": [], "equipped": [], "notches": 3, "collected": [],
		"bonus_hp": 0, "notches_bought": 0, "weapon": "aiguille", "weapons_owned": []}

# ---------------------------------------------------------------- niveaux
func is_tutorial() -> bool:
	return mode == "tutorial"

func is_hub() -> bool:
	return mode == "hub"

func is_boss_level() -> bool:
	return (mode == "descent" and step == STEPS_PER_PALIER) or mode == "rush"

# ---------------------------------------------------------------- malédictions, descente du jour, défi des boss
const CURSES := {
	"": {"name": "Aucune malédiction", "desc": "Descente normale.", "geo": 1.0},
	"haste": {"name": "Hâte", "desc": "Ennemis 25 % plus rapides et plus agressifs. Éclats +50 %.", "geo": 1.5},
	"dark": {"name": "Obscurité", "desc": "La lumière se réduit autour de toi. Éclats +50 %.", "geo": 1.5},
	"fragile": {"name": "Fragilité", "desc": "Impossible de se soigner avec l'âme. Éclats +60 %.", "geo": 1.6},
}
const RUSH_REWARD := 300
const RUSH_ORDER := ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre"]
var curse := ""
var daily := false
var saved_seed := 0
var rush_i := 0

func geo_mult() -> float:
	return float(CURSES.get(curse, CURSES[""])["geo"]) if mode == "descent" else 1.0

static func today_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

func start_daily(player) -> void:
	if player:
		prog["geo"] = player.geo
	saved_seed = run_seed
	run_seed = today_seed()
	daily = true
	curse = ""
	_cache.clear()
	_start(3)

func start_rush(player) -> void:
	if player:
		prog["geo"] = player.geo
	snapshot = prog.duplicate(true)
	mode = "rush"
	rush_i = 0
	palier = 6
	step = 1
	curse = ""
	trial_weapon = ""
	Achievements.reset_run()
	save_game()
	_reload(true)

# Fin d'un mode spécial : retour au hub avec le bon état
func _end_special() -> void:
	if daily:
		run_seed = saved_seed
		daily = false
		_cache.clear()
	prog = snapshot.duplicate(true)
	curse = ""
	mode = "hub"

func depth() -> int:
	return (palier - 1) * STEPS_PER_PALIER + step

func current_level() -> Dictionary:
	if mode == "tutorial":
		var t: Dictionary = Levels.LEVELS[0].duplicate()
		t["music"] = ["res://music/tuto_premiers_pas.ogg"]
		return t
	if mode == "hub":
		var h: Dictionary = Levels.HUB.duplicate()
		h["music"] = ["res://music/sanctuaire.ogg"]
		return h
	if mode == "rush":
		return _rush_level()
	var key := "%d-%d-%d" % [run_seed, palier, step]
	if not _cache.has(key):
		var all := Biomes.all()
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed * 7 + palier * 1013
		var b1 := rng.randi_range(0, all.size() - 1)
		var b2 := (b1 + rng.randi_range(1, all.size() - 1)) % all.size()
		var biome: Dictionary = all[b1 if step == 1 else b2]
		var boss := ""
		var boss_id := ""
		if is_boss_level():
			boss = "K"
			boss_id = boss_for(palier)
		var gen := LevelGen.new()
		var seed_value := run_seed * 31 + palier * 7919 + step * 104729
		var diff: Dictionary = DIFFS[difficulty].duplicate()
		diff["count"] = scaled("count")
		_cache[key] = {
			"name": biome["name"],
			"map": gen.generate(biome, seed_value, mini(depth(), 10), boss, false, diff),
			"music": biome["music"],
			"boss_id": boss_id,
			"boss_music": BOSSES[boss_id]["music"] if boss_id != "" else "",
			"palette": biome["pal"],
			"seed": seed_value,
		}
	return _cache[key]

func _rush_level() -> Dictionary:
	var key := "rush-%d" % rush_i
	if not _cache.has(key):
		var bid: String = RUSH_ORDER[rush_i]
		var all: Array = Biomes.all()
		var biome: Dictionary = all[rush_i % all.size()]
		var gen := LevelGen.new()
		var diff: Dictionary = DIFFS[difficulty].duplicate()
		_cache[key] = {
			"name": biome["name"], "map": gen.generate(biome, 777 + rush_i, 6, "K", false, diff, true),
			"music": biome["music"], "boss_id": bid, "boss_music": BOSSES[bid]["music"],
			"palette": biome["pal"], "seed": 777 + rush_i,
		}
	return _cache[key]

# Fin du niveau en cours (passage lumineux atteint)
func go_next_level(player) -> void:
	if mode == "rush":
		rush_i += 1
		if rush_i >= RUSH_ORDER.size():
			var t := float(Achievements.run.get("time", 0.0))
			var best := float(Achievements.counters.get("rush_best", 0.0))
			if best <= 0.0 or t < best:
				Achievements.counters["rush_best"] = t
				Achievements.save()
			Achievements.unlock("rush")
			_end_special()
			prog["geo"] = int(prog.get("geo", 0)) + RUSH_REWARD     # récompense gardée
			snapshot = prog.duplicate(true)
			pending_message = tr("Défi des boss terminé en %d:%02d !") % [int(t) / 60, int(t) % 60] + "  " + tr("+%d éclats") % RUSH_REWARD + "\n" + tr("Meilleur temps : %d:%02d") % [int(Achievements.counters["rush_best"]) / 60, int(Achievements.counters["rush_best"]) % 60]
			save_game()
		_reload(true)
		return
	if mode == "descent" and daily and step >= STEPS_PER_PALIER:
		var t2 := float(Achievements.run.get("time", 0.0))
		var dkey := "daily_%d" % run_seed
		var best2 := float(Achievements.counters.get(dkey, 0.0))
		if best2 <= 0.0 or t2 < best2:
			Achievements.counters[dkey] = t2
			Achievements.save()
		Achievements.unlock("daily")
		_end_special()
		pending_message = tr("Descente du jour réussie en %d:%02d !") % [int(t2) / 60, int(t2) % 60] + "\n" + tr("Meilleur temps du jour : %d:%02d") % [int(Achievements.counters[dkey]) / 60, int(Achievements.counters[dkey]) % 60] + "\n" + Achievements.run_summary()
		save_game()
		_reload(true)
		return
	if mode == "tutorial":
		prog["can_dash"] = true
		mode = "hub"
		pending_message = "Le Sanctuaire de la Lanterne\nParle au marchand, puis prends l'ascenseur pour descendre."
	elif mode == "descent":
		prog["geo"] = player.geo
		if step < STEPS_PER_PALIER:
			step += 1
		else:
			record = maxi(record, palier)
			unlocked = maxi(unlocked, palier + 1)
			mode = "hub"
			pending_message = tr("Palier %d terminé !\nL'ascenseur peut maintenant descendre jusqu'au palier %d.") % [palier, unlocked]
			pending_message += "\n" + Achievements.run_summary()
			_palier_done()
			if curse != "":
				Achievements.unlock("curse")
			curse = ""
	save_game()
	_reload(true)

# Départ en descente depuis l'ascenseur du hub
func start_descent(p: int, player, curse_id := "") -> void:
	if player:
		prog["geo"] = player.geo
	curse = curse_id
	_start(clampi(p, 1, unlocked))

func _start(p: int) -> void:
	palier = p
	step = 1
	mode = "descent"
	trial_weapon = ""
	Achievements.reset_run()
	snapshot = prog.duplicate(true)
	save_game()
	_reload(true)

# Mort pendant une descente : retour au hub, le butin ramassé depuis le départ est perdu
func die_in_descent(geo_now: int = -1, pos: Vector2 = Vector2.ZERO) -> void:
	if mode == "rush" or daily:
		var what := tr("Défi des boss échoué (boss %d / %d).") % [rush_i + 1, RUSH_ORDER.size()] if mode == "rush" else tr("Descente du jour échouée.")
		_end_special()
		pending_message = what + "\n" + Achievements.run_summary()
		save_game()
		_reload(true)
		return
	var where := tr("Vous avez sombré au palier %d (niveau %d/%d).") % [palier, step, STEPS_PER_PALIER]
	var lost := geo_now - int(snapshot.get("geo", 0))
	prog = snapshot.duplicate(true)
	curse = ""
	# l'ombre garde les éclats perdus (une ombre non récupérée est remplacée)
	if geo_now >= 0 and lost > 0 and mode == "descent":
		prog["shade"] = {"palier": palier, "step": step, "x": pos.x, "y": pos.y, "geo": lost}
		where += "\n" + tr("Ton ombre garde %d éclats là où tu es tombé.") % lost
	where += "\n" + Achievements.run_summary()
	mode = "hub"
	pending_message = where + "\n" + tr("Le butin de cette descente est perdu, mais l'ascenseur se souvient.")
	save_game()
	_reload(true)

func abandon_descent() -> void:
	if mode == "rush" or daily:
		_end_special()
	curse = ""
	prog = snapshot.duplicate(true)
	mode = "hub"
	pending_message = tr("Descente abandonnée. Le butin de cette descente est perdu.") + "\n" + Achievements.run_summary()
	save_game()
	_reload(false)

func restart_level() -> void:
	_reload(false)

func new_game(skip_tutorial := false, diff := -1) -> void:
	if diff >= 0:
		difficulty = diff
	show_title = false
	randomize()
	run_seed = randi() % 1000000
	_cache.clear()
	prog = _fresh()
	unlocked = 1
	record = 0
	palier = 1
	step = 1
	if skip_tutorial:
		prog["can_dash"] = true
		mode = "hub"
		pending_message = "Le Sanctuaire de la Lanterne\nParle au marchand, puis prends l'ascenseur pour descendre."
	else:
		mode = "tutorial"
	snapshot = prog.duplicate(true)
	save_game()
	_reload(false)

func continue_game() -> void:
	if load_game():
		show_title = false
		mode = "hub"
		pending_message = "Bon retour au Sanctuaire."
		_reload(false)

func _reload(deferred: bool) -> void:
	Engine.time_scale = Settings.speed()
	get_tree().paused = false
	if deferred:
		get_tree().call_deferred("reload_current_scene")
	else:
		get_tree().reload_current_scene()

# ---------------------------------------------------------------- sauvegarde
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "version", 1)
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "unlocked", unlocked)
	cfg.set_value("game", "record", record)
	cfg.set_value("game", "run_seed", saved_seed if daily else run_seed)
	cfg.set_value("game", "tutorial_done", mode != "tutorial")
	# en descente on sauvegarde l'état du départ : quitter en pleine descente = abandon
	cfg.set_value("game", "prog", snapshot if mode in ["descent", "rush"] else prog)
	cfg.save(Paths.file(SAVE_NAME))

func has_save() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(Paths.file(SAVE_NAME)) == OK and bool(cfg.get_value("game", "tutorial_done", false))

func save_summary() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) != OK:
		return ""
	var dd: int = clampi(int(cfg.get_value("game", "difficulty", 1)), 0, DIFFS.size() - 1)
	var p: Dictionary = cfg.get_value("game", "prog", {})
	return tr("%s — palier %d accessible — record : palier %d — %d éclats") % [
		tr(DIFFS[dd]["name"]), int(cfg.get_value("game", "unlocked", 1)), int(cfg.get_value("game", "record", 0)), int(p.get("geo", 0))]

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) != OK:
		return false
	difficulty = clampi(int(cfg.get_value("game", "difficulty", 1)), 0, DIFFS.size() - 1)
	unlocked = int(cfg.get_value("game", "unlocked", 1))
	record = int(cfg.get_value("game", "record", 0))
	run_seed = int(cfg.get_value("game", "run_seed", run_seed))
	var p = cfg.get_value("game", "prog", {})
	prog = _fresh()
	if p is Dictionary:
		for k in p:
			prog[k] = p[k]
	snapshot = prog.duplicate(true)
	_cache.clear()
	return true

# ---------------------------------------------------------------- marchand
func max_hp_bonus() -> int:
	return int(prog.get("bonus_hp", 0))

func charm_price(id: int) -> int:
	return 60 * int(Charms.CHARMS[id]["cost"])

func notch_price() -> int:
	return 120 + 80 * int(prog.get("notches_bought", 0))

func hp_price() -> int:
	return 150 + 100 * max_hp_bonus()

# Achat : renvoie "" si c'est fait, sinon la raison du refus
func buy(kind: String, id: int, player) -> String:
	var price := 0
	match kind:
		"charm":
			if owns(id):
				return "Déjà possédé."
			price = charm_price(id)
		"notch":
			price = notch_price()
		"hp":
			if max_hp_bonus() >= MAX_BONUS_HP:
				return "Le marchand n'en a plus."
			price = hp_price()
	if player.geo < price:
		return tr("Pas assez d'éclats (%d nécessaires).") % price
	player.geo -= price
	prog["geo"] = player.geo
	match kind:
		"charm":
			add_charm(id)
		"notch":
			prog["notches"] = int(prog["notches"]) + 1
			prog["notches_bought"] = int(prog.get("notches_bought", 0)) + 1
		"hp":
			prog["bonus_hp"] = max_hp_bonus() + 1
			player.apply_equipment()
			player.hp = player.max_hp
	if mode == "hub":
		snapshot = prog.duplicate(true)   # en descente, l'achat fait partie du butin (perdu à la mort)
	save_game()
	return ""

# ---------------------------------------------------------------- armes (arsenal)
var trial_weapon := ""   # arme essayée à l'arsenal (au Sanctuaire seulement, non sauvegardée)

func weapon() -> String:
	if trial_weapon != "" and mode == "hub":
		return trial_weapon
	return str(prog.get("weapon", "aiguille"))

func owns_weapon(id: String) -> bool:
	return id == "aiguille" or (prog.get("weapons_owned", []) as Array).has(id)

func weapon_level(id: String = "") -> int:
	if id == "":
		id = weapon()
	return int((prog.get("weapon_lv", {}) as Dictionary).get(id, 1))

func upgrade_weapon(id: String, player) -> String:
	if weapon_level(id) >= 2:
		return "Déjà améliorée."
	if not owns_weapon(id):
		return "Achète d'abord cette arme."
	var price := int(WeaponsData.UP[id]["price"])
	if player.geo < price:
		return tr("Pas assez d'éclats (%d nécessaires).") % price
	player.geo -= price
	prog["geo"] = player.geo
	var lv: Dictionary = prog.get("weapon_lv", {})
	lv[id] = 2
	prog["weapon_lv"] = lv
	snapshot = prog.duplicate(true)
	save_game()
	Achievements.unlock("forge")
	return ""

func equip_weapon(id: String) -> void:
	if owns_weapon(id):
		prog["weapon"] = id
		snapshot = prog.duplicate(true)
		save_game()

func buy_weapon(id: String, player) -> String:
	if owns_weapon(id):
		return "Déjà possédée."
	var price := int(WeaponsData.get_w(id)["price"])
	if player.geo < price:
		return tr("Pas assez d'éclats (%d nécessaires).") % price
	player.geo -= price
	prog["geo"] = player.geo
	var arr: Array = prog.get("weapons_owned", [])
	arr.append(id)
	prog["weapons_owned"] = arr
	if arr.size() >= 3:
		Achievements.unlock("arsenal")
	prog["weapon"] = id
	snapshot = prog.duplicate(true)
	save_game()
	return ""

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
	if prog["owned"].size() >= charm_count():
		Achievements.unlock("charms")

# Succès liés à la fin d'un palier
func _palier_done() -> void:
	if palier >= 1:
		Achievements.unlock("palier1")
	if palier >= 3:
		Achievements.unlock("palier3")
	if palier >= 6:
		Achievements.unlock("palier6")
	if int(Achievements.run.get("hurt", 0)) == 0:
		Achievements.unlock("flawless")

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

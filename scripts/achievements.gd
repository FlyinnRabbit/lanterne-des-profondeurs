extends Node
# Autoload « Achievements » : succès et statistiques, communs à toutes les parties
# (fichier achievements.cfg, voir paths.gd). Les statistiques de descente sont dans « run ».

const Paths = preload("res://scripts/paths.gd")
const SAVE_NAME := "achievements.cfg"

const LIST := [
	["palier1", "Premiers pas", "Termine le palier 1."],
	["palier3", "Plus profond", "Termine le palier 3."],
	["palier6", "Abysses", "Termine le palier 6."],
	["final", "Lanterne rallumée", "Vaincs le boss final du palier 7."],
	["finals4", "Les quatre gardiens", "Vaincs les quatre boss finaux (un par partie, tiré au hasard)."],
	["flawless", "Intouchable", "Termine un palier sans être touché."],
	["perfect10", "Maître de la parade", "Réussis 10 parades parfaites d'affilée sans être touché."],
	["crit50", "Coup de grâce", "Porte 50 coups critiques."],
	["plunge", "Météore", "Vaincs un ennemi avec une attaque plongée."],
	["shade", "Retour d'outre-tombe", "Récupère les éclats de ton ombre."],
	["rich", "Trésor", "Possède 1000 éclats."],
	["arsenal", "Collectionneur", "Possède les 4 armes."],
	["forge", "Forgée", "Améliore une arme chez la forgeronne."],
	["charms", "Tous les emblèmes", "Possède tous les emblèmes."],
	["curse", "Maudit", "Termine un palier avec une malédiction."],
	["daily", "Graine du jour", "Termine le palier 1 d'une descente du jour."],
	["rush", "Marathon", "Termine le défi des boss."],
	["room", "Explorateur", "Réussis une salle spéciale (trésor, défi chronométré ou arène)."],
	["palier10", "Sans fond", "Termine le palier 10."],
	["nightmare", "Cauchemar éveillé", "Termine un palier en difficulté Cauchemar."],
	["kills500", "Veilleur aguerri", "Vaincs 500 ennemis."],
	["elite25", "Chasseur d'élites", "Vaincs 25 élites."],
	["parry100", "Mur d'acier", "Réussis 100 parades."],
	["trophy", "Trophée", "Obtiens un cosmétique rare en battant un boss."],
	["wardrobe", "Garde-robe", "Possède 10 cosmétiques."],
	["fashion", "Sur son trente-et-un", "Porte un cosmétique non standard dans chaque catégorie."],
	["noel", "Esprit de Noël", "Termine un palier pendant l'évènement de Noël."],
	["gift", "Sous le sapin", "Ouvre ton cadeau au Sanctuaire pendant l'évènement de Noël."],
	["calendar", "Calendrier du Veilleur", "Ouvre le cadeau de chacune des quatre fêtes."],
]

# Cosmétiques offerts en plus par ces succès (les autres liens sont dans cosmetics.gd, clé "ach").
signal cosmetic_unlocked(item_id: String)

var done := {}           # id -> true
var counters := {}       # crits, perfect_streak…
var run := {}            # statistiques de la descente en cours
signal unlocked(id: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) == OK:
		done = cfg.get_value("ach", "done", {})
		counters = cfg.get_value("ach", "counters", {})
	reset_run()
	GameState.cos.sync_achievements(done)

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ach", "done", done)
	cfg.set_value("ach", "counters", counters)
	cfg.save(Paths.file(SAVE_NAME))

func info(id: String) -> Array:
	for a in LIST:
		if a[0] == id:
			return a
	return [id, id, ""]

func unlock(id: String) -> void:
	if done.has(id):
		return
	done[id] = true
	save()
	unlocked.emit(id)
	for item_id in GameState.cos.for_achievement(id):
		give_cosmetic(item_id)

# Donne un cosmétique et prévient le joueur.
func give_cosmetic(item_id: String) -> bool:
	if not GameState.cos.grant(item_id):
		return false
	cosmetic_unlocked.emit(item_id)
	check_wardrobe()
	return true

func check_wardrobe() -> void:
	var c = GameState.cos
	if c.owned_count() >= 10:
		unlock("wardrobe")
	var all := true
	for cat in c.CATS:
		if c.eq(cat) == c.DEFAULTS[cat]:
			all = false
	if all:
		unlock("fashion")

func on_kill(elite: bool) -> void:
	if count("kills") >= 500:
		unlock("kills500")
	if elite and count("elites") >= 25:
		unlock("elite25")
	if int(counters["kills"]) % 25 == 0:
		save()

func on_parry() -> void:
	if count("parries") >= 100:
		unlock("parry100")

func count(key: String, add := 1) -> int:
	counters[key] = int(counters.get(key, 0)) + add
	return int(counters[key])

# ---------------------------------------------------------------- statistiques de descente
func reset_run() -> void:
	run = {"kills": 0, "damage": 0, "crits": 0, "perfect": 0, "hurt": 0, "time": 0.0}

func stat(key: String, add = 1) -> void:
	run[key] = run.get(key, 0) + add

func run_summary() -> String:
	var t := int(run.get("time", 0.0))
	return tr("Ennemis vaincus : %d   Dégâts : %d   Critiques : %d\nParades parfaites : %d   Coups reçus : %d   Temps : %d:%02d") % [
		int(run["kills"]), int(run["damage"]), int(run["crits"]), int(run["perfect"]), int(run["hurt"]), t / 60, t % 60]

# Événements de jeu
func on_crit() -> void:
	stat("crits")
	if count("crits") >= 50:
		unlock("crit50")

func on_perfect_parry() -> void:
	stat("perfect")
	counters["streak"] = int(counters.get("streak", 0)) + 1
	if int(counters["streak"]) >= 10:
		unlock("perfect10")

func on_hurt() -> void:
	stat("hurt")
	counters["streak"] = 0

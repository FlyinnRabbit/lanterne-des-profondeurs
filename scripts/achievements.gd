extends Node
# Autoload « Achievements » : succès et statistiques, communs à toutes les parties
# (fichier achievements.cfg, voir paths.gd). Les statistiques de descente sont dans « run ».

const Paths = preload("res://scripts/paths.gd")
const SAVE_NAME := "achievements.cfg"

const LIST := [
	["palier1", "Premiers pas", "Termine le palier 1."],
	["palier3", "Plus profond", "Termine le palier 3."],
	["palier6", "Abysses", "Termine le palier 6."],
	["final", "Lanterne rallumée", "Vaincs l'Ombre de la Lanterne (palier 7)."],
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
]

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

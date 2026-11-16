extends RefCounted
# Cosmétiques du héros (communs à toutes les parties, fichier cosmetics.cfg) :
# cape, écharpe, couvre-chef, traînée, familier, ultime. Purement visuels.
# Accès : GameState.cos  (ce n'est PAS un autoload : un patch de mise à jour ne peut pas en ajouter).
#
# Obtention : "price" = vendu par la tailleuse ; "ach" = offert par un succès ;
# "boss" = butin rare d'un boss ; "season" = vendu (ou offert) seulement pendant l'évènement.
const Paths = preload("res://scripts/paths.gd")
const DU = preload("res://scripts/draw_util.gd")
const SAVE_NAME := "cosmetics.cfg"
const BOSS_DROP_CHANCE := 0.25

const CATS := ["cape", "scarf", "hat", "trail", "pet", "ult"]
const CAT_NAMES := {"cape": "Cape", "scarf": "Écharpe", "hat": "Couvre-chef", "trail": "Traînée et lueurs", "pet": "Familier", "ult": "Ultime"}
const DEFAULTS := {"cape": "cape_ombre", "scarf": "scarf_sarcelle", "hat": "hat_none", "trail": "trail_ombre", "pet": "pet_none", "ult": "ult_or"}

# c = couleur principale ; c2 = couleur secondaire
const ITEMS := {
	# --- capes
	"cape_ombre": {"cat": "cape", "name": "Cape d'ombre", "c": Color(0.1, 0.085, 0.16), "c2": Color(0.3, 0.27, 0.42)},
	"cape_braise": {"cat": "cape", "name": "Cape de braise", "price": 80, "c": Color(0.3, 0.07, 0.06), "c2": Color(0.75, 0.35, 0.2)},
	"cape_mousse": {"cat": "cape", "name": "Cape de mousse", "price": 80, "c": Color(0.08, 0.2, 0.12), "c2": Color(0.4, 0.6, 0.35)},
	"cape_givre": {"cat": "cape", "name": "Cape de givre", "price": 80, "c": Color(0.3, 0.42, 0.55), "c2": Color(0.8, 0.92, 1.0)},
	"cape_amethyste": {"cat": "cape", "name": "Cape d'améthyste", "price": 120, "c": Color(0.17, 0.06, 0.25), "c2": Color(0.7, 0.45, 0.9)},
	"cape_os": {"cat": "cape", "name": "Cape d'ivoire", "price": 120, "c": Color(0.72, 0.68, 0.58), "c2": Color(0.4, 0.36, 0.3)},
	"cape_or": {"cat": "cape", "name": "Cape du Veilleur doré", "ach": "final", "c": Color(0.36, 0.25, 0.06), "c2": Color(1.0, 0.85, 0.45)},
	"cape_nuit": {"cat": "cape", "name": "Cape de nuit étoilée", "ach": "finals4", "c": Color(0.04, 0.05, 0.16), "c2": Color(0.75, 0.85, 1.0), "stars": true},
	"cape_noel": {"cat": "cape", "name": "Cape de Noël", "price": 100, "season": "noel", "c": Color(0.65, 0.08, 0.08), "c2": Color(0.95, 0.95, 0.95)},
	"cape_halloween": {"cat": "cape", "name": "Cape de la veillée", "price": 100, "season": "halloween", "c": Color(0.36, 0.17, 0.03), "c2": Color(0.1, 0.05, 0.12)},
	"cape_rose": {"cat": "cape", "name": "Cape de roses", "price": 100, "season": "valentin", "c": Color(0.42, 0.12, 0.24), "c2": Color(0.95, 0.65, 0.75)},
	"cape_pastel": {"cat": "cape", "name": "Cape de printemps", "price": 100, "season": "paques", "c": Color(0.3, 0.4, 0.3), "c2": Color(0.95, 0.9, 0.6)},
	# --- écharpes
	"scarf_sarcelle": {"cat": "scarf", "name": "Écharpe sarcelle", "c": Color(0.5, 0.85, 0.86), "c2": Color(0.22, 0.5, 0.55)},
	"scarf_ecarlate": {"cat": "scarf", "name": "Écharpe écarlate", "price": 40, "c": Color(0.95, 0.3, 0.25), "c2": Color(0.55, 0.12, 0.1)},
	"scarf_doree": {"cat": "scarf", "name": "Écharpe dorée", "price": 40, "c": Color(1.0, 0.85, 0.4), "c2": Color(0.6, 0.42, 0.12)},
	"scarf_blanche": {"cat": "scarf", "name": "Écharpe blanche", "price": 40, "c": Color(0.95, 0.95, 1.0), "c2": Color(0.6, 0.62, 0.72)},
	"scarf_violette": {"cat": "scarf", "name": "Écharpe violette", "price": 40, "c": Color(0.75, 0.5, 1.0), "c2": Color(0.38, 0.2, 0.55)},
	"scarf_braise": {"cat": "scarf", "name": "Écharpe de braise vive", "boss": "cerbere", "c": Color(1.0, 0.6, 0.2), "c2": Color(0.7, 0.15, 0.05), "glow": true},
	"scarf_guirlande": {"cat": "scarf", "name": "Guirlande lumineuse", "price": 60, "season": "noel", "c": Color(0.2, 0.55, 0.25), "c2": Color(0.1, 0.3, 0.14), "lights": true},
	# --- couvre-chefs
	"hat_none": {"cat": "hat", "name": "Capuche nue", "c": Color(0.3, 0.27, 0.42)},
	"hat_plume": {"cat": "hat", "name": "Plume de corbeau", "price": 90, "c": Color(0.15, 0.15, 0.22)},
	"hat_bougie": {"cat": "hat", "name": "Bougie du veilleur", "price": 90, "c": Color(1.0, 0.85, 0.5)},
	"hat_fleurs": {"cat": "hat", "name": "Couronne de fleurs", "price": 120, "c": Color(0.95, 0.6, 0.75)},
	"hat_couronne": {"cat": "hat", "name": "Couronne d'or", "ach": "rich", "c": Color(1.0, 0.85, 0.4)},
	"hat_aureole": {"cat": "hat", "name": "Auréole", "ach": "flawless", "c": Color(1.0, 0.95, 0.7)},
	"hat_cornes": {"cat": "hat", "name": "Cornes d'os", "boss": "colosse", "c": Color(0.85, 0.82, 0.72)},
	"hat_bonnet": {"cat": "hat", "name": "Bonnet de Noël", "season": "noel", "gift": true, "c": Color(0.85, 0.12, 0.12)},
	"hat_renne": {"cat": "hat", "name": "Bois de renne", "price": 120, "season": "noel", "c": Color(0.5, 0.33, 0.18)},
	"hat_citrouille": {"cat": "hat", "name": "Citrouille creusée", "season": "halloween", "gift": true, "c": Color(0.95, 0.5, 0.1)},
	"hat_coeurs": {"cat": "hat", "name": "Serre-tête à cœurs", "season": "valentin", "gift": true, "c": Color(0.95, 0.35, 0.5)},
	"hat_lapin": {"cat": "hat", "name": "Oreilles de lapin", "season": "paques", "gift": true, "c": Color(0.95, 0.92, 0.88)},
	# --- traînées et lueurs (Ruée, œil, coups)
	"trail_ombre": {"cat": "trail", "name": "Ombre et ambre", "c": Color(1.0, 0.75, 0.35), "c2": Color(0.15, 0.15, 0.25), "slash": Color(1, 1, 1)},
	"trail_braise": {"cat": "trail", "name": "Braise", "price": 100, "c": Color(1.0, 0.45, 0.2), "c2": Color(0.8, 0.25, 0.1), "slash": Color(1.0, 0.8, 0.6)},
	"trail_givre": {"cat": "trail", "name": "Givre", "price": 100, "c": Color(0.6, 0.9, 1.0), "c2": Color(0.3, 0.6, 0.85), "slash": Color(0.8, 0.95, 1.0)},
	"trail_spectre": {"cat": "trail", "name": "Spectre", "price": 100, "c": Color(0.55, 1.0, 0.6), "c2": Color(0.15, 0.5, 0.3), "slash": Color(0.8, 1.0, 0.85)},
	"trail_or": {"cat": "trail", "name": "Or pur", "ach": "crit50", "c": Color(1.0, 0.9, 0.5), "c2": Color(0.8, 0.6, 0.15), "slash": Color(1.0, 0.92, 0.6)},
	"trail_regard": {"cat": "trail", "name": "Regard d'en dessous", "boss": "oeil", "c": Color(1.0, 0.3, 0.6), "c2": Color(0.5, 0.1, 0.4), "slash": Color(1.0, 0.75, 0.9)},
	"trail_flocons": {"cat": "trail", "name": "Flocons", "price": 100, "season": "noel", "c": Color(0.9, 0.97, 1.0), "c2": Color(0.75, 0.85, 1.0), "slash": Color(0.92, 0.97, 1.0), "snow": true},
	"trail_coeurs": {"cat": "trail", "name": "Cœur battant", "price": 100, "season": "valentin", "c": Color(1.0, 0.45, 0.6), "c2": Color(0.7, 0.2, 0.4), "slash": Color(1.0, 0.8, 0.88)},
	"trail_citrouille": {"cat": "trail", "name": "Feu de citrouille", "price": 100, "season": "halloween", "c": Color(1.0, 0.6, 0.15), "c2": Color(0.35, 0.15, 0.45), "slash": Color(1.0, 0.85, 0.65)},
	# --- familiers
	"pet_none": {"cat": "pet", "name": "Aucun familier", "c": Color(0.4, 0.4, 0.5)},
	"pet_luciole": {"cat": "pet", "name": "Luciole", "price": 150, "c": Color(0.8, 1.0, 0.5)},
	"pet_papillon": {"cat": "pet", "name": "Papillon de nuit", "price": 150, "c": Color(0.8, 0.75, 0.95)},
	"pet_follet": {"cat": "pet", "name": "Feu follet", "ach": "shade", "c": Color(0.6, 0.8, 1.0)},
	"pet_lanterne": {"cat": "pet", "name": "Petite lanterne", "ach": "palier6", "c": Color(1.0, 0.8, 0.45)},
	"pet_guepe": {"cat": "pet", "name": "Guêpe de la Reine", "boss": "reine", "c": Color(1.0, 0.8, 0.2)},
	"pet_flocon": {"cat": "pet", "name": "Flocon vivant", "price": 120, "season": "noel", "c": Color(0.9, 0.97, 1.0)},
	"pet_chauvesouris": {"cat": "pet", "name": "Chauve-souris", "price": 120, "season": "halloween", "c": Color(0.6, 0.45, 0.8)},
	"pet_coeur": {"cat": "pet", "name": "Petit cœur", "price": 120, "season": "valentin", "c": Color(1.0, 0.45, 0.6)},
	"pet_poussin": {"cat": "pet", "name": "Poussin", "price": 120, "season": "paques", "c": Color(1.0, 0.9, 0.4)},
	# --- ultimes (apparence de l'onde de choc)
	"ult_or": {"cat": "ult", "name": "Onde dorée", "c": Color(1.0, 0.9, 0.6), "c2": Color(0.7, 0.9, 1.0)},
	"ult_givre": {"cat": "ult", "name": "Nova de givre", "price": 200, "c": Color(0.7, 0.92, 1.0), "c2": Color(0.4, 0.65, 1.0)},
	"ult_brasier": {"cat": "ult", "name": "Brasier", "price": 200, "c": Color(1.0, 0.55, 0.2), "c2": Color(1.0, 0.85, 0.4)},
	"ult_eclipse": {"cat": "ult", "name": "Éclipse", "ach": "rush", "c": Color(0.08, 0.05, 0.14), "c2": Color(1.0, 0.95, 0.85)},
	"ult_essaim": {"cat": "ult", "name": "Essaim spectral", "boss": "chevalier", "c": Color(0.55, 1.0, 0.75), "c2": Color(0.3, 0.6, 0.9)},
	"ult_nuee": {"cat": "ult", "name": "Nuée de chauves-souris", "price": 150, "season": "halloween", "c": Color(0.45, 0.25, 0.65), "c2": Color(1.0, 0.6, 0.15)},
	"ult_coeur": {"cat": "ult", "name": "Coup de foudre", "price": 150, "season": "valentin", "c": Color(1.0, 0.45, 0.6), "c2": Color(1.0, 0.85, 0.9)},
	"ult_eclosion": {"cat": "ult", "name": "Éclosion", "price": 150, "season": "paques", "c": Color(0.75, 0.95, 0.7), "c2": Color(1.0, 0.85, 0.95)},
	"ult_etoile": {"cat": "ult", "name": "Étoile de Noël", "price": 150, "season": "noel", "c": Color(1.0, 0.9, 0.5), "c2": Color(0.95, 0.3, 0.3)},
}

var owned := {}
var equipped := {}
var gifts := {}          # fête -> année du dernier cadeau ouvert
signal changed

func _init() -> void:
	load_data()

func load_data() -> void:
	owned = {}
	gifts = {}
	equipped = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) == OK:
		owned = cfg.get_value("cos", "owned", {})
		var eq: Dictionary = cfg.get_value("cos", "equipped", {})
		for k in eq:
			if ITEMS.has(eq[k]) and CATS.has(k):
				equipped[k] = eq[k]
		gifts = cfg.get_value("cos", "gifts", {})
		if int(cfg.get_value("cos", "gift_year", 0)) > 0:
			gifts["noel"] = int(cfg.get_value("cos", "gift_year", 0))
	for k in DEFAULTS:
		owned[DEFAULTS[k]] = true

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("cos", "owned", owned)
	cfg.set_value("cos", "equipped", equipped)
	cfg.set_value("cos", "gifts", gifts)
	cfg.save(Paths.file(SAVE_NAME))

func has(id: String) -> bool:
	return owned.has(id)

func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

func eq(cat: String) -> String:
	return String(equipped.get(cat, DEFAULTS[cat]))

func look(cat: String) -> Dictionary:
	return ITEMS.get(eq(cat), ITEMS[DEFAULTS[cat]])

# Donne un cosmétique. Renvoie vrai s'il est nouveau.
func grant(id: String) -> bool:
	if not ITEMS.has(id) or owned.has(id):
		return false
	owned[id] = true
	save()
	changed.emit()
	return true

func equip(id: String) -> void:
	if not owned.has(id) or not ITEMS.has(id):
		return
	equipped[ITEMS[id]["cat"]] = id
	save()
	changed.emit()

func items_of(cat: String) -> Array:
	var out := []
	for id in ITEMS:
		if ITEMS[id]["cat"] == cat:
			out.append(id)
	return out

func owned_count() -> int:
	var n := 0
	for id in owned:
		if ITEMS.has(id) and not (id in DEFAULTS.values()):
			n += 1
	return n

# Cosmétiques offerts par un succès (aussi pour les succès déjà obtenus avant cette version).
func for_achievement(ach: String) -> Array:
	var out := []
	for id in ITEMS:
		if ITEMS[id].get("ach", "") == ach:
			out.append(id)
	return out

func for_boss(boss: String) -> Array:
	var out := []
	for id in ITEMS:
		if ITEMS[id].get("boss", "") == boss:
			out.append(id)
	return out

func sync_achievements(done: Dictionary) -> void:
	for a in done:
		for id in for_achievement(String(a)):
			if not owned.has(id):
				owned[id] = true
	save()

# ------------------------------------------------------------------ fêtes (évènements saisonniers)
# Chaque fête : décor au Sanctuaire, un cadeau à ouvrir une fois par an, une collection en vente.
# Pour en essayer une hors saison : variable d'environnement LANTERNE_EVENT=noel|halloween|valentin|paques
const EVENTS := {
	"valentin": {"music": "res://music/valse_des_lanternes.ogg", "name": "la Saint-Valentin", "from": [2, 8], "to": [2, 16], "gift": "hat_coeurs", "ambience": "jardins",
		"lights": [Color(1.0, 0.4, 0.55), Color(1.0, 0.7, 0.8), Color(0.9, 0.2, 0.35)]},
	"paques": {"music": "res://music/matin_de_printemps.ogg", "name": "Pâques", "gift": "hat_lapin", "ambience": "jardins",
		"lights": [Color(1.0, 0.9, 0.5), Color(0.7, 0.9, 1.0), Color(1.0, 0.7, 0.85), Color(0.7, 1.0, 0.7)]},
	"halloween": {"music": "res://music/veillee_des_ombres.ogg", "name": "la Veillée des Ombres", "from": [10, 20], "to": [11, 2], "gift": "hat_citrouille", "ambience": "ossuaire",
		"lights": [Color(1.0, 0.55, 0.1), Color(0.65, 0.35, 0.9), Color(1.0, 0.55, 0.1), Color(0.5, 1.0, 0.45)]},
	"noel": {"music": "res://music/noel_veillee_de_neige.ogg", "name": "Noël", "from": [12, 1], "to": [1, 6], "gift": "hat_bonnet", "ambience": "glace",
		"lights": [Color(1.0, 0.3, 0.3), Color(1.0, 0.85, 0.3), Color(0.4, 0.7, 1.0), Color(0.5, 1.0, 0.55), Color(1.0, 0.5, 0.9)]},
}

# Dimanche de Pâques (calcul de Butcher) -> [mois, jour]
static func easter(year: int) -> Array:
	var a := year % 19
	var b := year / 100
	var c := year % 100
	var d := b / 4
	var e := b % 4
	var f := (b + 8) / 25
	var g := (b - f + 1) / 3
	var h := (19 * a + b - d - g + 15) % 30
	var i := c / 4
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := (a + 11 * h + 22 * l) / 451
	var month := (h + l - 7 * m + 114) / 31
	var day := (h + l - 7 * m + 114) % 31 + 1
	return [month, day]

static func _day_of_year(y: int, m: int, d: int) -> int:
	var days := [31, 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var n := d
	for i in m - 1:
		n += days[i]
	return n

# Fête en cours ("" s'il n'y en a pas).
static func current_event() -> String:
	var force := OS.get_environment("LANTERNE_EVENT")
	if force != "":
		return force if EVENTS.has(force) else ""
	if OS.get_environment("LANTERNE_NOEL") == "1":
		return "noel"
	var dt := Time.get_date_dict_from_system()
	var y := int(dt["year"])
	var today := _day_of_year(y, int(dt["month"]), int(dt["day"]))
	for id in EVENTS:
		var ev: Dictionary = EVENTS[id]
		if id == "paques":
			var es := easter(y)
			var ed := _day_of_year(y, es[0], es[1])
			if today >= ed - 7 and today <= ed + 8:      # de la semaine sainte à une semaine après
				return id
			continue
		var a0 := _day_of_year(y, ev["from"][0], ev["from"][1])
		var a1 := _day_of_year(y, ev["to"][0], ev["to"][1])
		if a0 <= a1:
			if today >= a0 and today <= a1:
				return id
		elif today >= a0 or today <= a1:      # fête à cheval sur le Nouvel An
			return id
	return ""

# Musique du Sanctuaire et de l'écran-titre : celle de la fête en cours, sinon la musique habituelle.
static func hub_music() -> String:
	var ev := current_event()
	return String(EVENTS[ev]["music"]) if ev != "" else "res://music/sanctuaire.ogg"

static func is_noel() -> bool:
	return current_event() == "noel"

static func season_on(s: String) -> bool:
	return s == "" or s == current_event()

# Année de la fête en cours (une fête de fin d'année qui déborde sur janvier compte pour l'année d'avant).
static func event_year() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) - (1 if current_event() == "noel" and int(d["month"]) == 1 else 0)

static func noel_year() -> int:
	return event_year()

func gift_open(ev: String) -> bool:
	return int(gifts.get(ev, 0)) == event_year()

func mark_gift(ev: String) -> void:
	gifts[ev] = event_year()
	save()

# ------------------------------------------------------------------ dessin du héros
# Corps du héros (écharpe, cape, jambes, capuche, œil, couvre-chef), dans le repère « pieds en (0,0),
# regard vers +x ». Utilisé par le joueur et par l'aperçu de la garde-robe.
func draw_hero(ci: CanvasItem, bob: float, sway: float, anim_t: float, sitting: bool, moving: bool) -> void:
	var cp := look("cape")
	var sc := look("scarf")
	var tl := look("trail")
	# la cape de base a une luminosité de 0,16 : les capes colorées sont plafonnées à 0,25 pour ne pas éblouir
	var cloak: Color = tone(cp["c"], 0.25)
	var trim: Color = tone(cp["c2"], 0.6)
	# Écharpe qui flotte (deux tons, bout effiloché)
	var scarf := PackedVector2Array([Vector2(-4, -24 + bob), Vector2(-12, -22 + bob + sway * 0.5), Vector2(-20, -24 + bob + sway), Vector2(-26, -20 + bob + sway * 1.4)])
	if sc.get("glow", false):
		ci.draw_polyline(scarf, Color(sc["c"], 0.16), 8.0)
	ci.draw_polyline(scarf, sc["c2"], 4.2)
	ci.draw_polyline(scarf, sc["c"], 2.2)
	for i in 3:
		ci.draw_line(scarf[3], scarf[3] + Vector2(-3 - i, 2.5 + i * 1.5), Color(sc["c"]).darkened(0.12), 1.0)
	if sc.get("lights", false):
		var lc := [Color(1.0, 0.3, 0.3), Color(1.0, 0.85, 0.3), Color(0.4, 0.7, 1.0), Color(1.0, 0.5, 0.9)]
		for i in 4:
			var on := fmod(anim_t * 2.0 + i * 0.5, 2.0) < 1.4
			ci.draw_circle(scarf[i] + Vector2(0, 2), 1.8, Color(lc[i], 1.0 if on else 0.35))
	# Cape : dégradé, doublure et plis
	var cape := PackedVector2Array([
		Vector2(-8, -26 + bob), Vector2(8, -26 + bob), Vector2(12, -3), Vector2(8, 0),
		Vector2(4, -4 + sway * 0.3), Vector2(0, 0), Vector2(-4, -4 - sway * 0.3), Vector2(-8, 0), Vector2(-13, -3)])
	DU.poly(ci, cape, cloak, false)
	DU.flat(ci, PackedVector2Array([Vector2(8, 0), Vector2(4, -4 + sway * 0.3), Vector2(6, -6), Vector2(11, -3.5)]), cloak.lerp(trim, 0.35).darkened(0.25))
	DU.flat(ci, PackedVector2Array([Vector2(-8, 0), Vector2(-4, -4 - sway * 0.3), Vector2(-7, -6), Vector2(-12, -3.5)]), cloak.lerp(trim, 0.25).darkened(0.4))
	for fx in [-4.0, 2.0, 7.0]:
		ci.draw_line(Vector2(fx, -20 + bob), Vector2(fx * 1.25, -5), Color(0, 0, 0, 0.35), 1.0)
	ci.draw_line(Vector2(-7, -25 + bob), Vector2(-11.5, -4), Color(trim, 0.9), 1.0)
	if cp.get("stars", false):
		for i in 6:
			var sp := Vector2(-8.0 + fposmod(i * 7.3, 17.0), -22.0 + fposmod(i * 5.1, 17.0) + bob * 0.5)
			var tw := 0.4 + 0.6 * absf(sin(anim_t * 2.0 + i * 1.7))
			ci.draw_circle(sp, 0.9, Color(1.0, 1.0, 0.9, tw))
	if eq("cape") == "cape_noel":
		ci.draw_polyline(PackedVector2Array([Vector2(12, -3), Vector2(8, 0), Vector2(4, -4 + sway * 0.3), Vector2(0, 0), Vector2(-4, -4 - sway * 0.3), Vector2(-8, 0), Vector2(-13, -3)]), Color(0.97, 0.97, 0.97), 3.0)
	else:
		ci.draw_polyline(PackedVector2Array([Vector2(12, -3), Vector2(8, 0), Vector2(4, -4 + sway * 0.3), Vector2(0, 0), Vector2(-4, -4 - sway * 0.3), Vector2(-8, 0), Vector2(-13, -3)]), Color(0.02, 0.02, 0.04), 1.2)
	# Petites jambes et bottes
	if not sitting:
		var step := sin(anim_t * 16.0) * 3.0 if moving else 0.0
		ci.draw_line(Vector2(-3, -3), Vector2(-3 + step, 0), Color(0.05, 0.04, 0.08), 3.2)
		ci.draw_line(Vector2(3, -3), Vector2(3 - step, 0), Color(0.05, 0.04, 0.08), 3.2)
		ci.draw_line(Vector2(-4.5 + step, 0), Vector2(-1 + step, 0), Color(0.3, 0.22, 0.18), 2.0)
		ci.draw_line(Vector2(1.5 - step, 0), Vector2(5 - step, 0), Color(0.3, 0.22, 0.18), 2.0)
	# Fermoir de la cape
	ci.draw_circle(Vector2(5, -24 + bob), 2.2, Color(0.75, 0.6, 0.3))
	ci.draw_circle(Vector2(4.4, -24.6 + bob), 0.9, Color(1.0, 0.92, 0.6))
	# Capuche pointue (la pointe retombe vers l'arrière)
	var hy := -26.0 + bob
	var hood := PackedVector2Array([
		Vector2(-10, hy + 4), Vector2(11, hy + 4), Vector2(12, hy - 8), Vector2(6, hy - 16),
		Vector2(-4, hy - 18), Vector2(-14, hy - 22 + sway * 0.5), Vector2(-11, hy - 8)])
	DU.poly(ci, hood, cloak.lightened(0.04))
	ci.draw_line(Vector2(-3, hy - 15), Vector2(-12, hy - 19 + sway * 0.5), Color(trim, 0.7), 1.0)
	ci.draw_polyline(PackedVector2Array([Vector2(-1, hy - 13), Vector2(10, hy - 9), Vector2(10.5, hy + 2)]), Color(trim, 0.8), 1.0)
	# Visage : vide sombre et un œil (couleur de la lueur choisie)
	var eye: Color = tl["c"]
	DU.flat(ci, DU.ellipse(Vector2(3, hy - 6), Vector2(6.5, 6.0)), Color(0.0, 0.0, 0.02))
	var blink := 0.3 if fmod(anim_t, 3.7) < 0.12 else 2.6
	ci.draw_circle(Vector2(5, hy - 6), 7.0, Color(eye, 0.14))
	ci.draw_circle(Vector2(5, hy - 6), 4.5, Color(eye, 0.25))
	DU.flat(ci, DU.ellipse(Vector2(5, hy - 6), Vector2(2.4, blink)), eye.lightened(0.15))
	if blink > 1.0:
		ci.draw_circle(Vector2(4.3, hy - 7), 0.8, Color(1, 1, 0.9))
	draw_hat(ci, eq("hat"), hy, sway, anim_t)

# Plafonne la luminosité d'une couleur (les ombrages et la lumière du héros l'éclaircissent déjà beaucoup).
static func tone(c: Color, vmax: float) -> Color:
	var v := maxf(c.r, maxf(c.g, c.b))
	if v <= vmax:
		return c
	var k := vmax / v
	return Color(c.r * k, c.g * k, c.b * k, c.a)

# Couvre-chef, posé sur la capuche (hy = hauteur du bas de la capuche).
func draw_hat(ci: CanvasItem, id: String, hy: float, sway: float, anim_t: float) -> void:
	var top := Vector2(1, hy - 17)
	match id:
		"hat_plume":
			var b := Vector2(-2, hy - 16)
			ci.draw_polyline(PackedVector2Array([b, b + Vector2(-5, -9), b + Vector2(-12, -14 + sway * 0.4)]), Color(0.08, 0.08, 0.12), 3.5)
			ci.draw_polyline(PackedVector2Array([b, b + Vector2(-5, -9), b + Vector2(-12, -14 + sway * 0.4)]), Color(0.3, 0.3, 0.45), 1.0)
		"hat_bougie":
			DU.box(ci, Rect2(top + Vector2(-2.5, -8), Vector2(5, 9)), Color(0.92, 0.9, 0.8))
			var fl := top + Vector2(0, -11 + sin(anim_t * 9.0) * 0.6)
			ci.draw_circle(fl, 7.0, Color(1.0, 0.75, 0.3, 0.18))
			DU.flat(ci, PackedVector2Array([fl + Vector2(-2.2, 2), fl + Vector2(0, -5), fl + Vector2(2.2, 2)]), Color(1.0, 0.8, 0.35))
		"hat_fleurs":
			var cols := [Color(0.95, 0.6, 0.75), Color(1.0, 0.9, 0.5), Color(0.7, 0.8, 1.0), Color(0.95, 0.6, 0.75)]
			for i in 4:
				var p := Vector2(-6.0 + i * 5.0, hy - 13.5 - absf(1.5 - i) * -1.2)
				ci.draw_circle(p, 2.6, cols[i])
				ci.draw_circle(p, 1.0, Color(1.0, 0.95, 0.7))
			ci.draw_line(Vector2(-8, hy - 12), Vector2(11, hy - 9), Color(0.3, 0.55, 0.3), 1.2)
		"hat_couronne":
			var g := Color(0.8, 0.62, 0.22)
			DU.flat(ci, PackedVector2Array([Vector2(-6, hy - 14), Vector2(-6, hy - 22), Vector2(-2.5, hy - 18), Vector2(1, hy - 24), Vector2(4.5, hy - 18), Vector2(8, hy - 22), Vector2(8, hy - 13)]), g)
			ci.draw_line(Vector2(-6, hy - 14), Vector2(8, hy - 13), g.darkened(0.3), 1.5)
			ci.draw_circle(Vector2(1, hy - 18), 1.4, Color(0.9, 0.2, 0.3))
		"hat_aureole":
			var c := top + Vector2(0, -9 + sin(anim_t * 2.0) * 1.0)
			ci.draw_arc(c, 9.0, 0.0, TAU, 20, Color(1.0, 0.9, 0.5, 0.16), 5.0)
			ci.draw_polyline(DU.ellipse(c, Vector2(9, 3.2), 20, 0.0, TAU + 0.3), Color(1.0, 0.95, 0.7), 2.0)
		"hat_cornes":
			var bone := Color(0.85, 0.82, 0.72)
			ci.draw_polyline(PackedVector2Array([Vector2(7, hy - 14), Vector2(12, hy - 20), Vector2(11, hy - 27)]), bone, 3.2)
			ci.draw_polyline(PackedVector2Array([Vector2(-5, hy - 16), Vector2(-9, hy - 23), Vector2(-6, hy - 29)]), bone, 3.2)
			ci.draw_circle(Vector2(11, hy - 27), 1.2, bone.lightened(0.2))
			ci.draw_circle(Vector2(-6, hy - 29), 1.2, bone.lightened(0.2))
		"hat_bonnet":
			var red := Color(0.5, 0.07, 0.07)
			var tip := Vector2(-15, hy - 20 + sway * 0.6)
			DU.flat(ci, PackedVector2Array([Vector2(-9, hy - 9), Vector2(11, hy - 9), Vector2(6, hy - 19), Vector2(-4, hy - 23), tip]), red)
			ci.draw_line(Vector2(-10, hy - 8.5), Vector2(12, hy - 8.5), Color(0.97, 0.97, 0.97), 4.5)
			ci.draw_circle(tip, 3.2, Color(0.97, 0.97, 0.97))
		"hat_citrouille":
			var o := Color(0.5, 0.24, 0.05)
			DU.poly(ci, DU.ellipse(Vector2(1, hy - 15), Vector2(10, 8), 14), o)
			for k in [-5.0, 0.0, 5.0]:
				ci.draw_arc(Vector2(1 + k, hy - 15), 8.0, PI * 0.35, PI * 0.65, 6, o.darkened(0.3), 1.0)
			ci.draw_line(Vector2(1, hy - 23), Vector2(-2, hy - 27), Color(0.25, 0.4, 0.15), 2.4)
			var glow := 0.75 + 0.25 * sin(anim_t * 7.0)
			DU.flat(ci, PackedVector2Array([Vector2(3, hy - 18), Vector2(6, hy - 15.5), Vector2(1.5, hy - 15.5)]), Color(1.0, 0.85, 0.3, glow))
			DU.flat(ci, PackedVector2Array([Vector2(8, hy - 18), Vector2(10, hy - 15.5), Vector2(6.5, hy - 15.5)]), Color(1.0, 0.85, 0.3, glow))
			ci.draw_polyline(PackedVector2Array([Vector2(1, hy - 12.5), Vector2(4, hy - 11), Vector2(6, hy - 12.5), Vector2(8.5, hy - 11), Vector2(10, hy - 12.5)]), Color(1.0, 0.85, 0.3, glow), 1.4)
		"hat_coeurs":
			ci.draw_arc(Vector2(1, hy - 9), 10.5, PI * 1.1, PI * 1.9, 12, Color(0.25, 0.2, 0.3), 1.6)
			for sgn in [-1.0, 1.0]:
				var st := Vector2(1 + sgn * 7.0, hy - 17)
				var hp := st + Vector2(sgn * 2.5, -9 + sin(anim_t * 5.0 + sgn) * 1.2)
				ci.draw_line(st, hp, Color(0.25, 0.2, 0.3), 1.0)
				ci.draw_circle(hp + Vector2(-1.6, 0), 2.1, Color(0.95, 0.35, 0.5))
				ci.draw_circle(hp + Vector2(1.6, 0), 2.1, Color(0.95, 0.35, 0.5))
				DU.flat(ci, PackedVector2Array([hp + Vector2(-3.5, 0.8), hp + Vector2(3.5, 0.8), hp + Vector2(0, 5)]), Color(0.95, 0.35, 0.5))
		"hat_lapin":
			var fur := Color(0.9, 0.88, 0.84)
			for sgn in [-1.0, 1.0]:
				var b3 := Vector2(1 + sgn * 4.5, hy - 16)
				var tip3 := b3 + Vector2(sgn * 3.0 - sway * 0.3, -19 + (3.0 if sgn > 0 else 0.0))
				ci.draw_line(b3, tip3, fur, 5.0)
				ci.draw_circle(tip3, 2.5, fur)
				ci.draw_line(b3 + Vector2(0, -3), tip3 + Vector2(0, 3), Color(0.95, 0.65, 0.72), 2.0)
		"hat_renne":
			var br := Color(0.5, 0.33, 0.18)
			for s in [-1.0, 1.0]:
				var b2 := Vector2(1 + s * 6.0, hy - 15)
				ci.draw_polyline(PackedVector2Array([b2, b2 + Vector2(s * 3, -8), b2 + Vector2(s * 8, -13)]), br, 2.4)
				ci.draw_line(b2 + Vector2(s * 3, -8), b2 + Vector2(s * 0.5, -14), br, 2.0)
				ci.draw_line(b2 + Vector2(s * 5.5, -10.5), b2 + Vector2(s * 9.5, -8.5), br, 1.8)
			ci.draw_circle(Vector2(11.5, hy - 5), 2.0, Color(0.95, 0.2, 0.2))

# Pastille de la garde-robe : petit aperçu d'un cosmétique.
func draw_swatch(ci: CanvasItem, id: String, c: Vector2, r: float) -> void:
	var it := item(id)
	if it.is_empty():
		return
	ci.draw_circle(c, r, Color(0.07, 0.055, 0.045))
	match String(it["cat"]):
		"cape":
			DU.flat(ci, PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.65), c + Vector2(r * 0.5, -r * 0.65), c + Vector2(r * 0.72, r * 0.6), c + Vector2(0, r * 0.4), c + Vector2(-r * 0.72, r * 0.6)]), it["c"])
			ci.draw_line(c + Vector2(-r * 0.5, -r * 0.65), c + Vector2(-r * 0.72, r * 0.6), it["c2"], 1.5)
		"scarf":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, r * 0.2), c + Vector2(-r * 0.1, -r * 0.3), c + Vector2(r * 0.7, r * 0.1)]), it["c2"], 5.0)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, r * 0.2), c + Vector2(-r * 0.1, -r * 0.3), c + Vector2(r * 0.7, r * 0.1)]), it["c"], 2.5)
		"hat":
			if id == "hat_none":
				ci.draw_line(c + Vector2(-r * 0.45, -r * 0.45), c + Vector2(r * 0.45, r * 0.45), Color(0.5, 0.5, 0.6), 2.0)
			else:
				ci.draw_set_transform(c + Vector2(-1, r * 0.2 + 20.0 * r / 16.0), 0.0, Vector2(r / 16.0, r / 16.0))
				draw_hat(ci, id, -4.0, 0.0, 0.0)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"trail":
			for i in 3:
				ci.draw_circle(c + Vector2(-r * 0.5 + i * r * 0.45, 0), r * (0.2 + i * 0.1), Color(it["c2"] if i < 2 else it["c"], 0.5 + i * 0.25))
		"pet":
			if id == "pet_none":
				ci.draw_line(c + Vector2(-r * 0.45, -r * 0.45), c + Vector2(r * 0.45, r * 0.45), Color(0.5, 0.5, 0.6), 2.0)
			else:
				ci.draw_circle(c, r * 0.55, Color(it["c"], 0.25))
				ci.draw_circle(c, r * 0.3, it["c"])
		"ult":
			ci.draw_arc(c, r * 0.65, 0.0, TAU, 20, it["c"], 3.0)
			ci.draw_arc(c, r * 0.35, 0.0, TAU, 14, it["c2"], 2.0)
	ci.draw_arc(c, r, 0.0, TAU, 24, Color(0.85, 0.7, 0.35), 1.5)

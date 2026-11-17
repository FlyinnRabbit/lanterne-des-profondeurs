# Armes de base, à acheter et équiper à l'arsenal du Sanctuaire.
#  w / h  : largeur et hauteur de la zone de coup horizontal (×)
#  v      : portée des coups vers le haut / le bas (×)
#  cd     : temps entre deux coups (×)      dmg : dégâts en plus
#  knock  : recul infligé (×)                stagger : étourdit brièvement l'ennemi
#  ranged : l'arme se lance (projectiles) au lieu de frapper au corps à corps

const ORDER := ["aiguille", "griffes", "fouet", "marteau", "shuriken", "faux", "baton"]

const W := {
	"aiguille": {"name": "Aiguille du Veilleur", "price": 0, "color": Color(0.85, 0.9, 1.0),
		"desc": "Équilibrée : rapide, portée moyenne, rebond sur les ennemis et les pics.",
		"w": 1.0, "h": 1.0, "v": 1.0, "cd": 1.0, "dmg": 0, "knock": 1.0, "stagger": 0.0, "ranged": false},
	"griffes": {"name": "Griffes Jumelles", "price": 180, "color": Color(0.85, 0.6, 1.0),
		"desc": "Une griffe à chaque main, très rapides mais courtes : chaque attaque frappe deux fois (0,6 dégât par griffe, 1 sur un coup puissant).",
		"w": 0.72, "h": 0.95, "v": 0.85, "cd": 0.65, "dmg": 0, "knock": 0.45, "stagger": 0.0, "ranged": false, "soul": 0.6},
	"fouet": {"name": "Fouet de Ronces", "price": 150, "color": Color(0.6, 0.85, 0.45),
		"desc": "Très longue portée devant soi et vers le haut, mais un peu plus lent. Garde les ennemis à distance.",
		"w": 1.9, "h": 0.7, "v": 1.45, "cd": 1.25, "dmg": 0, "knock": 0.7, "stagger": 0.0, "ranged": false},
	"marteau": {"name": "Marteau d'Enclume", "price": 220, "color": Color(1.0, 0.65, 0.35),
		"desc": "Lent et lourd : +1 dégât, gros recul et étourdit brièvement les ennemis touchés.",
		"w": 0.95, "h": 1.35, "v": 1.1, "cd": 1.85, "dmg": 1, "knock": 1.6, "stagger": 0.35, "ranged": false},
	"shuriken": {"name": "Étoiles de Lune", "price": 260, "color": Color(0.75, 0.85, 1.0),
		"desc": "Shurikens lancés à distance. Coup final : 3 étoiles ; tourbillon : 8 étoiles en cercle (une salve ne touche qu'une fois le même ennemi) ; estoc : grande étoile perçante. Pas de rebond.",
		"w": 1.0, "h": 1.0, "v": 1.0, "cd": 1.3, "dmg": 0, "knock": 0.6, "stagger": 0.0, "ranged": true},
	"faux": {"name": "Faux du Glaneur", "price": 240, "color": Color(0.6, 0.95, 0.85),
		"desc": "Grand arc en demi-lune devant et au-dessus de toi, qui fauche plusieurs ennemis à la fois. Plus lente. Le coup final devient un tourbillon tout autour de toi.",
		"w": 1.25, "h": 1.5, "v": 1.25, "cd": 1.35, "dmg": 0, "knock": 0.9, "stagger": 0.0, "ranged": false},
	"baton": {"name": "Bâton Cerclé de Cuivre", "price": 230, "color": Color(0.85, 0.55, 0.32),
		"desc": "Long et rapide : un estoc fin qui porte loin devant et en hauteur. Accroupi, l'attaque devient un saut à la perche qui te propulse en l'air.",
		"w": 1.7, "h": 0.6, "v": 1.5, "cd": 0.95, "dmg": 0, "knock": 1.1, "stagger": 0.0, "ranged": false},
}

# Améliorations (niveau 2), vendues par la forgeronne une fois le palier 1 terminé
const UP := {
	"aiguille": {"price": 200, "desc": "Niv. 2 : le coup final projette une courte lame d'air."},
	"griffes": {"price": 220, "desc": "Niv. 2 : chaque coup de griffe a 20 % de chances de faire saigner (1 dégât une seconde plus tard). Le Croc Sanglant ajoute 30 %."},
	"fouet": {"price": 240, "desc": "Niv. 2 : le fouet attire vers toi les petits ennemis touchés."},
	"marteau": {"price": 260, "desc": "Niv. 2 : le coup final fait jaillir une onde de choc des deux côtés."},
	"shuriken": {"price": 280, "desc": "Niv. 2 : les étoiles reviennent comme un boomerang et touchent à nouveau."},
	"faux": {"price": 260, "desc": "Niv. 2 : chaque ennemi fauché rend de l'âme, et le tourbillon lance une lame fantôme qui revient vers toi."},
	"baton": {"price": 270, "desc": "Niv. 2 : le coup final s'abat en frappe géante et fait courir une onde au sol devant toi."},
}

# ---------------------------------------------------------------- niveaux 3 à 5
# Au-delà du niveau 2 (l'effet spécial), la forgeronne renforce une caractéristique propre à
# chaque arme : dégâts (+1), portée (+12 %), vitesse de frappe (+10 %) ou chance de critique (+8 %).
const MAX_LV := 5
const GROWTH := {
	"aiguille": ["speed", "crit", "dmg"],
	"griffes": ["crit", "speed", "crit"],
	"fouet": ["reach", "speed", "dmg"],
	"marteau": ["dmg", "speed", "reach"],
	"shuriken": ["speed", "crit", "dmg"],
	"faux": ["reach", "dmg", "crit"],
	"baton": ["speed", "reach", "crit"],
}
# palier qu'il faut avoir terminé pour forger chaque niveau
const NEED := {2: 1, 3: 2, 4: 3, 5: 5}
const STAT_NAMES := {"dmg": "+1 dégât", "reach": "+12 % de portée", "speed": "+10 % de vitesse de frappe", "crit": "+8 % de chance de critique"}

static func up_price(id: String, to_lv: int) -> int:
	var base := int(UP.get(id, {"price": 220})["price"])
	return [0, 0, base, roundi(base * 1.5 / 10.0) * 10, base * 2, base * 3][clampi(to_lv, 0, 5)]

# effet du niveau to_lv (2 : effet spécial, 3-5 : caractéristique)
static func level_desc(id: String, to_lv: int) -> String:
	if to_lv == 2:
		return String(UP[id]["desc"])
	return String(STAT_NAMES[GROWTH[id][to_lv - 3]])

# bonus cumulés d'une arme à un niveau donné
static func bonus(id: String, lv: int) -> Dictionary:
	var b := {"dmg": 0, "reach": 0.0, "speed": 0.0, "crit": 0.0}
	for l in range(3, mini(lv, MAX_LV) + 1):
		var k: String = GROWTH.get(id, ["dmg", "dmg", "dmg"])[l - 3]
		match k:
			"dmg": b["dmg"] += 1
			"reach": b["reach"] += 0.12
			"speed": b["speed"] += 0.10
			"crit": b["crit"] += 0.08
	return b

static func get_w(id: String) -> Dictionary:
	return W.get(id, W["aiguille"])

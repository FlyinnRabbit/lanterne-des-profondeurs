# Armes de base, à acheter et équiper à l'arsenal du Sanctuaire.
#  w / h  : largeur et hauteur de la zone de coup horizontal (×)
#  v      : portée des coups vers le haut / le bas (×)
#  cd     : temps entre deux coups (×)      dmg : dégâts en plus
#  knock  : recul infligé (×)                stagger : étourdit brièvement l'ennemi
#  ranged : l'arme se lance (projectiles) au lieu de frapper au corps à corps

const ORDER := ["aiguille", "griffes", "fouet", "marteau", "shuriken"]

const W := {
	"aiguille": {"name": "Aiguille du Veilleur", "price": 0, "color": Color(0.85, 0.9, 1.0),
		"desc": "Équilibrée : rapide, portée moyenne, rebond sur les ennemis et les pics.",
		"w": 1.0, "h": 1.0, "v": 1.0, "cd": 1.0, "dmg": 0, "knock": 1.0, "stagger": 0.0, "ranged": false},
	"griffes": {"name": "Griffes Jumelles", "price": 180, "color": Color(0.85, 0.6, 1.0),
		"desc": "Une griffe à chaque main, très rapides mais courtes : chaque attaque frappe deux fois (0,5 dégât par griffe, 1 sur un coup puissant).",
		"w": 0.72, "h": 0.95, "v": 0.85, "cd": 0.65, "dmg": 0, "knock": 0.45, "stagger": 0.0, "ranged": false, "soul": 0.3},
	"fouet": {"name": "Fouet de Ronces", "price": 150, "color": Color(0.6, 0.85, 0.45),
		"desc": "Très longue portée devant soi et vers le haut, mais un peu plus lent. Garde les ennemis à distance.",
		"w": 1.9, "h": 0.7, "v": 1.45, "cd": 1.25, "dmg": 0, "knock": 0.7, "stagger": 0.0, "ranged": false},
	"marteau": {"name": "Marteau d'Enclume", "price": 220, "color": Color(1.0, 0.65, 0.35),
		"desc": "Lent et lourd : +1 dégât, gros recul et étourdit brièvement les ennemis touchés.",
		"w": 0.95, "h": 1.35, "v": 1.1, "cd": 1.85, "dmg": 1, "knock": 1.6, "stagger": 0.35, "ranged": false},
	"shuriken": {"name": "Étoiles de Lune", "price": 260, "color": Color(0.75, 0.85, 1.0),
		"desc": "Shurikens lancés à distance. Coup final : 3 étoiles ; tourbillon : 8 étoiles en cercle (une salve ne touche qu'une fois le même ennemi) ; estoc : grande étoile perçante. Pas de rebond.",
		"w": 1.0, "h": 1.0, "v": 1.0, "cd": 1.3, "dmg": 0, "knock": 0.6, "stagger": 0.0, "ranged": true},
}

# Améliorations (niveau 2), vendues par la forgeronne une fois le palier 1 terminé
const UP := {
	"aiguille": {"price": 200, "desc": "Niv. 2 : le coup final projette une courte lame d'air."},
	"griffes": {"price": 220, "desc": "Niv. 2 : les griffes font saigner : un ennemi touché perd encore 1 vie une seconde plus tard."},
	"fouet": {"price": 240, "desc": "Niv. 2 : le fouet attire vers toi les petits ennemis touchés."},
	"marteau": {"price": 260, "desc": "Niv. 2 : le coup final fait jaillir une onde de choc des deux côtés."},
	"shuriken": {"price": 280, "desc": "Niv. 2 : les étoiles reviennent comme un boomerang et touchent à nouveau."},
}

static func get_w(id: String) -> Dictionary:
	return W.get(id, W["aiguille"])

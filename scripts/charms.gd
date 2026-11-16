# Les emblèmes (équipement). Sur les cartes, les chiffres 1 à 8 placent l'emblème correspondant.
# Chaque emblème coûte des encoches ; on en a 3 au départ (les « N » sur les cartes en ajoutent).

const LONG_NAIL := 0
const GLASS_HEART := 1
const SWIFT_CLOAK := 2
const THORNS := 3
const MIRROR := 4
const GREED := 5
const QUICK_FOCUS := 6
const BRUTE := 7
const METEOR := 8
const SHADOW_REST := 9
const ECHO := 10
const LIGHT_STEP := 11
const REBOUND := 12
const ANVIL_FALL := 13
const RIPOSTE := 14
const PHANTOM_DASH := 15
const SOUL_HARVEST := 16
const PLUNDERER := 17
const CLIMBER := 18
const LAST_BREATH := 19

const CHARMS := [
	{"name": "Aiguille Longue", "cost": 2, "color": Color(0.75, 0.85, 1.0),
		"desc": "Allonge la portée des coups d'aiguille de 40 %."},
	{"name": "Cœur de Verre", "cost": 2, "color": Color(0.95, 0.6, 0.7),
		"desc": "Ajoute deux fragments de vie."},
	{"name": "Cape Rapide", "cost": 1, "color": Color(0.5, 0.9, 0.85),
		"desc": "Course 12 % plus rapide, la Ruée se recharge deux fois plus vite."},
	{"name": "Coquille Épineuse", "cost": 2, "color": Color(0.55, 0.75, 0.45),
		"desc": "Quand vous êtes touché, des épines blessent les ennemis proches."},
	{"name": "Miroir Parfait", "cost": 1, "color": Color(0.9, 0.95, 1.0),
		"desc": "La fenêtre de parade passe de 0,2 à 0,35 seconde."},
	{"name": "Âme Vorace", "cost": 2, "color": Color(0.8, 0.7, 1.0),
		"desc": "Chaque coup rapporte plus d'âme et charge davantage l'ultime."},
	{"name": "Concentration Vive", "cost": 1, "color": Color(1.0, 0.95, 0.7),
		"desc": "Le soin se fait presque deux fois plus vite."},
	{"name": "Force Brute", "cost": 3, "color": Color(1.0, 0.55, 0.4),
		"desc": "+1 dégât à tous les coups, mais les coups sont 20 % plus lents."},
	{"name": "Météore Ardent", "cost": 2, "color": Color(1.0, 0.7, 0.3),
		"desc": "Une attaque plongée qui touche un ennemi prépare un coup critique."},
	{"name": "Repos de l'Ombre", "cost": 2, "color": Color(0.6, 0.55, 0.9),
		"desc": "Accroupi hors combat, l'âme remonte lentement (jusqu'à 33). Le soin accroupi est 1,5 fois plus rapide."},
	{"name": "Écho Parfait", "cost": 2, "color": Color(0.85, 1.0, 0.95),
		"desc": "Une parade parfaite lance gratuitement une lame d'âme."},
	{"name": "Pas Léger", "cost": 1, "color": Color(0.7, 1.0, 0.6),
		"desc": "Franchir un piège sans être touché rapporte 5 éclats."},
	{"name": "Lame Rebond", "cost": 1, "color": Color(0.6, 0.85, 1.0),
		"desc": "Rebondir sur un ennemi (coup vers le bas, piqué) te propulse 25 % plus haut et rend 6 d'âme."},
	{"name": "Enclume Tombante", "cost": 2, "color": Color(0.75, 0.75, 0.82),
		"desc": "Le piqué inflige 1 dégât de plus et son onde de choc est 50 % plus large."},
	{"name": "Parade Tranchante", "cost": 2, "color": Color(1.0, 0.85, 0.55),
		"desc": "Une parade réussie inflige 2 dégâts à l'attaquant."},
	{"name": "Ruée Spectrale", "cost": 2, "color": Color(0.75, 0.65, 1.0),
		"desc": "La Ruée blesse les ennemis qu'elle traverse (1 dégât)."},
	{"name": "Récolte d'Âme", "cost": 1, "color": Color(0.65, 0.95, 0.9),
		"desc": "Chaque ennemi vaincu rend 8 d'âme."},
	{"name": "Flair du Pilleur", "cost": 1, "color": Color(1.0, 0.8, 0.35),
		"desc": "Les coffres des grottes et les cachettes donnent 60 % d'éclats en plus."},
	{"name": "Nœud de Grimpeur", "cost": 1, "color": Color(0.85, 0.7, 0.5),
		"desc": "Les treuils hissent deux fois plus vite ; la première remontée de chaque treuil rend 33 d'âme."},
	{"name": "Dernier Souffle", "cost": 3, "color": Color(1.0, 0.45, 0.45),
		"desc": "Un coup fatal te laisse à 1 masque au lieu de te vaincre, une fois par niveau."},
]

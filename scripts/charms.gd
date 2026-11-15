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
		"desc": "Les coups d'aiguille infligent le double de dégâts."},
]

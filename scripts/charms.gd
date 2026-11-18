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
const BLOOD_FANG := 20
const SOUL_FLAME := 21
const FRUGAL_LAMP := 22
const MOTH_WING := 23
const TWIN_SHADOW := 24
const STONE_SKIN := 25
const MERCHANT_PURSE := 26
const SAP_CHALICE := 27
const STORM_HEART := 28
const THUNDER_WAVE := 29
const BARK_SOLES := 30
const PENDULUM := 31
const HUNTER_FANG := 32
const FROST_BITE := 33
const HAWK_EYE := 34
const OBSIDIAN_TIP := 35
const SOUL_VEIL := 36
const WOUNDED_RAGE := 37
const COMET := 38
const BLESSED_SAP := 39
const BLADE_DANCE := 40
const BENCH_PRAYER := 41

const CHARMS := [
	{"name": "Aiguille Longue", "cost": 2, "color": Color(0.75, 0.85, 1.0),
		"desc": "Allonge la portée des coups d'aiguille de 40 %.",
		"up": "Niv. 2 / 3 : portée +55 % / +70 %."},
	{"name": "Cœur de Verre", "cost": 2, "color": Color(0.95, 0.6, 0.7),
		"desc": "Ajoute deux fragments de vie.",
		"up": "Niv. 2 / 3 : trois / quatre fragments de vie."},
	{"name": "Cape Rapide", "cost": 1, "color": Color(0.5, 0.9, 0.85),
		"desc": "Course 12 % plus rapide, la Ruée se recharge deux fois plus vite.",
		"up": "Niv. 2 / 3 : course +18 % / +24 %, Ruée encore plus vite rechargée."},
	{"name": "Coquille Épineuse", "cost": 2, "color": Color(0.55, 0.75, 0.45),
		"desc": "Quand vous êtes touché, des épines blessent les ennemis proches.",
		"up": "Niv. 2 / 3 : les épines font 4 / 5 dégâts (3 au niv. 1)."},
	{"name": "Miroir Parfait", "cost": 1, "color": Color(0.9, 0.95, 1.0),
		"desc": "La fenêtre de parade passe de 0,2 à 0,35 seconde.",
		"up": "Niv. 2 / 3 : fenêtre de parade 0,42 / 0,5 seconde."},
	{"name": "Âme Vorace", "cost": 2, "color": Color(0.8, 0.7, 1.0),
		"desc": "Chaque coup rapporte plus d'âme et charge davantage l'ultime.",
		"up": "Niv. 2 / 3 : encore plus d'âme et d'ultime par coup."},
	{"name": "Concentration Vive", "cost": 1, "color": Color(1.0, 0.95, 0.7),
		"desc": "Le soin se fait presque deux fois plus vite.",
		"up": "Niv. 2 / 3 : le soin est plus de deux fois plus rapide."},
	{"name": "Force Brute", "cost": 3, "color": Color(1.0, 0.55, 0.4),
		"desc": "+1 dégât à tous les coups, mais les coups sont 20 % plus lents.",
		"up": "Niv. 2 / 3 : les coups ne sont plus que 12 % / 5 % plus lents."},
	{"name": "Météore Ardent", "cost": 2, "color": Color(1.0, 0.7, 0.3),
		"desc": "Une attaque plongée qui touche un ennemi prépare un coup critique.",
		"up": "Niv. 2 / 3 : le piqué qui touche rend aussi 10 / 20 d'âme."},
	{"name": "Repos de l'Ombre", "cost": 2, "color": Color(0.6, 0.55, 0.9),
		"desc": "Accroupi hors combat, l'âme remonte lentement (jusqu'à 33). Le soin accroupi est 1,5 fois plus rapide.",
		"up": "Niv. 2 / 3 : l'âme remonte jusqu'à 50 / 66, soin accroupi encore plus rapide."},
	{"name": "Écho Parfait", "cost": 2, "color": Color(0.85, 1.0, 0.95),
		"desc": "Une parade parfaite lance gratuitement une lame d'âme.",
		"up": "Niv. 2 / 3 : la lame d'âme fait 4 / 5 dégâts (3 au niv. 1)."},
	{"name": "Pas Léger", "cost": 1, "color": Color(0.7, 1.0, 0.6),
		"desc": "Franchir un piège sans être touché rapporte 5 éclats.",
		"up": "Niv. 2 / 3 : 8 / 12 éclats par piège franchi."},
	{"name": "Lame Rebond", "cost": 1, "color": Color(0.6, 0.85, 1.0),
		"desc": "Rebondir sur un ennemi (coup vers le bas, piqué) te propulse 25 % plus haut et rend 6 d'âme.",
		"up": "Niv. 2 / 3 : rebond +35 % / +45 %, 9 / 12 d'âme."},
	{"name": "Enclume Tombante", "cost": 2, "color": Color(0.75, 0.75, 0.82),
		"desc": "Le piqué inflige 1 dégât de plus et son onde de choc est 50 % plus large.",
		"up": "Niv. 2 / 3 : onde de choc encore plus large ; +2 dégâts au niv. 3."},
	{"name": "Parade Tranchante", "cost": 2, "color": Color(1.0, 0.85, 0.55),
		"desc": "Une parade réussie inflige 2 dégâts à l'attaquant.",
		"up": "Niv. 2 / 3 : 3 / 4 dégâts à l'attaquant."},
	{"name": "Ruée Spectrale", "cost": 2, "color": Color(0.75, 0.65, 1.0),
		"desc": "La Ruée blesse les ennemis qu'elle traverse (1 dégât).",
		"up": "Niv. 2 / 3 : 2 / 3 dégâts aux ennemis traversés."},
	{"name": "Récolte d'Âme", "cost": 1, "color": Color(0.65, 0.95, 0.9),
		"desc": "Chaque ennemi vaincu rend 8 d'âme.",
		"up": "Niv. 2 / 3 : 12 / 16 d'âme par ennemi vaincu."},
	{"name": "Flair du Pilleur", "cost": 1, "color": Color(1.0, 0.8, 0.35),
		"desc": "Les coffres des grottes et les cachettes donnent 60 % d'éclats en plus.",
		"up": "Niv. 2 / 3 : +90 % / +120 % d'éclats dans les cachettes."},
	{"name": "Nœud de Grimpeur", "cost": 1, "color": Color(0.85, 0.7, 0.5),
		"desc": "Les treuils hissent deux fois plus vite ; la première remontée de chaque treuil rend 33 d'âme.",
		"up": "Niv. 2 / 3 : la première remontée rend 45 / 60 d'âme."},
	{"name": "Dernier Souffle", "cost": 3, "color": Color(1.0, 0.45, 0.45),
		"desc": "Un coup fatal te laisse à 1 masque au lieu de te vaincre, une fois par niveau.",
		"up": "Niv. 2 / 3 : te laisse à 2 / 3 masques."},
	{"name": "Croc Sanglant", "cost": 2, "color": Color(0.9, 0.3, 0.38),
		"desc": "+30 % de chances de faire saigner à chaque coup, avec toutes les armes (1 dégât une seconde plus tard). Avec les Griffes niv. 2 : 50 %.",
		"up": "Niv. 2 / 3 : +40 % / +50 % de chances de saignée."},
	{"name": "Âme Ardente", "cost": 2, "color": Color(0.55, 0.85, 1.0),
		"desc": "La lame d'âme (sort) inflige 1 dégât de plus.",
		"up": "Niv. 2 / 3 : +2 dégâts ; au niv. 3 le sort ne coûte plus que 28 d'âme."},
	{"name": "Lanterne Frugale", "cost": 1, "color": Color(1.0, 0.85, 0.5),
		"desc": "Le soin ne coûte que 27 d'âme au lieu de 33.",
		"up": "Niv. 2 / 3 : le soin coûte 24 / 20 d'âme."},
	{"name": "Aile de Phalène", "cost": 3, "color": Color(0.85, 0.8, 0.65),
		"desc": "Permet un second saut en l'air, un peu moins haut que le premier.",
		"up": "Niv. 2 / 3 : le second saut est plus haut (90 % / 100 %)."},
	{"name": "Ombre Jumelle", "cost": 2, "color": Color(0.5, 0.45, 0.75),
		"desc": "Deux Ruées en l'air au lieu d'une avant de toucher le sol.",
		"up": "Niv. 2 / 3 : la Ruée porte 10 % / 20 % plus loin."},
	{"name": "Peau de Pierre", "cost": 2, "color": Color(0.65, 0.65, 0.6),
		"desc": "Après un coup reçu, l'invulnérabilité dure 40 % plus longtemps.",
		"up": "Niv. 2 / 3 : +60 % / +80 % d'invulnérabilité."},
	{"name": "Bourse du Marchand", "cost": 1, "color": Color(0.95, 0.75, 0.3),
		"desc": "Les ennemis vaincus lâchent 20 % d'éclats en plus.",
		"up": "Niv. 2 / 3 : +30 % / +40 % d'éclats."},
	{"name": "Calice de Sève", "cost": 3, "color": Color(0.7, 0.9, 0.4),
		"desc": "Tous les 15 ennemis vaincus, rend un masque.",
		"up": "Niv. 2 / 3 : un masque tous les 12 / 10 ennemis vaincus."},
	{"name": "Cœur d'Orage", "cost": 2, "color": Color(0.6, 0.75, 1.0),
		"desc": "L'ultime se charge 25 % plus vite (coups et parades).",
		"up": "Niv. 2 / 3 : l'ultime se charge 35 % / 45 % plus vite."},
	{"name": "Onde Tonnerre", "cost": 2, "color": Color(0.8, 0.85, 1.0),
		"desc": "L'onde de l'ultime est 30 % plus large.",
		"up": "Niv. 2 / 3 : +45 % / +60 % de rayon ; +1 dégât au niv. 3."},
	{"name": "Semelles d'Écorce", "cost": 1, "color": Color(0.6, 0.45, 0.3),
		"desc": "Le premier coup de piège de chaque niveau est ignoré.",
		"up": "Niv. 2 / 3 : les 2 / 3 premiers coups de piège sont ignorés."},
	{"name": "Pendule", "cost": 1, "color": Color(0.85, 0.95, 0.8),
		"desc": "Une parade réussie recharge aussitôt la Ruée et rend 5 d'âme de plus.",
		"up": "Niv. 2 / 3 : 8 / 12 d'âme de plus par parade."},
	{"name": "Croc du Chasseur", "cost": 2, "color": Color(0.9, 0.55, 0.45),
		"desc": "+1 dégât contre les ennemis sous 40 % de leur vie.",
		"up": "Niv. 2 / 3 : sous 50 % / 60 % de leur vie."},
	{"name": "Givre Mordant", "cost": 2, "color": Color(0.7, 0.92, 1.0),
		"desc": "15 % de chances par coup de geler brièvement l'ennemi (0,6 s, pas les boss).",
		"up": "Niv. 2 / 3 : 20 % / 25 % de chances."},
	{"name": "Œil du Faucon", "cost": 2, "color": Color(1.0, 0.9, 0.45),
		"desc": "+8 % de chances de coup critique.",
		"up": "Niv. 2 / 3 : +12 % / +16 % de chances de critique."},
	{"name": "Pointe d'Obsidienne", "cost": 2, "color": Color(0.55, 0.4, 0.6),
		"desc": "Les coups critiques infligent ×2 au lieu de ×1,5.",
		"up": "Niv. 2 / 3 : critiques ×2,25 / ×2,5."},
	{"name": "Voile d'Âme", "cost": 3, "color": Color(0.75, 0.85, 0.95),
		"desc": "Avec 33 d'âme, un coup reçu est absorbé par l'âme au lieu des masques (une fois toutes les 8 s).",
		"up": "Niv. 2 / 3 : une fois toutes les 6 / 5 s, pour 28 / 22 d'âme."},
	{"name": "Rage du Blessé", "cost": 2, "color": Color(0.95, 0.35, 0.3),
		"desc": "À 1 masque, +1 dégât à tous les coups.",
		"up": "Niv. 2 / 3 : actif à 2 / 3 masques ou moins."},
	{"name": "Comète", "cost": 1, "color": Color(0.9, 0.9, 1.0),
		"desc": "Le coup chargé (tourbillon) se prépare 40 % plus vite.",
		"up": "Niv. 2 / 3 : 50 % / 60 % plus vite."},
	{"name": "Sève Bénie", "cost": 2, "color": Color(0.55, 0.95, 0.6),
		"desc": "Chaque soin a 25 % de chances de rendre un masque de plus.",
		"up": "Niv. 2 / 3 : 35 % / 50 % de chances."},
	{"name": "Danse des Lames", "cost": 2, "color": Color(0.95, 0.75, 0.85),
		"desc": "Le coup final du combo inflige +1 dégât et rend 4 d'âme.",
		"up": "Niv. 2 / 3 : rend 6 / 8 d'âme ; +2 dégâts au niv. 3."},
	{"name": "Prière du Banc", "cost": 1, "color": Color(0.95, 0.9, 0.7),
		"desc": "S'asseoir sur un banc remplit l'âme jusqu'à 33.",
		"up": "Niv. 2 / 3 : jusqu'à 66 / 99 d'âme."},
]

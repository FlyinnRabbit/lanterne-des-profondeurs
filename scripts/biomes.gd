# Les 9 biomes. Chaque partie en tire 5 au hasard, dans un ordre aléatoire,
# et chaque niveau est reconstruit à partir de « salles » assemblées (voir levelgen.gd).
#  chunks  : poids des types de salles (définit la forme du biome)
#  enemies : poids c = rampant, f = volant, s = cracheur
#  extras  : ennemis mis en avant (b bulbe explosif, w tisseuse, l lancier, r spectre)
#  pal     : couleurs (fond, parallaxe, roche, mousse, pics, lumière ambiante, poussière)

const M := "res://music/"

static func C(r: float, g: float, b: float, a := 1.0) -> Color:
	return Color(r, g, b, a)

static func all() -> Array:
	var arr := _all()
	for b in arr:
		b["pal"]["id"] = b["id"]
	return arr

static func _all() -> Array:
	return [
		{"id": "profondeurs", "extras": {"w": 1.0}, "name": "Les Profondeurs",
			"music": [M + "profondeurs_puits_d_ombre.ogg", M + "profondeurs_lanternes_eteintes.ogg"],
			"chunks": {"flat": 3, "platforms": 3, "pit": 2, "hill": 2, "well": 1, "islands": 2, "split": 2},
			"enemies": {"c": 3, "f": 2, "s": 0},
			"pal": {"bg": C(0.025, 0.035, 0.07), "far": C(0.05, 0.07, 0.13), "mid": C(0.07, 0.09, 0.17), "near": C(0.06, 0.07, 0.12),
				"rock": C(0.085, 0.095, 0.14), "rock_hi": C(0.14, 0.16, 0.23), "moss": C(0.42, 0.55, 0.68), "spike": C(0.72, 0.76, 0.86),
				"ambient": C(0.55, 0.6, 0.78), "dust": C(0.7, 0.85, 1.0, 0.55), "dust_dir": Vector2(0.3, -1), "light": C(1.0, 0.85, 0.6)}},
		{"id": "jardins", "extras": {"w": 2.0}, "name": "Les Jardins Fongiques",
			"music": [M + "jardins_spores_flottantes.ogg", M + "jardins_mycelium.ogg"],
			"chunks": {"wall": 3, "platforms": 3, "well": 2, "hill": 1, "pit": 1, "zigzag": 3, "cave": 2},
			"enemies": {"c": 2, "f": 1, "s": 3},
			"pal": {"bg": C(0.02, 0.05, 0.04), "far": C(0.04, 0.09, 0.07), "mid": C(0.06, 0.12, 0.09), "near": C(0.05, 0.1, 0.07),
				"rock": C(0.07, 0.11, 0.09), "rock_hi": C(0.12, 0.19, 0.14), "moss": C(0.45, 0.75, 0.45), "spike": C(0.75, 0.85, 0.6),
				"ambient": C(0.55, 0.72, 0.6), "dust": C(0.7, 1.0, 0.6, 0.5), "dust_dir": Vector2(0.1, -1), "light": C(0.85, 1.0, 0.7)}},
		{"id": "citadelle", "extras": {"l": 2.0, "r": 1.0}, "name": "La Citadelle Engloutie",
			"music": [M + "citadelle_nef_engloutie.ogg", M + "citadelle_cloches_sous_l_eau.ogg"],
			"chunks": {"pillars": 3, "arena": 2, "bridge": 2, "platforms": 1, "flat": 1, "blades": 3, "crumble": 2},
			"enemies": {"c": 1, "f": 2, "s": 2},
			"pal": {"bg": C(0.04, 0.03, 0.07), "far": C(0.08, 0.06, 0.13), "mid": C(0.11, 0.08, 0.17), "near": C(0.09, 0.07, 0.14),
				"rock": C(0.12, 0.1, 0.17), "rock_hi": C(0.22, 0.19, 0.3), "moss": C(0.85, 0.75, 0.45), "spike": C(0.85, 0.8, 0.6),
				"ambient": C(0.62, 0.55, 0.75), "dust": C(1.0, 0.9, 0.6, 0.45), "dust_dir": Vector2(0.0, -1), "light": C(1.0, 0.85, 0.6)}},
		{"id": "cristal", "extras": {"r": 2.0}, "name": "Les Mines de Cristal",
			"music": [M + "cristal_echos_de_quartz.ogg", M + "profondeurs_lanternes_eteintes.ogg"],
			"chunks": {"wide_gap": 3, "corridor": 2, "platforms": 2, "pit": 1, "moving": 3, "islands": 2},
			"enemies": {"c": 1, "f": 3, "s": 1},
			"pal": {"bg": C(0.01, 0.04, 0.06), "far": C(0.03, 0.1, 0.13), "mid": C(0.04, 0.14, 0.18), "near": C(0.03, 0.1, 0.13),
				"rock": C(0.06, 0.1, 0.13), "rock_hi": C(0.2, 0.45, 0.55), "moss": C(0.5, 0.95, 1.0), "spike": C(0.6, 0.95, 1.0),
				"ambient": C(0.5, 0.7, 0.8), "dust": C(0.6, 1.0, 1.0, 0.6), "dust_dir": Vector2(0.0, -1), "light": C(0.7, 0.95, 1.0)}},
		{"id": "forge", "extras": {"b": 2.5}, "name": "La Forge Ardente",
			"music": [M + "forge_enclume_ardente.ogg"],
			"chunks": {"pillars": 3, "pit": 3, "bridge": 2, "arena": 1, "crumble": 3, "split": 2},
			"enemies": {"c": 4, "f": 1, "s": 1},
			"pal": {"bg": C(0.07, 0.02, 0.01), "far": C(0.14, 0.05, 0.03), "mid": C(0.2, 0.07, 0.03), "near": C(0.14, 0.05, 0.03),
				"rock": C(0.12, 0.06, 0.05), "rock_hi": C(0.3, 0.12, 0.06), "moss": C(1.0, 0.5, 0.15), "spike": C(1.0, 0.6, 0.3),
				"ambient": C(0.8, 0.55, 0.45), "dust": C(1.0, 0.6, 0.2, 0.75), "dust_dir": Vector2(0.2, -1), "light": C(1.0, 0.7, 0.4)}},
		{"id": "bibliotheque", "extras": {"r": 2.5}, "name": "La Bibliothèque Silencieuse",
			"music": [M + "bibliotheque_pages_muettes.ogg"],
			"chunks": {"wall": 3, "platforms": 4, "corridor": 1, "flat": 1, "zigzag": 3, "moving": 2},
			"enemies": {"c": 1, "f": 4, "s": 1},
			"pal": {"bg": C(0.05, 0.035, 0.02), "far": C(0.1, 0.07, 0.04), "mid": C(0.14, 0.1, 0.06), "near": C(0.1, 0.07, 0.04),
				"rock": C(0.13, 0.09, 0.06), "rock_hi": C(0.28, 0.2, 0.12), "moss": C(0.85, 0.7, 0.4), "spike": C(0.8, 0.75, 0.6),
				"ambient": C(0.75, 0.65, 0.5), "dust": C(1.0, 0.9, 0.7, 0.4), "dust_dir": Vector2(0.5, 0.3), "light": C(1.0, 0.85, 0.55)}},
		{"id": "glace", "extras": {"l": 1.5}, "name": "Les Abysses Gelés",
			"music": [M + "glace_souffle_givre.ogg"],
			"chunks": {"wide_gap": 3, "bridge": 3, "flat": 1, "hill": 1, "islands": 3, "blades": 2},
			"enemies": {"c": 2, "f": 1, "s": 3},
			"pal": {"bg": C(0.06, 0.08, 0.11), "far": C(0.15, 0.19, 0.25), "mid": C(0.2, 0.25, 0.32), "near": C(0.16, 0.2, 0.26),
				"rock": C(0.18, 0.22, 0.3), "rock_hi": C(0.55, 0.65, 0.78), "moss": C(0.9, 0.95, 1.0), "spike": C(0.85, 0.95, 1.0),
				"ambient": C(0.75, 0.82, 0.92), "dust": C(1.0, 1.0, 1.0, 0.85), "dust_dir": Vector2(0.25, 1), "light": C(0.85, 0.92, 1.0)}},
		{"id": "ruche", "extras": {"b": 1.5}, "name": "La Ruche Bourdonnante",
			"music": [M + "ruche_bourdonnement.ogg"],
			"chunks": {"corridor": 4, "arena": 2, "platforms": 1, "flat": 1, "cave": 3, "blades": 2},
			"enemies": {"c": 0, "f": 5, "s": 1},
			"pal": {"bg": C(0.06, 0.04, 0.0), "far": C(0.14, 0.1, 0.02), "mid": C(0.2, 0.14, 0.03), "near": C(0.15, 0.1, 0.02),
				"rock": C(0.16, 0.11, 0.03), "rock_hi": C(0.4, 0.28, 0.06), "moss": C(1.0, 0.8, 0.2), "spike": C(1.0, 0.85, 0.4),
				"ambient": C(0.8, 0.7, 0.45), "dust": C(1.0, 0.85, 0.3, 0.6), "dust_dir": Vector2(1, -0.2), "light": C(1.0, 0.85, 0.4)}},
		{"id": "ossuaire", "extras": {"l": 2.0, "w": 1.0}, "name": "L'Ossuaire",
			"music": [M + "ossuaire_requiem.ogg"],
			"chunks": {"hill": 3, "arena": 3, "pit": 2, "well": 1, "crumble": 2, "split": 2, "cave": 2},
			"enemies": {"c": 3, "f": 1, "s": 3},
			"pal": {"bg": C(0.04, 0.04, 0.04), "far": C(0.09, 0.09, 0.08), "mid": C(0.13, 0.12, 0.11), "near": C(0.1, 0.1, 0.09),
				"rock": C(0.14, 0.13, 0.12), "rock_hi": C(0.35, 0.33, 0.3), "moss": C(0.8, 0.78, 0.7), "spike": C(0.9, 0.88, 0.8),
				"ambient": C(0.62, 0.6, 0.58), "dust": C(0.9, 0.9, 0.85, 0.4), "dust_dir": Vector2(0.0, 1), "light": C(0.95, 0.9, 0.8)}},
	]

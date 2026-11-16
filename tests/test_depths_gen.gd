extends SceneTree
# Génère des centaines de niveaux : chaque treuil (« ~ ») a son arrivée (« u ») au-dessus,
# chaque niveau a un départ, une sortie (ou un sanctuaire), et chaque grotte a son coffre.
func _initialize() -> void:
	var Biomes = load("res://scripts/biomes.gd")
	var LevelGen = load("res://scripts/levelgen.gd")
	var bad := 0
	var n := 0
	var stats := {}
	for b in Biomes.all():
		for sd in 30:
			for depth in [1, 3, 6, 9]:
				var gen = LevelGen.new()
				var boss := "K" if depth >= 3 else ""
				var m: Array = gen.generate(b, sd * 131 + depth, depth, boss, depth == 9, {"count": 1.3, "variety": 2.0})
				n += 1
				var lows := []
				var tops := []
				var has := {"P": 0, "O": 0, "E": 0, "$": 0, "M": 0}
				for y in m.size():
					var row: String = m[y]
					if row.length() != m[0].length():
						bad += 1
						print("ligne de longueur différente ", b["id"], " ", sd)
					for x in row.length():
						var c := row[x]
						if c == "~":
							lows.append(Vector2i(x, y))
						elif c == "u":
							tops.append(Vector2i(x, y))
						elif has.has(c):
							has[c] += 1
				for lo in lows:
					var found := false
					for tp in tops:
						if tp.y < lo.y and absi(tp.x - lo.x) <= 8:
							found = true
					if not found:
						bad += 1
						print("treuil sans arrivée : ", b["id"], " graine ", sd, " prof ", depth, " ", lo)
				if has["P"] != 1 or (has["O"] + has["E"]) != 1:
					bad += 1
					print("départ/sortie : ", b["id"], " ", sd, " ", has)
				var key: String = b["id"]
				if not stats.has(key):
					stats[key] = [0, 0, 0, 0]
				stats[key][0] += 1
				stats[key][1] += lows.size()
				stats[key][2] += has["$"]
				stats[key][3] += has["M"]
	for k in stats:
		var s: Array = stats[k]
		print("%-13s treuils/niveau %.1f  coffres %.1f  marchands %.2f" % [k, float(s[1]) / s[0], float(s[2]) / s[0], float(s[3]) / s[0]])
	print("niveaux : %d, problèmes : %d" % [n, bad])
	print("RÉSULTAT : ", "OK" if bad == 0 else "ÉCHEC")
	quit()

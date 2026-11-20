extends SceneTree
# Classement / code Discord : la requête de secours en IPv4 (HTTPClient) répond comme HTTPRequest.
# Nécessite le serveur local : node server/dev_server.mjs 8797
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var lb = Node.new()
	lb.set_script(load("res://scripts/leaderboard.gd"))
	root.add_child(lb)
	await process_frame
	var res := []
	lb._http_v4("http://localhost:8797/top?seed=1&diff=1", HTTPClient.METHOD_GET, "", func(ok, code, text): res.append([ok, code, text]), "R13")
	for i in 300:
		await process_frame
		if not res.is_empty():
			break
	print("IPv4 : ", res)
	var ok: bool = not res.is_empty() and res[0][1] == 200 and String(res[0][2]).begins_with("{")
	# repli automatique : un port fermé (connexion refusée) passe par l'IPv4 puis échoue proprement
	var res2 := []
	lb._http("http://127.0.0.1:1/top", HTTPClient.METHOD_GET, "", func(ok2, code, text): res2.append([ok2, code]))
	for i in 1500:
		await process_frame
		if not res2.is_empty():
			break
	print("port fermé : ", res2, " ; diagnostic : ", lb.last_net)
	ok = ok and not res2.is_empty() and not res2[0][0]
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends Node
# Classement en ligne de la Descente du jour (serveur : dossier server/, Cloudflare Worker + D1).
# L'adresse du serveur est lue dans leaderboard.url sur GitHub (écrite par le workflow de
# déploiement) ; LANTERNE_LEADERBOARD_URL la remplace pour les tests.
# Envoyé : la graine du jour, la difficulté, le temps, un pseudo et un identifiant aléatoire
# propre à l'installation (rien d'autre). Sans réseau, rien ne se passe.

const VersionScript = preload("res://scripts/version.gd")
const URL_SOURCE := "https://raw.githubusercontent.com/FlyinnRabbit/lanterne-des-profondeurs/main/leaderboard.url"
# Adresse de secours si GitHub est injoignable (certains réseaux bloquent raw.githubusercontent.com)
const FALLBACK := "https://lanterne-classement.blindtest42.workers.dev"
const HEADERS := ["User-Agent: LanterneDesProfondeurs", "Content-Type: application/json"]

var endpoint := ""          # adresse du Worker, une fois connue
var last := {}              # dernière réponse (top 10 + rang), pour l'affichage
var _waiting := []          # appels en attente de l'adresse
var _resolving := false
var last_net := ""          # dernier échec réseau (« R5 » : résultat HTTPRequest, « H500 » : code HTTP), pour le diagnostic

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var env := OS.get_environment("LANTERNE_LEADERBOARD_URL")
	if env != "":
		endpoint = env.strip_edges().trim_suffix("/")

static func enabled() -> bool:
	return bool(Settings.board_online)

# Identifiant de l'installation (32 caractères hexadécimaux, créé au premier usage).
static func player_id() -> String:
	var id := String(Settings.player_id)
	if id.length() < 16:
		var c := Crypto.new()
		id = c.generate_random_bytes(16).hex_encode()
		Settings.set_value("player_id", id)
	return id

# Pseudo : celui choisi par le joueur, sinon « Veilleur-XXXX ».
static func player_name() -> String:
	var n := String(Settings.player_name).strip_edges()
	if n.length() >= 2:
		return n
	return "Veilleur-" + player_id().substr(0, 4).to_upper()

func _http(url: String, method: int, body: String, cb: Callable) -> void:
	var h := HTTPRequest.new()
	h.timeout = 10.0
	add_child(h)
	h.request_completed.connect(func(result: int, code: int, _hd: PackedStringArray, data: PackedByteArray):
		h.queue_free()
		# connexion impossible ou sans réponse : souvent une IPv6 cassée sur le PC (le navigateur,
		# lui, repasse tout seul en IPv4). On réessaie une fois en forçant l'IPv4.
		if result in [HTTPRequest.RESULT_TIMEOUT, HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CONNECTION_ERROR,
				HTTPRequest.RESULT_NO_RESPONSE, HTTPRequest.RESULT_CANT_RESOLVE]:
			_http_v4(url, method, body, cb, "R%d" % result)
			return
		if result != HTTPRequest.RESULT_SUCCESS:
			last_net = "R%d" % result
		elif code != 200:
			last_net = "H%d" % code
		cb.call(result == HTTPRequest.RESULT_SUCCESS, code, data.get_string_from_utf8()))
	var err := h.request(url, PackedStringArray(HEADERS), method, body)
	if err != OK:
		last_net = "E%d" % err
		h.queue_free()
		cb.call(false, 0, "")

# Même requête, mais vers l'adresse IPv4 du serveur (le certificat et le nom envoyés au serveur
# restent ceux du vrai nom d'hôte). first : code du premier échec, gardé pour le diagnostic.
func _http_v4(url: String, method: int, body: String, cb: Callable, first: String) -> void:
	var tls := url.begins_with("https://")
	var rest := url.substr(8 if tls else 7)
	var slash := rest.find("/")
	var hostport := rest if slash < 0 else rest.substr(0, slash)
	var path := "/" if slash < 0 else rest.substr(slash)
	var host := hostport
	var port := 443 if tls else 80
	if hostport.contains(":"):
		host = hostport.get_slice(":", 0)
		port = int(hostport.get_slice(":", 1))
	var ip := host if host.is_valid_ip_address() else IP.resolve_hostname(host, IP.TYPE_IPV4)
	if ip == "":
		last_net = first + "/v4R3"
		cb.call(false, 0, "")
		return
	var c := HTTPClient.new()
	var err := c.connect_to_host(ip, port, TLSOptions.client(null, host) if tls else null)
	if err != OK:
		last_net = first + "/v4E%d" % err
		cb.call(false, 0, "")
		return
	var t0 := Time.get_ticks_msec()
	var timed_out := func() -> bool: return Time.get_ticks_msec() - t0 > 12000
	while c.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		c.poll()
		if timed_out.call():
			break
		await get_tree().process_frame
	if c.get_status() != HTTPClient.STATUS_CONNECTED:
		last_net = first + "/v4S%d" % c.get_status()
		cb.call(false, 0, "")
		return
	var hd := PackedStringArray(HEADERS)
	hd.append("Host: " + host)
	err = c.request(method, path, hd, body)
	if err != OK:
		last_net = first + "/v4E%d" % err
		cb.call(false, 0, "")
		return
	while c.get_status() == HTTPClient.STATUS_REQUESTING:
		c.poll()
		if timed_out.call():
			break
		await get_tree().process_frame
	if not c.get_status() in [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]:
		last_net = first + "/v4S%d" % c.get_status()
		cb.call(false, 0, "")
		return
	var data := PackedByteArray()
	while c.get_status() == HTTPClient.STATUS_BODY:
		c.poll()
		var chunk := c.read_response_body_chunk()
		if chunk.size() > 0:
			data.append_array(chunk)
		elif timed_out.call():
			break
		else:
			await get_tree().process_frame
	var code := c.get_response_code()
	c.close()
	if code != 200:
		last_net = first + "/v4H%d" % code
	else:
		last_net = ""
	cb.call(code > 0, code, data.get_string_from_utf8())

# Trouve l'adresse du serveur puis lance fn ; fail si elle est introuvable (hors ligne).
func _with_endpoint(fn: Callable, fail: Callable) -> void:
	if endpoint != "":
		fn.call()
		return
	_waiting.append([fn, fail])
	if _resolving:
		return
	_resolving = true
	_http(URL_SOURCE + "?t=%d" % Time.get_unix_time_from_system(), HTTPClient.METHOD_GET, "", func(ok: bool, code: int, text: String):
		_resolving = false
		var u := text.strip_edges()
		var found := ok and code == 200 and u.begins_with("https://")
		endpoint = u.trim_suffix("/") if found else FALLBACK
		found = true
		var w := _waiting.duplicate()
		_waiting.clear()
		for pair in w:
			if found:
				pair[0].call()
			elif pair[1].is_valid():
				pair[1].call())

func _parse(ok: bool, code: int, text: String) -> Dictionary:
	if not ok or code != 200:
		return {"error": "offline" if not ok or code == 0 else "http_%d" % code}
	var d = JSON.parse_string(text)
	return d if d is Dictionary else {"error": "bad_json"}

# Envoie un temps (fin de Descente du jour) ; cb(réponse) avec top 10 et rang.
func submit(seed: int, diff: int, time: float, cb: Callable = Callable(), ghost: String = "") -> void:
	if not enabled():
		return
	var payload := {"seed": seed, "diff": diff, "time": snappedf(time, 0.01), "player_id": player_id(),
		"name": player_name(), "version": VersionScript.VERSION}
	if ghost != "":
		payload["ghost"] = ghost
	var body := JSON.stringify(payload)
	var done := func(d: Dictionary):
		if not d.has("error"):
			last = d
		if cb.is_valid():
			cb.call(d)
	_with_endpoint(func():
		_http(endpoint + "/score", HTTPClient.METHOD_POST, body, func(ok: bool, code: int, text: String):
			done.call(_parse(ok, code, text))),
		func(): done.call({"error": "offline"}))

# Fantôme du premier du classement (jour ou semaine) ; cb({name, time, data}) ou {none}/{error}.
func fetch_ghost(seed: int, diff: int, cb: Callable) -> void:
	_with_endpoint(func():
		_http(endpoint + "/ghost?seed=%d&diff=%d" % [seed, diff], HTTPClient.METHOD_GET, "", func(ok: bool, code: int, text: String):
			cb.call(_parse(ok, code, text))),
		func(): cb.call({"error": "offline"}))

# Lit le classement d'un jour et d'une difficulté.
func fetch_top(seed: int, diff: int, cb: Callable) -> void:
	_with_endpoint(func():
		_http(endpoint + "/top?seed=%d&diff=%d&player_id=%s" % [seed, diff, player_id()], HTTPClient.METHOD_GET, "", func(ok: bool, code: int, text: String):
			var d := _parse(ok, code, text)
			if not d.has("error"):
				last = d
			cb.call(d)),
		func(): cb.call({"error": "offline"}))

extends Node
# Classement en ligne de la Descente du jour (serveur : dossier server/, Cloudflare Worker + D1).
# L'adresse du serveur est lue dans leaderboard.url sur GitHub (écrite par le workflow de
# déploiement) ; LANTERNE_LEADERBOARD_URL la remplace pour les tests.
# Envoyé : la graine du jour, la difficulté, le temps, un pseudo et un identifiant aléatoire
# propre à l'installation (rien d'autre). Sans réseau, rien ne se passe.

const VersionScript = preload("res://scripts/version.gd")
const URL_SOURCE := "https://raw.githubusercontent.com/FlyinnRabbit/lanterne-des-profondeurs/main/leaderboard.url"
const HEADERS := ["User-Agent: LanterneDesProfondeurs", "Content-Type: application/json"]

var endpoint := ""          # adresse du Worker, une fois connue
var last := {}              # dernière réponse (top 10 + rang), pour l'affichage
var _waiting := []          # appels en attente de l'adresse
var _resolving := false

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
	h.timeout = 12.0
	add_child(h)
	h.request_completed.connect(func(result: int, code: int, _hd: PackedStringArray, data: PackedByteArray):
		h.queue_free()
		cb.call(result == HTTPRequest.RESULT_SUCCESS, code, data.get_string_from_utf8()))
	if h.request(url, PackedStringArray(HEADERS), method, body) != OK:
		h.queue_free()
		cb.call(false, 0, "")

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
		if found:
			endpoint = u.trim_suffix("/")
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

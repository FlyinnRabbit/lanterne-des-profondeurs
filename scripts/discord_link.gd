extends "res://scripts/leaderboard.gd"
# Serveur Discord de la communauté et familier « Tube néon ».
#   join()        : ouvre l'invitation (l'adresse n'est jamais affichée dans le jeu).
#   redeem(code)  : vérifie le code du jour auprès du Worker du classement. Ce code est posté
#                   chaque jour dans un salon du serveur par un webhook (voir server/worker.js) :
#                   seuls les membres le voient. Code valable → le familier « Tube néon » est donné.

signal link_changed(status: String)   # checking | ok | bad_code | not_configured | offline | too_many

const INVITE := "https://discord.gg/gkzvFv9tpc"
const PET := "pet_neon"

var status := ""
var _busy := false

func join() -> void:
	OS.shell_open(INVITE)

func has_pet() -> bool:
	return GameState.cos.has(PET)

static func clean(code: String) -> String:
	var c := ""
	for ch in code.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			c += ch
	return c

func redeem(code: String) -> void:
	var c := clean(code)
	if c.length() != 8:
		_status("bad_code")
		return
	if _busy:
		return
	_busy = true
	_status("checking")
	_with_endpoint(func(): _check(c), func():
		_busy = false
		_status("offline"))

func _check(c: String) -> void:
	_http(endpoint + "/discord/code?code=" + c, HTTPClient.METHOD_GET, "", func(ok: bool, code: int, text: String):
		_busy = false
		if code == 429:
			_status("too_many")
			return
		on_answer(_parse(ok, code, text)))

# Réponse du Worker (séparée pour les tests)
func on_answer(d: Dictionary) -> void:
	if d.get("ok", false):
		if GameState.cos.grant(PET):
			GameState.cos.equip(PET)
		_status("ok")
	elif String(d.get("error", "")) == "not_configured":
		_status("not_configured")
	elif d.has("error"):
		_status("offline")
	else:
		_status("bad_code")

func _status(s: String) -> void:
	status = s
	link_changed.emit(s)

extends Node
# Pont vers Steam, pour la version Steam uniquement (scripts/edition.gd : STEAM).
# Le module GodotSteam (GDExtension) est ajouté par le workflow « Export Steam » ; sans lui (dépôt,
# versions GitHub, navigateur), ce nœud ne fait rien.
# - Succès : chaque succès du jeu débloque le succès Steam « ACH_<ID> » (voir docs/steam/achievements.md).
#   Au démarrage, ceux déjà obtenus sont renvoyés (parties commencées avant la version Steam).
# - Sauvegardes : par le « Steam Auto-Cloud », réglé dans Steamworks (aucun code).

const Edition = preload("res://scripts/edition.gd")

var steam: Object = null
var active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Edition.steam() or not Engine.has_singleton("Steam"):
		return
	steam = Engine.get_singleton("Steam")
	var r = steam.call("steamInitEx")
	var status := -1
	if r is Dictionary:
		status = int(r.get("status", -1))
	elif r is bool:
		status = 0 if r else -1
	active = status == 0
	print("[steam] initialisation : ", r)
	if not active:
		return
	var ach = get_node_or_null("/root/Achievements")
	if ach:
		ach.unlocked.connect(_on_achievement)
		for id in ach.done:
			_unlock_on_steam(String(id))
		_store()

func _process(_delta: float) -> void:
	if active:
		steam.call("run_callbacks")

static func api_name(id: String) -> String:
	return "ACH_" + id.to_upper()

func _on_achievement(id: String) -> void:
	_unlock_on_steam(id)
	_store()

func _unlock_on_steam(id: String) -> void:
	if active and steam.has_method("setAchievement"):
		steam.call("setAchievement", api_name(id))

func _store() -> void:
	if active and steam.has_method("storeStats"):
		steam.call("storeStats")

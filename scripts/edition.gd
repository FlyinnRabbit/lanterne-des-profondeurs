extends RefCounted
# Édition du jeu. Le dépôt contient la version complète ; le workflow d'export réécrit ces
# constantes (sed) avant d'exporter la démo et les versions Steam (voir .github/workflows).

const DEMO := false              # démo : tutoriel + paliers 1 à DEMO_MAX_PALIER
const STEAM := false             # version Steam : succès Steam, pas de mise à jour automatique
const DEMO_MAX_PALIER := 2
# Le jeu complet gratuit « continue sur Steam » : dernière version gratuite, sans mise à jour
# automatique, avec un lien vers la page Steam sur l'écran-titre (voir docs/steam/bascule.md).
const STEAM_MOVE := false

# Identifiant Steam du jeu complet (pas de la démo), à remplir une fois l'app créée dans Steamworks.
const STEAM_APP_ID := 0
# Page itch.io de la démo : lien du bouton « Le jeu complet » tant que la page Steam n'existe pas.
const FALLBACK_URL := "https://flyinrabbit.itch.io/lantern-of-the-depths-demo"

# La démo peut aussi être forcée par l'environnement (tests) ; l'inverse est impossible.
static func demo() -> bool:
	return DEMO or OS.get_environment("LANTERNE_EDITION") == "demo"

static func steam() -> bool:
	return STEAM

# L'écran-titre propose la page Steam (démo, ou jeu complet gratuit après la bascule).
static func show_store_link() -> bool:
	return (demo() or STEAM_MOVE) and not STEAM

static func store_label() -> String:
	return "Lanterne des Profondeurs sur Steam" if STEAM_APP_ID > 0 else "Le jeu complet"

static func store_url() -> String:
	if STEAM_APP_ID > 0:
		return "https://store.steampowered.com/app/%d/" % STEAM_APP_ID
	return FALLBACK_URL

# Ouvre la page du jeu complet : par l'overlay Steam si possible, sinon dans le navigateur.
static func open_store() -> void:
	if STEAM_APP_ID > 0 and Engine.has_singleton("Steam"):
		var s = Engine.get_singleton("Steam")
		if s.has_method("activateGameOverlayToStore"):
			s.activateGameOverlayToStore(STEAM_APP_ID)
			return
	OS.shell_open(store_url())

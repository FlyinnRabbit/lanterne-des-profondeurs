extends Node
# Autoload « Lang » : langues du jeu. Le texte source (msgid) est le français ;
# les traductions viennent de translations.gd (généré par tools/translations.py).
# Les textes fixes des menus (Label, Button…) sont traduits automatiquement par Godot ;
# les textes composés passent par tr() au moment où ils sont affichés.

const Tr = preload("res://scripts/translations.gd")
# index 0 = automatique (langue du système)
const CODES := ["", "fr", "en", "es", "de"]
const NAMES := ["Automatique", "Français", "English", "Español", "Deutsch"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for code in Tr.T:
		var t := Translation.new()
		t.locale = code
		var d: Dictionary = Tr.T[code]
		for k in d:
			t.add_message(k, d[k])
		TranslationServer.add_translation(t)
	apply()
	Settings.changed.connect(apply)

func current() -> String:
	var i := clampi(int(Settings.language), 0, CODES.size() - 1)
	if i > 0:
		return CODES[i]
	var sys := OS.get_locale_language()
	return sys if sys in CODES else "en"

func apply() -> void:
	var c := current()
	if TranslationServer.get_locale() != c:
		TranslationServer.set_locale(c)

# Traduction utilisable depuis une fonction statique ou une ressource
static func t(s: String) -> String:
	return String(TranslationServer.translate(s))

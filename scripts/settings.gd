extends Node
# Autoload « Settings » : options d'affichage et de confort, sauvegardées dans settings.cfg (voir paths.gd).

signal changed

const Paths = preload("res://scripts/paths.gd")
const SAVE_NAME := "settings.cfg"   # voir paths.gd (mode portable)

var hud_scale := 1.0       # 0.6 – 1.6
var menu_scale := 1.0      # 0.6 – 1.3
var shake := 1.0           # 0 – 1.5
var zoom := 1.25           # 0.9 – 1.8
var fullscreen := false
var vsync := true
var hitstop := true
var show_hints := true
var master_volume := 0.9
var music_volume := 0.7
var sfx_volume := 0.8
var fps_cap := 1           # index dans FPS_CHOICES
var show_fps := false
var pad_style := 0         # 0 automatique, 1 Xbox, 2 PlayStation
var enemy_bars := true     # barres de vie au-dessus des ennemis
var damage_numbers := true # dégâts infligés dans le coin de l'écran
var language := 0          # index dans Lang.CODES (0 = langue du système)
var minimap := true        # mini-carte en haut à droite
var telegraphs := true     # « ! » au-dessus des ennemis qui préparent un coup
var colorblind := false    # dangers en couleurs très contrastées (blanc / magenta)
var crouch_toggle := false # appuyer sur bas pour s'accroupir / se relever
var game_speed := 0        # index dans SPEED_CHOICES
var menu_anim := true      # écran titre animé (lanterne qui se balance, menu qui glisse)
var title_scene := 3       # décor de l'écran titre : 0 Sanctuaire réel, 1 troglodyte, 2 pilotis, 3 Sanctuaire isométrique
var last_slot := 1         # dernier emplacement de sauvegarde utilisé
var auto_update := true  # télécharger les mises à jour au lancement (voir updater.gd)
var player_name := ""      # pseudo affiché au classement de la Descente du jour
var player_id := ""        # identifiant aléatoire de l'installation (classement)
var board_online := true   # envoyer ses temps au classement en ligne
# 0 haute, 1 équilibrée, 2 basse (voir main.apply_quality) ; équilibrée par défaut sur Mac et navigateur
var gfx_quality := 1 if (OS.has_feature("macos") or OS.has_feature("web")) else 0
var kb_layout := 0         # disposition du clavier pour les noms de touches (voir controls.gd)

const SPEED_CHOICES := [1.0, 0.9, 0.8, 0.7]
const SPEED_LABELS := ["100 %", "90 %", "80 %", "70 %"]
const GFX_LABELS := ["Haute", "Équilibrée", "Basse"]

func speed() -> float:
	return SPEED_CHOICES[clampi(game_speed, 0, SPEED_CHOICES.size() - 1)]

const FPS_CHOICES := [30, 60, 120, 144, 165, 240, 0]   # 0 = illimité
const FPS_LABELS := ["30", "60", "120", "144", "165", "240", "Illimité"]
const PAD_STYLE_LABELS := ["Automatique", "Xbox (XInput)", "PlayStation"]

# Steam Deck : Steam définit la variable d'environnement SteamDeck=1
static func is_steam_deck() -> bool:
	return OS.get_environment("SteamDeck") == "1" or OS.get_processor_name().contains("AMD Custom APU")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_steam_deck() and not FileAccess.file_exists(Paths.file(SAVE_NAME)):
		fullscreen = true      # premier lancement sur le Deck : plein écran, 60 FPS
		pad_style = 1          # les boutons du Deck sont A/B/X/Y
	load_settings()
	apply_display()

func set_value(key: String, value) -> void:
	set(key, value)
	if key in ["fullscreen", "vsync", "fps_cap"]:
		apply_display()
	if key == "game_speed" and Engine.time_scale > 0.5:
		Engine.time_scale = speed()
	save_settings()
	changed.emit()

func apply_display() -> void:
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)
	if not OS.has_feature("web"):   # le navigateur gère lui-même la synchronisation
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	# Plafond d'images par seconde (0 = illimité ; avec la VSync, l'écran limite aussi)
	Engine.max_fps = FPS_CHOICES[clampi(fps_cap, 0, FPS_CHOICES.size() - 1)]

func _input(event: InputEvent) -> void:
	# F11 : plein écran rapide
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		set_value("fullscreen", not fullscreen)

func reset_defaults() -> void:
	hud_scale = 1.0
	menu_scale = 1.0
	shake = 1.0
	zoom = 1.25
	fullscreen = false
	vsync = true
	hitstop = true
	show_hints = true
	master_volume = 0.9
	music_volume = 0.7
	sfx_volume = 0.8
	fps_cap = 1
	show_fps = false
	pad_style = 0
	enemy_bars = true
	damage_numbers = true
	minimap = true
	telegraphs = true
	colorblind = false
	crouch_toggle = false
	game_speed = 0
	menu_anim = true
	Engine.time_scale = speed()
	apply_display()
	save_settings()
	changed.emit()

const KEYS := ["hud_scale", "menu_scale", "shake", "zoom", "fullscreen", "vsync", "hitstop", "show_hints",
	"master_volume", "music_volume", "sfx_volume", "fps_cap", "show_fps", "pad_style", "enemy_bars", "damage_numbers", "language",
	"minimap", "telegraphs", "colorblind", "crouch_toggle", "game_speed", "last_slot", "kb_layout", "auto_update", "player_name", "player_id", "board_online", "gfx_quality", "menu_anim", "title_scene"]

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in KEYS:
		cfg.set_value("options", k, get(k))
	cfg.save(Paths.file(SAVE_NAME))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) != OK:
		return
	for k in KEYS:
		if cfg.has_section_key("options", k):
			set(k, cfg.get_value("options", k))

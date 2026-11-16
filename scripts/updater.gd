extends Node
# Autoload « Updater » (le PREMIER de la liste) : mise à jour automatique du jeu.
#
# 1. Au démarrage (_init, avant que les autres scripts soient chargés) : si un patch a été
#    téléchargé (dossier « update »), il est chargé par-dessus le jeu d'origine.
# 2. Ensuite : on demande à GitHub la dernière Release. Si elle est plus récente :
#    - un patch compatible existe -> il est téléchargé, puis appliqué au prochain lancement ;
#    - sinon (ou mises à jour automatiques coupées) -> simple avis avec lien de téléchargement.
#
# Ce script ne doit dépendre d'AUCUN autre script du jeu (ni preload, ni autre autoload dans
# son code) : il tourne avant eux, c'est ce qui permet au patch de les remplacer.
#
# Sécurité : si le jeu ne démarre pas correctement avec un patch, le patch est retiré au
# lancement suivant et cette version n'est plus retéléchargée.

signal changed

const REPO := "FlyinnRabbit/lanterne-des-profondeurs"
const API_URL := "https://api.github.com/repos/" + REPO + "/releases/latest"
const DOWNLOAD_PREFIX := "https://github.com/" + REPO + "/releases/download/"
const PAGE_URL := "https://github.com/" + REPO + "/releases/latest"

# idle : rien ; checking ; uptodate ; downloading ; ready (patch prêt, redémarrer) ;
# available (nouvelle version, à télécharger à la main) ; error
var state := "idle"
var base_version := ""      # version de l'exécutable (figée à l'export)
var version := ""           # version en cours (exécutable + patch éventuel)
var latest := ""            # dernière version publiée
var page_url := PAGE_URL
var patched := false        # un patch est chargé
var progress := 0.0
var _http: HTTPRequest
var _asset_size := 0
var _bad := ""              # version de patch qui a échoué au démarrage

static func enabled() -> bool:
	return not OS.has_feature("web") and (not OS.has_feature("editor") or OS.get_environment("LANTERNE_UPDATE_TEST") != "")

# Dossier des fichiers de mise à jour (à côté des sauvegardes ; mode portable compris).
static func dir() -> String:
	var base := OS.get_executable_path().get_base_dir()
	if not OS.has_feature("editor") and FileAccess.file_exists(base.path_join("portable.txt")):
		return base.path_join("sauvegardes").path_join("update")
	return OS.get_user_data_dir().path_join("update")

# Nom du patch attendu : dépend de la version du moteur et de la « génération » des données
# (musiques, sons, images : non inclus dans le patch). Si l'un des deux change, les anciennes
# installations ne trouvent pas de patch et affichent l'avis de téléchargement.
static func patch_name() -> String:
	var e := Engine.get_version_info()
	return "LanterneDesProfondeurs_patch_g%d.%d_d%d.pck" % [int(e["major"]), int(e["minor"]), int(ProjectSettings.get_setting("application/config/data_gen", 1))]

static func newer(a: String, b: String) -> bool:   # a > b ?
	var pa := a.trim_prefix("v").split(".")
	var pb := b.trim_prefix("v").split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y:
			return x > y
	return false

func _init() -> void:
	base_version = String(ProjectSettings.get_setting("application/config/version", "0"))
	if enabled():
		_load_patch()
	var vs = load("res://scripts/version.gd")
	version = String(vs.VERSION) if vs else base_version
	if enabled():
		print("[maj] version %s (exécutable %s%s)" % [version, base_version, ", patch chargé" if patched else ""])

func _load_patch() -> void:
	var d := dir()
	var cfg := ConfigFile.new()
	if cfg.load(d.path_join("patch.cfg")) != OK:
		return
	_bad = String(cfg.get_value("patch", "bad", ""))
	var pv := String(cfg.get_value("patch", "version", ""))
	var file := String(cfg.get_value("patch", "file", "")).get_file()
	_clean(file)
	var pck := d.path_join(file)
	if pv == "" or file == "" or not FileAccess.file_exists(pck):
		return
	# patch dépassé (jeu retéléchargé en entier), prévu pour un autre moteur, ou démarrage raté
	var stale := not newer(pv, base_version) or String(cfg.get_value("patch", "name", "")) != patch_name()
	var crashed := FileAccess.file_exists(d.path_join("booting"))
	if stale or crashed:
		if crashed:
			_bad = pv
		_remove_patch()
		return
	var f := FileAccess.open(d.path_join("booting"), FileAccess.WRITE)
	if f:
		f.close()
	if ProjectSettings.load_resource_pack(pck, true):
		patched = true
	else:
		_remove_patch()

# Supprime les anciens fichiers de patch (tout sauf « keep »).
func _clean(keep: String) -> void:
	var d := dir()
	for n in DirAccess.get_files_at(d):
		if (n.ends_with(".pck") or n.ends_with(".tmp")) and n != keep:
			DirAccess.remove_absolute(d.path_join(n))

func _remove_patch() -> void:
	var d := dir()
	_clean("")
	if FileAccess.file_exists(d.path_join("booting")):
		DirAccess.remove_absolute(d.path_join("booting"))
	var cfg := ConfigFile.new()
	cfg.set_value("patch", "bad", _bad)
	cfg.save(d.path_join("patch.cfg"))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not enabled():
		return
	changed.connect(func():
		if state != "downloading" or progress == 0.0:
			print("[maj] %s%s" % [state, (" -> " + latest) if latest != "" else ""]))
	# le jeu a démarré correctement : le patch est validé au bout de quelques secondes
	get_tree().create_timer(6.0, true, false, true).timeout.connect(func():
		var b := dir().path_join("booting")
		if FileAccess.file_exists(b):
			DirAccess.remove_absolute(b))
	check.call_deferred()

# Fermeture normale du jeu (même très tôt) : ce n'est pas un démarrage raté.
func _exit_tree() -> void:
	if enabled():
		var b := dir().path_join("booting")
		if FileAccess.file_exists(b):
			DirAccess.remove_absolute(b)

func _auto() -> bool:
	var s = get_node_or_null("/root/Settings")
	return s == null or s.get("auto_update") != false

func check() -> void:
	if not enabled() or state in ["checking", "downloading", "ready"]:
		return
	state = "checking"
	changed.emit()
	_request(_api_url(), "", _on_info)

func _api_url() -> String:
	var t := OS.get_environment("LANTERNE_UPDATE_TEST")   # tests : serveur local
	return t if t != "" else API_URL

func _request(url: String, file: String, cb: Callable) -> void:
	if _http:
		_http.queue_free()
	_http = HTTPRequest.new()
	_http.timeout = 20.0 if file == "" else 180.0
	_http.download_file = file
	add_child(_http)
	_http.request_completed.connect(cb)
	if _http.request(url, PackedStringArray(["User-Agent: LanterneDesProfondeurs", "Accept: application/vnd.github+json"])) != OK:
		_fail()

func _fail() -> void:
	state = "available" if latest != "" and newer(latest, version) else "error"
	changed.emit()

func _on_info(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail()
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary) or not data.has("tag_name"):
		_fail()
		return
	latest = String(data["tag_name"]).trim_prefix("v")
	if String(data.get("html_url", "")).begins_with("https://github.com/" + REPO):
		page_url = String(data["html_url"])
	if not newer(latest, version):
		state = "uptodate"
		changed.emit()
		return
	state = "available"
	var want := patch_name()
	if _auto() and latest != _bad:
		for a in data.get("assets", []):
			if a is Dictionary and String(a.get("name", "")) == want:
				var url := String(a.get("browser_download_url", ""))
				if url.begins_with(DOWNLOAD_PREFIX) or OS.get_environment("LANTERNE_UPDATE_TEST") != "":
					_asset_size = int(a.get("size", 0))
					_download(url)
					return
	changed.emit()

func _download(url: String) -> void:
	var d := dir()
	DirAccess.make_dir_recursive_absolute(d)
	state = "downloading"
	progress = 0.0
	changed.emit()
	_request(url, d.path_join("download.tmp"), _on_patch)

func _process(_delta: float) -> void:
	if state == "downloading" and _http and _asset_size > 0:
		var p := clampf(float(_http.get_downloaded_bytes()) / _asset_size, 0.0, 1.0)
		if absf(p - progress) > 0.02:
			progress = p
			changed.emit()

func _on_patch(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var d := dir()
	var tmp := d.path_join("download.tmp")
	var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(tmp)
	if ok:
		var f := FileAccess.open(tmp, FileAccess.READ)
		# taille annoncée par GitHub + en-tête d'un fichier .pck (« GDPC »)
		ok = f != null and f.get_length() > 16 and (_asset_size <= 0 or int(f.get_length()) == _asset_size) and f.get_buffer(4).get_string_from_ascii() == "GDPC"
		if f:
			f.close()
	if not ok:
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)
		_fail()
		return
	# nom propre à la version : le patch en cours d'utilisation n'est pas touché (verrouillé sous Windows)
	var file := "patch_%s.pck" % latest.validate_filename()
	var pck := d.path_join(file)
	if FileAccess.file_exists(pck):
		DirAccess.remove_absolute(pck)
	if DirAccess.rename_absolute(tmp, pck) != OK:
		_fail()
		return
	var cfg := ConfigFile.new()
	cfg.set_value("patch", "version", latest)
	cfg.set_value("patch", "file", file)
	cfg.set_value("patch", "name", patch_name())
	cfg.set_value("patch", "bad", _bad)
	cfg.save(d.path_join("patch.cfg"))
	state = "ready"
	changed.emit()

# Redémarre le jeu pour appliquer le patch téléchargé.
func restart() -> void:
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()

func open_page() -> void:
	OS.shell_open(page_url)

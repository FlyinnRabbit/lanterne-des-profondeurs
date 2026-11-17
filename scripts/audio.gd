extends Node
# Autoload « Audio » : musique (playlists par niveau avec fondus, thème de boss) et bruitages.
# Bus créés au démarrage : Master > Music, Master > SFX. Volumes réglés dans Options.

const FADE := 1.5
const SFX_NAMES := ["slash", "hit", "hurt", "parry", "dash", "jump", "ult", "pickup", "heal", "spit", "kill", "door",
	"whip", "hammer", "star", "star_hit", "crit", "crit_ready", "achievement", "soul_level", "soul_full"]

var players: Array[AudioStreamPlayer] = []
var active := 0
var playlist: Array = []
var index := 0
var boss_mode := false
var current_path := ""
var sfx_streams := {}
var sfx_pool: Array[AudioStreamPlayer] = []
var duck := 0.0   # atténuation en pause (dB)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		p.finished.connect(_on_finished.bind(i))
		add_child(p)
		players.append(p)
	for i in 10:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		sfx_pool.append(s)
	for n in SFX_NAMES:
		var path := "res://sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			sfx_streams[n] = load(path)
	Settings.changed.connect(apply_volumes)
	apply_volumes()

func apply_volumes() -> void:
	_set_bus("Master", Settings.master_volume)
	_set_bus("Music", Settings.music_volume)
	_set_bus("SFX", Settings.sfx_volume)

func _set_bus(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)

# ---------------------------------------------------------------- musique
func play_playlist(paths: Array, shuffle := true) -> void:
	boss_mode = false
	playlist = paths.duplicate()
	if shuffle:
		playlist.shuffle()
	index = 0
	if playlist.is_empty():
		stop_music()
		return
	# Si le morceau en cours fait partie de la nouvelle playlist, on le laisse continuer
	if current_path in playlist and players[active].playing:
		index = playlist.find(current_path)
		return
	_crossfade(playlist[0], playlist.size() == 1)

func play_boss(path: String) -> void:
	boss_mode = true
	_crossfade(path, true)

func resume_level() -> void:
	boss_mode = false
	if not playlist.is_empty():
		index = (index + 1) % playlist.size()
		_crossfade(playlist[index], playlist.size() == 1)

func stop_music() -> void:
	for p in players:
		create_tween().tween_property(p, "volume_db", -80.0, FADE)
	current_path = ""

func _crossfade(path: String, loop: bool) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Musique introuvable : " + path)
		return
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		stream.loop = loop
	var old := players[active]
	active = 1 - active
	var p := players[active]
	p.stream = stream
	p.volume_db = -40.0
	p.play()
	current_path = path
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "volume_db", duck, FADE)
	if old.playing:
		tw.tween_property(old, "volume_db", -80.0, FADE)
		tw.chain().tween_callback(old.stop)

func _on_finished(i: int) -> void:
	# fin d'un morceau de la playlist : on enchaîne le suivant (la playlist boucle)
	if i != active or boss_mode or playlist.is_empty():
		return
	index = (index + 1) % playlist.size()
	_crossfade(playlist[index], playlist.size() == 1)

func _process(_delta: float) -> void:
	# musique un peu plus basse quand le jeu est en pause
	var target := -8.0 if get_tree().paused else 0.0
	if not is_equal_approx(target, duck):
		duck = move_toward(duck, target, 0.5)
		var p := players[active]
		if p.playing and p.volume_db > -30.0:
			p.volume_db = duck

# ---------------------------------------------------------------- bruitages
func sfx(name: String, pitch_var := 0.08, vol_db := 0.0) -> void:
	if not sfx_streams.has(name):
		return
	for s in sfx_pool:
		if not s.playing:
			s.stream = sfx_streams[name]
			s.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			s.volume_db = vol_db
			s.play()
			return

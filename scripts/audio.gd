extends Node
# Autoload « Audio » : musique (playlists par niveau avec fondus, thème de boss) et bruitages.
# Bus créés au démarrage : Master > Music, Master > SFX. Volumes réglés dans Options.

const FADE := 1.5
var _fade_tw: Tween
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
# ambiance du biome (boucle discrète sous la musique) et bruits de pas
const AMB_DB := -15.0
var amb: AudioStreamPlayer
var amb_id := ""
var _amb_tw: Tween
var step_streams := {}   # matière -> [variantes]

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
	amb = AudioStreamPlayer.new()
	amb.bus = "SFX"
	amb.volume_db = -80.0
	add_child(amb)
	for m in ["stone", "grass", "snow", "sand", "wood", "crystal", "soft"]:
		step_streams[m] = []
		for k in 3:
			var sp := "res://sfx/step_%s%d.wav" % [m, k]
			if ResourceLoader.exists(sp):
				step_streams[m].append(load(sp))
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
		var st = players[active].stream
		if st is AudioStreamOggVorbis:
			st.loop = playlist.size() == 1      # devenu seul : il boucle sans blanc
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
	if _fade_tw and _fade_tw.is_valid():
		_fade_tw.kill()
	for p in players:
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -80.0, FADE)
		tw.tween_callback(p.stop)
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
	p.volume_db = -80.0
	p.play()
	current_path = path
	# fondu à puissance constante (en amplitude, pas en dB) : pas de creux au milieu
	var from_old := db_to_linear(old.volume_db - duck) if old.playing else 0.0
	if _fade_tw and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = create_tween()
	_fade_tw.tween_method(func(t: float):
		p.volume_db = linear_to_db(maxf(sqrt(t), 0.0001)) + duck
		if old.playing:
			old.volume_db = linear_to_db(maxf(sqrt(1.0 - t) * from_old, 0.0001)) + duck, 0.0, 1.0, FADE)
	_fade_tw.tween_callback(func():
		if old != players[active]:
			old.stop())

# Fin proche d'un morceau de la playlist : le suivant commence en fondu AVANT la fin, sans blanc.
func _next_in_playlist() -> void:
	index = (index + 1) % playlist.size()
	_crossfade(playlist[index], playlist.size() == 1)

func _on_finished(i: int) -> void:
	# fin d'un morceau de la playlist : on enchaîne le suivant (la playlist boucle)
	if i != active or boss_mode or playlist.is_empty():
		return
	_next_in_playlist()

func _process(_delta: float) -> void:
	var cur := players[active]
	if not boss_mode and playlist.size() > 1 and cur.playing and cur.stream:
		var left: float = cur.stream.get_length() - cur.get_playback_position()
		if left > 0.0 and left < FADE:
			_next_in_playlist()
	# musique un peu plus basse quand le jeu est en pause
	var target := -8.0 if get_tree().paused else 0.0
	if not is_equal_approx(target, duck):
		duck = move_toward(duck, target, 0.5)
		var p := players[active]
		if p.playing and p.volume_db > -30.0:
			p.volume_db = duck

# ---------------------------------------------------------------- ambiance et pas
func play_ambience(id: String) -> void:
	if id == amb_id and amb.playing:
		return
	amb_id = id
	var path := "res://sfx/amb_%s.ogg" % id
	if _amb_tw and _amb_tw.is_valid():
		_amb_tw.kill()
	if not ResourceLoader.exists(path):
		stop_ambience()
		return
	var st = load(path).duplicate()
	if st is AudioStreamOggVorbis:
		st.loop = true
	amb.stream = st
	amb.volume_db = -50.0
	amb.play(randf() * 10.0)
	_amb_tw = create_tween()
	_amb_tw.tween_property(amb, "volume_db", AMB_DB, 2.5)

func stop_ambience() -> void:
	amb_id = ""
	if _amb_tw and _amb_tw.is_valid():
		_amb_tw.kill()
	_amb_tw = create_tween()
	_amb_tw.tween_property(amb, "volume_db", -60.0, 1.2)
	_amb_tw.tween_callback(amb.stop)

func step(material: String, vol_db := -17.0) -> void:
	var arr: Array = step_streams.get(material, [])
	if arr.is_empty():
		return
	for s in sfx_pool:
		if not s.playing:
			s.stream = arr[randi() % arr.size()]
			s.pitch_scale = randf_range(0.9, 1.1)
			s.volume_db = vol_db
			s.play()
			return

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

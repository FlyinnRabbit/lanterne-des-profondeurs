extends SceneTree
# Les 21 nouveaux emblèmes (21 à 41) : chaque effet s'applique bien
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
var gs
var C
func _eq(ids: Array, lv := 1) -> void:
	gs.prog["owned"] = ids.duplicate()
	gs.prog["equipped"] = ids.duplicate()
	var d := {}
	for i in ids:
		d[str(i)] = lv
	gs.prog["charm_lv"] = d
func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	C = load("res://scripts/charms.gd")
	var ok := true
	var fails := []
	if gs.charm_count() != 42:
		fails.append("count %d" % gs.charm_count())
	# coûts et textes
	for i in range(21, 42):
		var ch: Dictionary = C.CHARMS[i]
		if not ch.has("up") or int(ch["cost"]) < 1:
			fails.append("data %d" % i)
	# 21 Âme Ardente
	_eq([C.SOUL_FLAME], 3)
	if pl.spell_cost() != 28: fails.append("soul flame cost")
	_eq([])
	if pl.spell_cost() != 33: fails.append("spell cost base")
	# 22 Lanterne Frugale
	_eq([C.FRUGAL_LAMP], 2)
	if pl.focus_cost() != 24: fails.append("frugal")
	# 25 Peau de Pierre
	_eq([C.STONE_SKIN], 1)
	pl.hp = 5
	pl.invuln_t = 0.0
	pl.take_damage(1, pl.global_position.x - 10)
	if absf(pl.invuln_t - pl.INVULN_TIME * 1.4) > 0.01: fails.append("stone %f" % pl.invuln_t)
	pl.hp = pl.max_hp
	# 28 Cœur d'Orage
	_eq([])
	var u0: int = pl.ult_per_hit()
	_eq([C.STORM_HEART], 3)
	if pl.ult_per_hit() <= u0: fails.append("storm")
	# 34 / 35 critiques
	_eq([C.OBSIDIAN_TIP], 1)
	if pl.crit_damage(4) != 8: fails.append("obsidian %d" % pl.crit_damage(4))
	_eq([])
	if pl.crit_damage(4) != 6: fails.append("crit base")
	# 37 Rage du Blessé
	_eq([C.WOUNDED_RAGE], 2)
	pl.hp = 2
	if pl.nail_damage() != 2: fails.append("rage on")
	pl.hp = 3
	if pl.nail_damage() != 1: fails.append("rage off")
	pl.hp = pl.max_hp
	# 38 Comète
	_eq([C.COMET], 1)
	if absf(pl.charge_time() - pl.CHARGE_TIME * 0.6) > 0.001: fails.append("comet")
	# 32 Croc du Chasseur
	_eq([C.HUNTER_FANG], 1)
	var foe = CharacterBody2D.new()
	foe.set_script(load("res://scripts/dummy.gd"))
	foe.hp = 1
	foe.hp_max = 10
	if pl.foe_bonus(foe) != 1: fails.append("hunter low")
	foe.hp = 9
	if pl.foe_bonus(foe) != 0: fails.append("hunter high")
	foe.free()
	# 41 Prière du Banc
	_eq([C.BENCH_PRAYER], 2)
	pl.soul = 0
	pl.sit(pl.global_position, true)
	if pl.soul != 66: fails.append("bench %d" % pl.soul)
	pl.sitting = false
	# 36 Voile d'Âme
	_eq([C.SOUL_VEIL], 1)
	pl.hp = pl.max_hp
	pl.soul = 40
	pl.invuln_t = 0.0
	pl.veil_cd = 0.0
	pl.receive_hit(pl.global_position + Vector2(30, 0), null)
	if pl.hp != pl.max_hp or pl.soul != 7: fails.append("veil hp %d soul %d" % [pl.hp, pl.soul])
	pl.invuln_t = 0.0
	pl.soul = 40
	pl.receive_hit(pl.global_position + Vector2(30, 0), null)
	if pl.hp != pl.max_hp - 1: fails.append("veil cd")
	pl.hp = pl.max_hp
	pl.invuln_t = 0.0
	# 27 Calice de Sève
	_eq([C.SAP_CHALICE], 3)
	pl.hp = pl.max_hp - 1
	pl.sap_kills = 0
	for i in 10:
		pl.on_kill_charms()
	if pl.hp != pl.max_hp: fails.append("chalice")
	# 31 Pendule
	_eq([C.PENDULUM], 1)
	pl.dash_cd = 0.6
	pl.soul = 0
	pl.parry_t = 0.3
	pl.receive_hit(pl.global_position + Vector2(30, 0), null)
	if pl.dash_cd > 0.0 or pl.soul < 5: fails.append("pendulum dash %f soul %d" % [pl.dash_cd, pl.soul])
	# 23 Aile de Phalène : second saut en l'air
	_eq([C.MOTH_WING], 1)
	for i in 120:
		await _f(1)
		if pl.is_on_floor(): break
	await _f(5)
	print("au sol : ", pl.is_on_floor())
	Input.action_press("jump"); await _f(2); Input.action_release("jump")
	await _f(14)
	var vy0: float = pl.velocity.y
	Input.action_press("jump"); await _f(2)
	var vy1: float = pl.velocity.y
	Input.action_release("jump")
	print("double saut : ", vy0, " -> ", vy1, " used ", pl.air_jump_used, " eq ", pl.eq(C.MOTH_WING), " floor ", pl.is_on_floor(), " buf ", pl.buffer_t, " coy ", pl.coyote_t)
	if vy1 > -400.0: fails.append("moth wing")
	await _f(60)
	# 24 Ombre Jumelle : deux ruées en l'air
	_eq([C.TWIN_SHADOW], 1)
	pl.can_dash = true
	Input.action_press("jump"); await _f(2); Input.action_release("jump")
	await _f(6)
	Input.action_press("dash"); await _f(1); Input.action_release("dash")
	await _f(20)
	pl.dash_cd = 0.0
	var air: bool = not pl.is_on_floor()
	Input.action_press("dash"); await _f(1); Input.action_release("dash")
	print("ruée 2 en l'air : ", air, " dash_t ", pl.dash_t)
	if air and pl.dash_t <= 0.0: fails.append("twin shadow")
	await _f(60)
	# icônes : chaque emblème a son propre dessin (pas le losange par défaut)
	var src: String = FileAccess.get_file_as_string("res://scripts/charm_icon.gd")
	for i in range(21, 42):
		if not src.contains("\t\t%d:  #" % i):
			fails.append("icon %d" % i)
	print("échecs : ", fails)
	print("RESULT ", "OK" if fails.is_empty() else "FAIL")
	quit()

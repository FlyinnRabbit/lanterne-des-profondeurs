extends CharacterBody2D
# Le Veilleur : petit voyageur encapuchonné armé d'une aiguille.
# Course, saut à hauteur variable, ruée (dash), coups dans 4 directions
# (le coup vers le bas fait rebondir : « pogo »), concentration pour se soigner.

const DU = preload("res://scripts/draw_util.gd")
const C = preload("res://scripts/charms.gd")

const SIZE := Vector2(20, 34)
const RUN_SPEED := 270.0
const GRAVITY := 1800.0
const FALL_MAX := 950.0
const JUMP_VELOCITY := -720.0
const JUMP_CUT := 0.4
const COYOTE := 0.1
const JUMP_BUFFER := 0.12
const DASH_SPEED := 760.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.75   # 0,45 avant : la Ruée se spammait
const ATTACK_COOLDOWN := 0.36
const ATTACK_TIME := 0.12
const COMBO_WINDOW := 0.55      # délai pour enchaîner le coup suivant du combo
const COMBO_SLACK := 0.3        # marge pour enchaîner, comptée APRÈS le temps de recharge de l'arme
#   (avant : fenêtre fixe de 0,55 s depuis le coup -> presque impossible avec les étoiles, impossible au marteau)
const CHARGE_TIME := 0.7        # maintien de la frappe pour un coup chargé
const THRUST_TIME := 0.2        # estoc (frapper pendant/juste après une ruée)
const THRUST_SPEED := 620.0
const SPIN_TIME := 0.28
const SPIN_REACH := 62.0        # demi-largeur du tourbillon (un coup normal porte à 70)
const SPELL_COST := 33
const CROUCH_SIZE := Vector2(20, 18)
const PLUNGE_SPEED := 980.0
const PERFECT_PARRY := 0.12     # parade dans les 0,12 premières secondes = parfaite
const CRIT_MULT := 1.5
const CRIT_TIME := 6.0
const Weapons = preload("res://scripts/weapons.gd")
const TrapScript = preload("res://scripts/trap.gd")
const DummyScript = preload("res://scripts/dummy.gd")
const POGO_VELOCITY := -580.0
const RECOIL_SLASH := 110.0     # recul du héros (px/s pendant 0,08 s) : coups 1 et 2 du combo ≈ 9 px
const RECOIL_FINISHER := 300.0  # coup final ≈ 24 px
const INVULN_TIME := 1.3
const FOCUS_TIME := 0.9
const SOUL_PER_HIT := 11
const FOCUS_COST := 33
const SOUL_MAX := 99
const PARRY_WINDOW := 0.2
const PARRY_COOLDOWN := 0.55
const ULT_MAX := 100
const ULT_PER_HIT := 6
const ULT_PER_PARRY := 25
const ULT_CHARGE_TIME := 0.55

var main
var max_hp := 5
var hp := 5
var soul := 0
var geo := 0
var can_dash := false
var facing := 1
var coyote_t := 0.0
var buffer_t := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var air_dash_used := false
var attack_cd := 0.0
var attack_t := 0.0
var attack_dir := Vector2.RIGHT
var attack_hit := {}
var attack_kind := "slash"     # slash / finisher / thrust / spin
var combo_i := 0
var combo_t := 0.0
var charge_t := 0.0
var thrust_t := 0.0
var post_dash_t := 0.0
var spell_cd := 0.0
var air_i := -1                 # combo aérien (0, 1, 2)
var crouching := false
var crouch_block := false   # après un piqué : pas d'accroupi tant que « bas » n'a pas été relâché
var crouch_latch := false
var rest_acc := 0.0
var combat_t := 99.0      # temps depuis le dernier coup donné ou reçu
var trap_parry := false
var parry_perfect_now := false   # la parade en cours est parfaite (lu par l'ennemi paré)   # la parade en cours vient d'un piège (pas d'âme ni d'ultime)
var plunging := false
var plunge_used := false        # une seule plongée par saut
var rise_used := false          # une seule entaille montante par saut (pas de vol infini)
var plunge_cd := 0.0
var plunge_kill_t := 0.0
var crit_ready := false         # coup critique prêt (après une parade parfaite)
var crit_t := 0.0
var attack_crit := false        # le coup en cours est critique
var last_crit_t := 0.0          # pour le journal des dégâts
var perfect_t := 0.0
var cs: CollisionShape2D
var crit_light: PointLight2D
var invuln_t := 0.0
var knock_t := 0.0
var recoil_t := 0.0
var recoil_vx := 0.0
var focus_t := 0.0
var last_safe := Vector2.ZERO
var sitting := false
var sit_t := 0.0
# Délai avant de pouvoir s'asseoir sur un banc après une attaque, un sort, un coup reçu ou
# après s'être relevé : empêche d'enchaîner frappe → banc (intouchable) → frappe.
const BENCH_LOCK := 1.5
var bench_lock_t := 0.0
var dead := false
var anim_t := 0.0
var squash := Vector2.ONE
var was_on_floor := true
var last_vy := 0.0
var after_t := 0.0
var parry_t := 0.0
var parry_cd := 0.0
var parry_flash := 0.0
var ult := 0
var ult_charge_t := 0.0

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs = CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	crit_light = main.make_light(Color(1.0, 0.75, 0.3), 0.7, 1.4)
	crit_light.enabled = false
	add_child(crit_light)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	last_safe = global_position

# ---------------------------------------------------------------- emblèmes
func eq(id: int) -> bool:
	return GameState.has_charm(id)

func run_speed() -> float:
	return RUN_SPEED * (1.12 if eq(C.SWIFT_CLOAK) else 1.0)

func dash_cooldown() -> float:
	return DASH_COOLDOWN * (0.5 if eq(C.SWIFT_CLOAK) else 1.0)

func parry_window() -> float:
	return 0.35 if eq(C.MIRROR) else PARRY_WINDOW

func focus_time() -> float:
	var quick := eq(C.QUICK_FOCUS)
	var rest := crouching and eq(C.SHADOW_REST)
	var m := 1.0
	if quick and rest:
		m = 0.55 * 0.9          # les deux : le meilleur bonus + un petit supplément
	elif quick:
		m = 0.55
	elif rest:
		m = 0.667
	return maxf(FOCUS_TIME * m, 0.4)

func soul_per_hit() -> int:
	return roundi((SOUL_PER_HIT + (6 if eq(C.GREED) else 0)) * float(GameState.d("soul")))

func ult_per_hit() -> int:
	return roundi((ULT_PER_HIT + (4 if eq(C.GREED) else 0)) * float(GameState.d("ult")))

func nail_damage() -> int:
	return 2 if eq(C.BRUTE) else 1   # Force Brute : +1 dégât (le double au départ, plus en profondeur)

func reach() -> float:
	return 1.4 if eq(C.LONG_NAIL) else 1.0

# À appeler quand l'équipement change
func apply_equipment() -> void:
	max_hp = 5 + (2 if eq(C.GLASS_HEART) else 0) + GameState.max_hp_bonus()
	hp = mini(hp, max_hp)

func weapon() -> Dictionary:
	return Weapons.get_w(GameState.weapon())

func get_rect() -> Rect2:
	if crouching:
		return Rect2(global_position + Vector2(-CROUCH_SIZE.x / 2.0, SIZE.y / 2.0 - CROUCH_SIZE.y), CROUCH_SIZE)
	return Rect2(global_position - SIZE / 2.0, SIZE)

# Accroupi : boîte de collision plus basse (les attaques hautes passent au-dessus)
func _set_crouch(on: bool) -> void:
	if on == crouching:
		return
	if not on:
		# se relever seulement s'il y a la place au-dessus
		for dx in [-8.0, 8.0]:
			if main.is_solid_at(global_position + Vector2(dx, -SIZE.y / 2.0 + 2.0)):
				return
	crouching = on
	var sh := cs.shape as RectangleShape2D
	sh.size = CROUCH_SIZE if on else SIZE
	cs.position = Vector2(0, (SIZE.y - CROUCH_SIZE.y) / 2.0) if on else Vector2.ZERO

func _physics_process(delta: float) -> void:
	anim_t += delta
	for t in ["coyote_t", "buffer_t", "dash_t", "dash_cd", "attack_cd", "attack_t", "invuln_t", "knock_t", "recoil_t",
			"combo_t", "thrust_t", "post_dash_t", "spell_cd", "crit_t", "last_crit_t", "perfect_t", "plunge_cd", "plunge_kill_t",
			"bench_lock_t"]:
		set(t, maxf(get(t) - delta, 0.0))
	if attack_t > 0.0 or thrust_t > 0.0 or ult_charge_t > 0.0:
		bench_lock_t = BENCH_LOCK
	parry_t = maxf(parry_t - delta, 0.0)
	parry_cd = maxf(parry_cd - delta, 0.0)
	parry_flash = maxf(parry_flash - delta, 0.0)
	combat_t += delta
	if crouching and eq(C.SHADOW_REST) and soul < FOCUS_COST and combat_t >= 3.0 and not _enemy_near(320.0):
		rest_acc += delta * 5.0
		if rest_acc >= 1.0:
			rest_acc -= 1.0
			soul = mini(soul + 1, SOUL_MAX)
	if crit_ready and crit_t <= 0.0:
		crit_ready = false
	crit_light.enabled = crit_ready
	if crit_ready:
		crit_light.energy = 1.1 + 0.4 * sin(anim_t * 10.0)
		crit_light.position = Vector2(facing * 16, -2)
	squash = squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	modulate.a = 0.35 if (invuln_t > 0.0 and fmod(invuln_t, 0.16) < 0.08 and not sitting) else 1.0
	queue_redraw()
	if dead:
		return
	if sitting:
		velocity = Vector2.ZERO
		sit_t += delta
		# Se relever : bouger, ou n'importe quelle action. On accepte une touche simplement
		# enfoncée (après un court délai) : un appui très bref pouvait passer inaperçu quand
		# le jeu tournait lentement, et on restait « collé » au banc.
		var want := absf(Input.get_axis("move_left", "move_right")) > 0.5
		for a in ["jump", "down", "attack", "dash", "parry"]:
			if Input.is_action_just_pressed(a) or (sit_t > 0.25 and Input.is_action_pressed(a)):
				want = true
		if want and sit_t > 0.12:
			sitting = false
			bench_lock_t = BENCH_LOCK
			_leave_bench()
			attack_cd = maxf(attack_cd, 0.2)
			buffer_t = 0.0
		return

	# Ultime : immobile et invulnérable pendant la charge, puis onde de choc
	if ult_charge_t > 0.0:
		ult_charge_t -= delta
		velocity = Vector2.ZERO
		if ult_charge_t <= 0.0:
			main.ultimate_blast(global_position)
			invuln_t = maxf(invuln_t, 0.4)
		return
	if Input.is_action_just_pressed("ultimate") and knock_t <= 0.0:
		if ult >= ULT_MAX:
			ult = 0
			ult_charge_t = ULT_CHARGE_TIME
			dash_t = 0.0
			attack_t = 0.0
			main.on_ultimate_charge(self)
			return
		else:
			main.show_message("Ultime pas encore chargé", 0.9)

	# Parade : courte fenêtre où un coup ou un projectile est renvoyé
	if Input.is_action_just_pressed("parry") and parry_cd <= 0.0 and knock_t <= 0.0:
		parry_t = parry_window()
		parry_cd = PARRY_COOLDOWN

	var dir := Input.get_axis("move_left", "move_right")
	if absf(dir) < 0.3:
		dir = 0.0
	else:
		dir = signf(dir)
	if Input.is_action_just_pressed("jump"):
		buffer_t = JUMP_BUFFER
	var on_floor := is_on_floor()
	if on_floor:
		coyote_t = COYOTE
		air_dash_used = false
		air_i = -1
		plunge_used = false
		rise_used = false
		if not was_on_floor:
			squash = Vector2(1.3, 0.7)
			main.spawn_burst(global_position + Vector2(0, SIZE.y / 2), Color(0.6, 0.65, 0.8, 0.6), 6, 80.0, 50.0)
		_update_safe_spot()

	# Concentration (soin) : maintenir L au sol avec 33 d'âme
	if Input.is_action_pressed("focus") and on_floor and soul >= FOCUS_COST and hp < max_hp and knock_t <= 0.0 and not (GameState.curse == "fragile" and GameState.mode == "descent"):
		focus_t += delta
		_set_crouch(crouch_latch if Settings.crouch_toggle else Input.is_action_pressed("down"))
		velocity.x = 0.0
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
		if focus_t >= focus_time():
			focus_t = 0.0
			soul -= FOCUS_COST
			hp += 1
			Audio.sfx("heal", 0.0)
			main.spawn_burst(global_position, Color(1, 1, 1), 20, 160.0, -100.0)
		move_and_slide()
		_post_move(on_floor)
		return
	focus_t = 0.0

	# Attaque plongée : en l'air, bas + ruée = piqué vers le sol, onde de choc à l'impact
	if not on_floor and not plunging and not plunge_used and plunge_cd <= 0.0 and Input.is_action_pressed("down") and Input.is_action_just_pressed("dash") and knock_t <= 0.0:
		plunging = true
		plunge_used = true
		plunge_cd = 0.6
		crouch_block = true
		crouch_latch = false
		dash_t = 0.0
		attack_hit.clear()
		attack_crit = _take_crit()
		squash = Vector2(0.7, 1.35)
		Audio.sfx("dash", 0.0, 3.0)
	if plunging:
		velocity = Vector2(0, PLUNGE_SPEED)
		_plunge_hits()
		move_and_slide()
		if is_on_floor() and plunging:
			_plunge_land()
		_post_move(on_floor)
		return

	# Ruée
	if can_dash and Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and (on_floor or not air_dash_used) and knock_t <= 0.0:
		if dir != 0.0:
			facing = int(dir)
		dash_t = DASH_TIME
		dash_cd = dash_cooldown()
		Audio.sfx("dash")
		crouch_latch = false      # la ruée relève le héros (mode bascule compris)
		if not on_floor:
			air_dash_used = true
		squash = Vector2(1.3, 0.8)
		main.spawn_burst(global_position, Color(0.2, 0.2, 0.3, 0.8), 10, 120.0, 0.0)
	# Estoc : frapper pendant la ruée (ou juste après) = coup perçant en ligne droite
	if Input.is_action_just_pressed("attack") and (dash_t > 0.0 or post_dash_t > 0.0) and thrust_t <= 0.0 and knock_t <= 0.0:
		_start_attack("thrust", Vector2(facing, 0))
		thrust_t = THRUST_TIME
		attack_t = THRUST_TIME
		dash_t = 0.0
		post_dash_t = 0.0
		Audio.sfx("dash", 0.05, 2.0)
	if thrust_t > 0.0:
		velocity = Vector2(facing * THRUST_SPEED, 0.0)
		_do_attack_hits()
		move_and_slide()
		_post_move(on_floor)
		return
	if dash_t > 0.0:
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		if dash_t <= delta * 1.5:
			post_dash_t = 0.15
		move_and_slide()
		_post_move(on_floor)
		return

	# Déplacement horizontal (nerveux, sans inertie, comme l'original)
	if knock_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
	elif recoil_t > 0.0:
		velocity.x = recoil_vx
	else:
		velocity.x = dir * run_speed() * (0.35 if parry_t > 0.0 else 1.0) * (0.3 if crouching else 1.0)
		if dir != 0.0 and attack_t <= 0.0:
			facing = int(dir)
	# Le piqué se lance en maintenant « bas » : à l'atterrissage on ne s'accroupit pas tant que la
	# touche n'a pas été relâchée (avant : on se retrouvait accroupi, à ramper, avec un coup bas)
	if crouch_block and not Input.is_action_pressed("down"):
		crouch_block = false
	if Settings.crouch_toggle:
		if on_floor and Input.is_action_just_pressed("down"):
			crouch_latch = not crouch_latch
		if not on_floor or Input.is_action_just_pressed("jump") or dash_t > 0.0:
			crouch_latch = false
		_set_crouch(on_floor and crouch_latch and knock_t <= 0.0)
	else:
		_set_crouch(on_floor and Input.is_action_pressed("down") and knock_t <= 0.0 and not crouch_block)

	# Saut
	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	if buffer_t > 0.0 and coyote_t > 0.0 and knock_t <= 0.0:
		velocity.y = JUMP_VELOCITY
		Audio.sfx("jump", 0.1, -4.0)
		buffer_t = 0.0
		coyote_t = 0.0
		squash = Vector2(0.7, 1.3)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Attaque : combo de 3 coups (le 3e est un coup final), coup chargé en maintenant
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0 and knock_t <= 0.0:
		var adir := Vector2(facing, 0)
		if Input.is_action_pressed("up"):
			adir = Vector2.UP
		elif Input.is_action_pressed("down") and not on_floor:
			adir = Vector2.DOWN
		if not on_floor and adir.y == 0.0:
			# combo aérien : entaille, entaille montante, puis vrille
			air_i = (air_i + 1) % 3 if combo_t > 0.0 else 0
			_start_attack(["air", "air_rise", "air_spin"][air_i], adir)
			combo_t = attack_cd + COMBO_SLACK
			if air_i == 1 and not rise_used:
				rise_used = true
				velocity.y = minf(velocity.y, -300.0)
			elif air_i == 2 and not rise_used:
				velocity.y = minf(velocity.y, -150.0)
		else:
			combo_i = (combo_i + 1) % 3 if combo_t > 0.0 else 0
			if crouching and adir.y == 0.0:
				combo_i = -1
				_start_attack("low", adir)
			else:
				_start_attack("finisher" if combo_i == 2 and adir.y == 0.0 else "slash", adir)
			combo_t = attack_cd + COMBO_SLACK
		charge_t = 0.0
	if Input.is_action_pressed("attack") and attack_t <= 0.0 and knock_t <= 0.0:
		var before := charge_t
		charge_t += delta
		if before < CHARGE_TIME and charge_t >= CHARGE_TIME:
			main.spawn_burst(global_position, Color(1.0, 0.95, 0.75), 10, 120.0, -100.0)
			Audio.sfx("pickup", 0.0, -8.0)
	if Input.is_action_just_released("attack"):
		if charge_t >= CHARGE_TIME and knock_t <= 0.0:
			_start_attack("spin", Vector2(facing, 0))
			attack_t = SPIN_TIME
			main.shake(6)
		charge_t = 0.0
	if attack_t > 0.0:
		_do_attack_hits()

	# Sort d'âme : lame d'âme qui traverse les ennemis (coûte 33 d'âme)
	if Input.is_action_just_pressed("spell") and soul >= SPELL_COST and spell_cd <= 0.0 and knock_t <= 0.0:
		soul -= SPELL_COST
		spell_cd = 0.45
		bench_lock_t = BENCH_LOCK
		var crit := _take_crit()
		var sdmg := 3 + (1 if eq(C.BRUTE) else 0)
		main.spawn_projectile(global_position + Vector2(facing * 20, -4), Vector2(facing * 620.0, 0),
			{"kind": "soulblade", "hostile": false, "radius": 14.0, "life": 1.1, "pierce": true,
			"damage": crit_damage(sdmg) if crit else sdmg, "crit": crit})
		recoil_t = 0.1
		recoil_vx = -facing * 180.0
		squash = Vector2(1.2, 0.85)
		Audio.sfx("parry", 0.05, -3.0)

	last_vy = velocity.y
	move_and_slide()
	_post_move(on_floor)

func _post_move(prev_on_floor: bool) -> void:
	was_on_floor = is_on_floor()
	if not prev_on_floor and was_on_floor and last_vy > 420.0:
		main.spawn_fx("dust", global_position + Vector2(0, SIZE.y / 2.0), Color(0.75, 0.72, 0.68))
	# images rémanentes pendant la ruée
	if dash_t > 0.0:
		after_t -= get_physics_process_delta_time()
		if after_t <= 0.0:
			after_t = 0.035
			main.spawn_fx("after", global_position + Vector2(0, SIZE.y / 2.0), GameState.cos.look("trail")["c2"].lightened(0.35), Vector2.RIGHT, facing)
	_check_hazards()

func _update_safe_spot() -> void:
	var feet_y := global_position.y + SIZE.y / 2.0 + 4.0
	var l := Vector2(global_position.x - SIZE.x, feet_y)
	var r := Vector2(global_position.x + SIZE.x, feet_y)
	if main.is_solid_at(l) and main.is_solid_at(r):
		last_safe = global_position

# Utilise le coup critique s'il est prêt
func _take_crit() -> bool:
	if crit_ready:
		crit_ready = false
		main.spawn_burst(global_position + Vector2(facing * 18, -4), Color(1.0, 0.8, 0.35), 14, 220.0, 0.0)
		return true
	return false

func _start_attack(kind: String, adir: Vector2) -> void:
	var wpn := weapon()
	attack_kind = kind
	attack_dir = adir
	attack_cd = ATTACK_COOLDOWN * (1.3 if kind == "finisher" else 1.0) * float(wpn["cd"]) * (1.2 if eq(C.BRUTE) else 1.0)
	attack_t = ATTACK_TIME * (1.4 if kind in ["finisher", "air_spin"] else 1.0)
	attack_hit.clear()
	attack_crit = _take_crit()
	match GameState.weapon():
		"fouet": Audio.sfx("whip", 0.1, -3.0)
		"marteau": Audio.sfx("hammer", 0.08, -2.0)
		"shuriken": Audio.sfx("star", 0.15, -4.0)
		_: Audio.sfx("slash", 0.12, -2.0 if kind == "slash" else 1.0)
	if attack_crit:
		Audio.sfx("crit", 0.05, -1.0)
	if wpn["ranged"]:
		_throw_stars(kind, adir)
	elif kind == "finisher" and GameState.weapon_level() >= 2:
		match GameState.weapon():
			"aiguille":
				main.spawn_projectile(global_position + Vector2(facing * 30, -4), Vector2(facing * 560.0, 0),
					{"kind": "slashwave", "hostile": false, "radius": 12.0, "life": 0.32, "pierce": true, "damage": nail_damage(), "crit": false})
			"marteau":
				var feet := global_position + Vector2(0, SIZE.y / 2.0 - 4.0)
				for d in [-1.0, 1.0]:
					# l'onde part des pieds du héros (et non 24 px plus loin, où une marche ou un bord la faisait disparaître)
					main.spawn_projectile(feet + Vector2(d * 6.0, 0), Vector2(d * 380.0, 0), {"kind": "wave", "hostile": false, "damage": nail_damage() + 1, "life": 0.7})
				main.shake(6)

# Shurikens : l'arme lancée
func _throw_stars(kind: String, adir: Vector2) -> void:
	# au plus 3 étoiles « simples » à l'écran (le coup final, le tourbillon et l'estoc passent outre)
	if kind in ["slash", "air", "air_rise", "low"]:
		var n := 0
		for pr in get_tree().get_nodes_in_group("projectiles"):
			if is_instance_valid(pr) and pr.kind == "shuriken" and not pr.hostile:
				n += 1
		if n >= 3:
			attack_crit = false
			return
	var dmg := hit_damage()
	var base := Vector2(facing, 0) if adir.y == 0.0 else adir
	var dirs := [base]
	var big := false
	match kind:
		"finisher", "air_spin":
			dirs = [base.rotated(-0.18), base, base.rotated(0.18)]
		"spin":
			dirs = []
			for i in 8:
				dirs.append(Vector2.from_angle(i * TAU / 8.0))
		"thrust":
			big = true
		"air_rise":
			dirs = [Vector2(facing, -0.6).normalized()]
		"low":
			dirs = [Vector2(facing, 0)]
	var first := true
	var volley := {}     # une salve ne touche qu'une fois le même ennemi
	for d in dirs:
		var star_crit := attack_crit and first     # le critique ne vaut que pour une étoile
		first = false
		main.spawn_projectile(global_position + d * 14.0 + Vector2(0, 6 if kind == "low" else -4), d * (560.0 if not big else 480.0),
			{"kind": "shuriken", "hostile": false, "radius": 14.0 if big else 8.0, "life": 0.6 if not big else 0.8,
			"pierce": big, "damage": dmg if (star_crit or not attack_crit) else _base_damage(), "crit": star_crit, "boomerang": GameState.weapon_level() >= 2, "volley": volley})
	attack_crit = false

# Dégâts selon le type de coup
# Dégâts du coup en cours sans le critique
func _base_damage() -> int:
	var c := attack_crit
	attack_crit = false
	var d := hit_damage()
	attack_crit = c
	return d

func hit_damage() -> int:
	var d := nail_damage() + int(weapon()["dmg"])
	match attack_kind:
		"finisher", "thrust", "air_spin", "plunge":
			d += 1
		"spin":
			d = d * 2 + 1
	return crit_damage(d) if attack_crit else d

# Critique : ×1,5 arrondi au-dessus, et toujours au moins +1
func crit_damage(d: int) -> int:
	return maxi(d + 1, ceili(d * CRIT_MULT))

func attack_rect() -> Rect2:
	var p := global_position
	var wpn := weapon()
	if wpn["ranged"]:
		return Rect2(p, Vector2.ZERO)      # les shurikens touchent eux-mêmes
	if attack_kind == "spin":
		var rs := SPIN_REACH * reach() * maxf(1.0, float(wpn["w"]) * 0.6)
		return Rect2(p - Vector2(rs, rs * 0.8), Vector2(rs * 2.0, rs * 1.6))
	if attack_kind == "air_spin":
		var ra := 62.0 * reach()
		return Rect2(p - Vector2(ra, ra), Vector2(ra * 2.0, ra * 2.0))
	if attack_kind == "low":
		var lw := 70.0 * reach() * float(wpn["w"])
		var lx := p.x if facing > 0 else p.x - lw
		return Rect2(Vector2(lx, p.y + 2), Vector2(lw, 18))
	if attack_kind == "thrust":
		var tw := 120.0 * reach()
		var tx := p.x if facing > 0 else p.x - tw
		return Rect2(Vector2(tx, p.y - 16), Vector2(tw, 26))
	if attack_dir == Vector2.UP:
		var hu := 62.0 * reach() * float(wpn["v"])
		return Rect2(p + Vector2(-32, -SIZE.y / 2.0 + 4 - hu), Vector2(64, hu))
	if attack_dir == Vector2.DOWN:
		return Rect2(p + Vector2(-32, SIZE.y / 2.0 - 6), Vector2(64, 62.0 * reach() * float(wpn["v"])))
	var w := 70.0 * reach() * (1.3 if attack_kind == "finisher" else 1.0) * float(wpn["w"])
	var hgt := 54.0 * (1.25 if attack_kind == "finisher" else 1.0) * float(wpn["h"])
	if attack_kind == "air_rise":
		hgt *= 1.4
	# fouet : la liane s'arrête au premier mur (pas de coup à travers la roche)
	if GameState.weapon() == "fouet":
		var step := 8.0
		var d := 0.0
		while d < w:
			if main.is_solid_at(Vector2(p.x + facing * (SIZE.x / 2.0 + d), p.y - 4.0)):
				break
			d += step
		w = maxf(d, 24.0)
	var x := p.x + SIZE.x / 2.0 - 4.0 if facing > 0 else p.x - SIZE.x / 2.0 - w + 4.0
	return Rect2(Vector2(x, p.y - hgt * 0.55), Vector2(w, hgt))

func _hit_breakables(r: Rect2) -> void:
	for b in get_tree().get_nodes_in_group("breakables"):
		if is_instance_valid(b) and not attack_hit.has(b) and b.get_rect().intersects(r):
			attack_hit[b] = true
			b.hit(1)
			if attack_dir == Vector2.DOWN and not is_on_floor():
				_pogo()

func _do_attack_hits() -> void:
	var r := attack_rect()
	_hit_breakables(r)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or attack_hit.has(e):
			continue
		if e.get_rect().intersects(r):
			attack_hit[e] = true
			var kdir := attack_dir
			if attack_kind in ["spin", "air_spin"]:
				kdir = (e.global_position - global_position).normalized()
			if attack_crit:
				last_crit_t = 0.2
			var wpn := weapon()
			e.take_hit(hit_damage(), kdir * (1.6 if attack_kind == "finisher" else 1.0) * float(wpn["knock"]))
			if float(wpn["stagger"]) > 0.0 and is_instance_valid(e) and not e.is_boss:
				e.stun_t = maxf(e.stun_t, float(wpn["stagger"]))
			# fouet niv. 2 : attire les petits ennemis
			if GameState.weapon() == "fouet" and GameState.weapon_level() >= 2 and is_instance_valid(e) and not e.is_boss and not e.dead:
				# attire jusqu'à une distance de frappe (pas au contact) et étourdit brièvement :
				# l'ennemi attiré est inoffensif le temps d'arriver
				var pull: Vector2 = global_position - e.global_position
				var gap := pull.length() - 70.0
				if gap > 10.0:
					e.knock = pull.normalized() * minf(sqrt(4400.0 * gap), 900.0)   # s'arrête à ~70 px
					e.stun_t = maxf(e.stun_t, 0.7)
			Audio.sfx("hit")
			soul = mini(soul + soul_per_hit(), SOUL_MAX)
			ult = mini(ult + ult_per_hit(), ULT_MAX)
			main.shake(4 if attack_kind == "slash" else 8)
			main.hit_stop(0.04 if attack_kind == "slash" else 0.07)
			if attack_kind in ["spin", "thrust", "air_spin", "air_rise"]:
				pass   # pas de recul : ces coups traversent
			elif attack_dir == Vector2.DOWN:
				_pogo()
			elif attack_dir.x != 0.0 and not crouching and attack_kind != "low":
				# Recul : léger sur les deux premiers coups (le combo reste à portée d'une cible fixe),
				# franc sur le coup final, aucun accroupi (on est ancré au sol).
				# (avant : 26 px à chaque coup -> le coup final du marteau et le 2e coup bas ratait le mannequin)
				recoil_t = 0.08
				recoil_vx = -facing * (RECOIL_FINISHER if attack_kind == "finisher" else RECOIL_SLASH)
	# Les spores ennemies peuvent être détruites d'un coup d'aiguille
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile and pr.get_rect().intersects(r):
			pr.pop()
			soul = mini(soul + 4, SOUL_MAX)
	if attack_dir == Vector2.DOWN and not attack_hit.has("spikes"):
		for s in main.spikes:
			if s.intersects(r):
				attack_hit["spikes"] = true
				main.spawn_burst(Vector2(global_position.x, s.position.y), Color(1, 1, 1), 6, 120.0)
				_pogo()
				break

func _pogo() -> void:
	velocity.y = POGO_VELOCITY
	air_dash_used = false
	dash_cd = 0.0
	squash = Vector2(0.8, 1.2)

func _check_hazards() -> void:
	if dead:
		return
	var r := get_rect().grow(-3)
	for s in main.spikes:
		if r.intersects(s):
			_hazard_respawn()
			return
	# Esquive : pendant la ruée on traverse ennemis et projectiles
	if dash_t > 0.0:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_harmful() and r.intersects(e.get_rect()):
			if not e.is_boss and main.wall_between(global_position, e.global_position):
				continue      # pas de coup à travers un mur (estoc du lancier, charge…)
			receive_hit(e.global_position, e)
			return

# Point d'entrée de tout coup reçu (contact ou projectile). Renvoie true si paré.
func receive_hit(from_pos: Vector2, source) -> bool:
	if dead:
		return false
	if parry_t > 0.0:
		_on_parry(from_pos, source)
		return true
	if invuln_t > 0.0 or ult_charge_t > 0.0 or sitting:
		return false
	take_damage(int(GameState.d("dmg")), from_pos.x)
	return false

func _on_parry(from_pos: Vector2, source) -> void:
	# parade parfaite : le prochain coup sera critique (×1,5) et l'ennemi est étourdi plus longtemps
	parry_perfect_now = parry_window() - parry_t <= PERFECT_PARRY
	if not _from_trap(source):
		Achievements.on_parry()
	if parry_perfect_now:
		crit_ready = true
		crit_t = CRIT_TIME
		perfect_t = 1.2
		Audio.sfx("crit_ready", 0.0, 0.0)
		if not _from_trap(source):
			Achievements.on_perfect_parry()
		if eq(C.ECHO):
			var ed := signf(from_pos.x - global_position.x)
			if ed == 0.0:
				ed = float(facing)
			main.spawn_projectile(global_position + Vector2(ed * 20, -4), Vector2(ed * 620.0, 0),
				{"kind": "soulblade", "hostile": false, "radius": 14.0, "life": 1.1, "pierce": true, "damage": 3})
	parry_t = 0.0
	parry_cd = 0.12
	parry_flash = 0.25
	invuln_t = maxf(invuln_t, 0.4)
	if not _from_trap(source):
		ult = mini(ult + roundi(ULT_PER_PARRY * float(GameState.d("ult"))), ULT_MAX)
		soul = mini(soul + soul_per_hit(), SOUL_MAX)
		combat_t = 0.0
	var d := (from_pos - global_position).normalized()
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	if source and source.has_method("parried"):
		source.parried(d)
	velocity.x = -signf(d.x) * 200.0
	recoil_t = 0.1
	recoil_vx = velocity.x
	main.on_parry(global_position + d * 18.0)

# Arme tenue en main (dessinée dans le repère du personnage, pieds en 0, tourné à droite)
# traînée de coup « peinte » : croissant effilé, bord extérieur vif qui s'estompe vers l'intérieur
func _smear(piv: Vector2, rad: float, a0: float, a1: float, thick: float, col: Color, k: float) -> void:
	col = col * Color(GameState.cos.look("trail")["slash"], 1.0)
	var n := 16
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		var a := lerpf(a0, a1, u)
		var th := thick * sin(u * PI) * (0.5 + 0.7 * u)
		outer.append(piv + Vector2.from_angle(a) * rad)
		inner.append(piv + Vector2.from_angle(a) * (rad - th))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in n + 1:
		pts.append(outer[i])
		var u := float(i) / n
		cols.append(Color(col.lightened(0.6), (0.45 + 0.55 * u) * k))
	for i in range(n, -1, -1):
		pts.append(inner[i])
		cols.append(Color(col.darkened(0.1), 0.18 * k))
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	draw_polygon(pts, cols)
	draw_polyline(outer, Color(1, 1, 1, 0.7 * k), 1.4)

func _draw_held(wid: String, bob: float) -> void:
	match wid:
		"fouet":
			# liane enroulée à la ceinture, épines
			var c := Vector2(13, -8 + bob)
			draw_arc(c, 5.0, 0.0, TAU, 14, Color(0.3, 0.45, 0.22), 3.0)
			draw_arc(c, 5.0, 0.0, TAU, 14, Color(0.55, 0.78, 0.4), 1.6)
			for i in 4:
				var a := i * TAU / 4.0 + 0.4
				draw_line(c + Vector2.from_angle(a) * 5.0, c + Vector2.from_angle(a) * 7.5, Color(0.75, 0.85, 0.55), 1.0)
			draw_line(Vector2(9, -12 + bob), Vector2(13, -3), Color(0.45, 0.65, 0.35), 2.0)
			draw_circle(Vector2(13, -2), 1.8, Color(0.85, 1.0, 0.65))
		"marteau":
			# manche de bois cerclé, tête d'acier
			draw_line(Vector2(8, -14 + bob), Vector2(14, 0), Color(0.3, 0.2, 0.12), 3.6)
			draw_line(Vector2(8, -14 + bob), Vector2(14, 0), Color(0.55, 0.4, 0.26), 1.6)
			draw_line(Vector2(9.5, -10 + bob), Vector2(11.5, -10.5 + bob), Color(0.7, 0.6, 0.3), 1.4)
			DU.box(self, Rect2(Vector2(8, -2), Vector2(13, 8)), Color(0.5, 0.52, 0.6))
			draw_line(Vector2(19, -1), Vector2(19, 5), Color(0.85, 0.87, 0.95), 1.0)
		"shuriken":
			var c := Vector2(13, -6 + bob)
			for i in 4:
				var a := i * PI / 2.0 + anim_t * 2.0
				DU.flat(self, PackedVector2Array([c, c + Vector2.from_angle(a - 0.35) * 3.0, c + Vector2.from_angle(a) * 7.0]), Color(0.82, 0.88, 0.98))
				draw_line(c, c + Vector2.from_angle(a) * 6.5, Color(1, 1, 1, 0.6), 0.8)
			draw_circle(c, 1.6, Color(0.3, 0.35, 0.45))
			DU.glow(self, c, 9.0, Color(0.7, 0.85, 1.0), 0.3)
		_:
			# aiguille : lame fine, garde dorée, poignée tressée
			var hand := Vector2(8, -14 + bob)
			var tip := Vector2(17, -1)
			var d := (tip - hand).normalized()
			var nn := d.orthogonal()
			draw_line(hand - d * 3.0, hand + d * 1.5, Color(0.35, 0.25, 0.2), 2.6)
			draw_line(hand + d * 1.5 + nn * 3.0, hand + d * 1.5 - nn * 3.0, Color(0.8, 0.65, 0.35), 2.0)
			DU.flat(self, PackedVector2Array([hand + d * 2.5 + nn * 1.3, tip, hand + d * 2.5 - nn * 1.3]), Color(0.86, 0.89, 0.97))
			draw_line(hand + d * 3.0, tip - d * 1.5, Color(1, 1, 1, 0.7), 0.8)

# ---------------------------------------------------------------- attaque plongée
func _plunge_rect() -> Rect2:
	return Rect2(global_position + Vector2(-18, SIZE.y / 2.0 - 10), Vector2(36, 40))

func _plunge_hits() -> void:
	plunge_kill_t = 0.5
	for b in get_tree().get_nodes_in_group("breakables"):
		if is_instance_valid(b) and b.get_rect().intersects(_plunge_rect().grow(4.0)):
			b.hit(3)
	var r := _plunge_rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not attack_hit.has(e) and e.get_rect().intersects(r):
			attack_hit[e] = true
			attack_kind = "plunge"
			if attack_crit:
				last_crit_t = 0.2
			e.take_hit(hit_damage(), Vector2.DOWN)
			Audio.sfx("hit")
			if eq(C.METEOR):
				crit_ready = true
				crit_t = CRIT_TIME
			soul = mini(soul + soul_per_hit(), SOUL_MAX)
			# rebond sur l'ennemi touché
			plunging = false
			attack_crit = false
			_pogo()
			main.shake(8)
			return

func _plunge_land() -> void:
	plunge_kill_t = 0.5
	plunging = false
	attack_kind = "plunge"
	squash = Vector2(1.45, 0.6)
	main.shake(12)
	Audio.sfx("kill", 0.0, 2.0)
	var feet := global_position + Vector2(0, SIZE.y / 2.0)
	main.spawn_burst(feet, Color(0.85, 0.9, 1.0), 26, 260.0, 300.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(feet) < 95.0:
			if attack_crit:
				last_crit_t = 0.2
			e.take_hit(hit_damage(), (e.global_position - feet).normalized())
	for d in [-1.0, 1.0]:
		main.spawn_projectile(feet + Vector2(d * 20.0, -4.0), Vector2(d * 360.0, 0), {"kind": "wave", "hostile": false, "damage": 1, "life": 0.6})
	attack_crit = false

func _from_trap(source) -> bool:
	return source != null and is_instance_valid(source) and (("from_trap" in source and source.from_trap) or source.get_script() == TrapScript)

func _enemy_near(r: float) -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead and e.global_position.distance_to(global_position) < r and e.get_script() != DummyScript:
			return true
	return false

func take_damage(amount: int, from_x: float) -> void:
	combat_t = 0.0
	bench_lock_t = BENCH_LOCK
	if dead:
		return
	hp -= amount
	invuln_t = INVULN_TIME
	knock_t = 0.22
	dash_t = 0.0
	focus_t = 0.0
	sitting = false
	var d := signf(global_position.x - from_x)
	if d == 0.0:
		d = -facing
	velocity = Vector2(d * 380.0, -380.0)
	main.on_player_hurt()
	if eq(C.THORNS):
		main.thorns_burst(global_position)
	if hp <= 0:
		_die()

func _hazard_respawn() -> void:
	hp -= int(GameState.d("dmg"))
	main.on_player_hurt()
	if hp <= 0:
		_die()
		return
	global_position = last_safe
	velocity = Vector2.ZERO
	invuln_t = INVULN_TIME
	knock_t = 0.3

func _die() -> void:
	dead = true
	hp = 0
	velocity = Vector2.ZERO
	visible = false
	main.on_player_died()

func respawn(pos: Vector2) -> void:
	global_position = pos
	last_safe = pos
	velocity = Vector2.ZERO
	hp = max_hp
	dead = false
	visible = true
	invuln_t = 1.0
	ult_charge_t = 0.0
	parry_t = 0.0

# En se relevant du banc : une seconde d'invulnérabilité et les ennemis collés au banc
# sont repoussés (et brièvement étourdis), pour ne pas prendre un coup en se levant.
func _leave_bench() -> void:
	invuln_t = maxf(invuln_t, 1.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss or not is_instance_valid(e):
			continue
		var d: Vector2 = e.global_position - global_position
		if d.length() < 130.0:
			var sx := signf(d.x) if absf(d.x) > 1.0 else (1.0 if randf() < 0.5 else -1.0)
			e.knock = Vector2(sx * 420.0, -160.0)
			e.stun_t = maxf(e.stun_t, 0.6)
	main.spawn_burst(global_position + Vector2(0, SIZE.y / 2.0 - 4.0), Color(1.0, 0.9, 0.6, 0.7), 12, 180.0, -40.0)

func sit(pos: Vector2, heal: bool = true) -> void:
	sitting = true
	sit_t = 0.0
	knock_t = 0.0
	global_position = pos
	last_safe = pos
	velocity = Vector2.ZERO
	if heal:
		hp = max_hp

# ---------------------------------------------------------------- dessin
func _draw() -> void:
	var moving := absf(velocity.x) > 10.0 and is_on_floor()
	var bob := sin(anim_t * 16.0) * 1.5 if moving else sin(anim_t * 2.5) * 0.6
	var sway := sin(anim_t * 16.0) * 3.0 if moving else sin(anim_t * 2.0) * 1.0
	if not is_on_floor():
		sway = clampf(velocity.y / 120.0, -4.0, 4.0)
	if sitting:
		bob = 4.0

	# Traînée de ruée
	if dash_t > 0.0:
		for i in 4:
			var a := 0.35 - i * 0.08
			draw_rect(Rect2(Vector2(-facing * (14 + i * 16) - 8, -14 + i * 2), Vector2(16, 24 - i * 4)), Color(GameState.cos.look("trail")["c2"], a))

	# Ultime en charge : anneaux dorés qui se resserrent
	var uc: Color = GameState.cos.look("ult")["c2"] if GameState.cos.eq("ult") == "ult_eclipse" else GameState.cos.look("ult")["c"]
	if ult_charge_t > 0.0:
		var k := 1.0 - ult_charge_t / ULT_CHARGE_TIME
		for i in 3:
			var rr := (1.0 - fmod(k + i * 0.33, 1.0)) * 70.0 + 8.0
			draw_arc(Vector2(0, -4), rr, 0.0, TAU, 40, Color(uc, 0.25 + 0.6 * k), 3.0)
		draw_circle(Vector2(0, -4), 10.0 + 14.0 * k, Color(uc.lightened(0.2), 0.35))
	elif ult >= ULT_MAX:
		draw_circle(Vector2(0, -4), 26.0 + sin(anim_t * 6.0) * 3.0, Color(uc, 0.12))
	# Parade : garde levée et éclat
	if parry_t > 0.0:
		var base_a := 0.0 if facing > 0 else PI
		draw_arc(Vector2(facing * 10, -6), 22.0, base_a - 1.4, base_a + 1.4, 16, Color(0.8, 0.9, 1.0, 0.8), 3.0)
		draw_line(Vector2(facing * 8, -20), Vector2(facing * 8, 6), Color(0.9, 0.92, 1.0), 2.5)
	if parry_flash > 0.0:
		var pk := parry_flash / 0.25
		draw_arc(Vector2(0, -6), 40.0 * (1.5 - pk), 0.0, TAU, 32, Color(1, 1, 1, pk), 4.0 * pk + 1.0)
	# Halo de concentration
	if focus_t > 0.0:
		var k := focus_t / focus_time()
		draw_circle(Vector2(0, -4), 10.0 + 30.0 * k, Color(1, 1, 1, 0.12 + 0.2 * k))

	var sq := squash * (Vector2(1.15, 0.58) if crouching else Vector2.ONE)
	draw_set_transform(Vector2(0, SIZE.y / 2.0), 0.0, Vector2(sq.x * facing, sq.y))
	# corps, cape, écharpe, capuche, œil et couvre-chef : selon les cosmétiques équipés
	GameState.cos.draw_hero(self, bob, sway, anim_t, sitting, moving)
	# Arme tenue au repos
	var wid: String = GameState.weapon()
	if attack_t <= 0.0 and not sitting:
		_draw_held(wid, bob)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Coup critique prêt : lumière dorée au bout de l'arme
	if crit_ready:
		var tip := Vector2(facing * 17, 4.0 if crouching else -4.0)
		var pulse := 1.0 + 0.25 * sin(anim_t * 12.0)
		draw_circle(tip, 16.0 * pulse, Color(1.0, 0.7, 0.25, 0.18))
		draw_circle(tip, 9.0 * pulse, Color(1.0, 0.75, 0.3, 0.35))
		draw_circle(tip, 4.5 * pulse, Color(1.0, 0.95, 0.7))
		for i in 4:
			var a := anim_t * 3.0 + i * PI / 2.0
			draw_line(tip + Vector2.from_angle(a) * 5.0, tip + Vector2.from_angle(a) * (11.0 + 3.0 * sin(anim_t * 9.0 + i)), Color(1.0, 0.85, 0.45, 0.85), 1.5)
	if perfect_t > 0.0:
		var pk := perfect_t / 1.2
		var f := ThemeDB.fallback_font
		var txt := tr("PARFAITE !")
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(f, Vector2(-tw / 2.0, -50 - (1.0 - pk) * 14.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.4, pk))
	# Attaque plongée : traînée et lame pointée vers le bas
	if plunging:
		for i in 4:
			draw_line(Vector2(-8 + i * 5, -20 - i * 6), Vector2(-8 + i * 5, -60 - i * 10), Color(0.75, 0.88, 1.0, 0.45), 2.0)
		draw_line(Vector2(0, 0), Vector2(0, 30), Color(0.95, 0.97, 1.0), 4.0)

	# Arc de l'attaque
	# Coup chargé prêt : l'aiguille scintille
	if charge_t > 0.2 and attack_t <= 0.0:
		var ck := clampf(charge_t / CHARGE_TIME, 0.0, 1.0)
		var cc := Color(1.0, 0.9, 0.6, 0.15 + 0.35 * ck) if ck >= 1.0 else Color(0.8, 0.9, 1.0, 0.1 + 0.25 * ck)
		draw_arc(Vector2(0, -4), 18.0 + 10.0 * ck, 0.0, TAU * ck, 24, cc, 3.0)
		if ck >= 1.0:
			draw_circle(Vector2(facing * 14, -6), 4.0 + sin(anim_t * 20.0), Color(1.0, 0.95, 0.75))
	if attack_t > 0.0:
		var r := attack_rect()
		var c := r.get_center() - global_position
		var ang := attack_dir.angle()
		match attack_kind:
			"spin":
				var k := clampf(attack_t / SPIN_TIME, 0.0, 1.0)
				var rot := (1.0 - k) * TAU * 1.5 * facing
				var sc: float = attack_rect().size.x / 2.0 / SPIN_REACH   # l'effet suit la portée réelle
				for i in 3:
					_smear(Vector2(0, -4), (30.0 + i * 12.0) * sc, rot + i * 2.1, rot + i * 2.1 + 2.4 * facing, 9.0, Color(1.0, 0.92, 0.7), k)
				DU.glow(self, Vector2(0, -4), 62.0 * sc * (1.2 - k), Color(1.0, 0.9, 0.6), 0.3 * k)
			"thrust":
				var k := clampf(attack_t / THRUST_TIME, 0.0, 1.0)
				var tip := Vector2(facing * r.size.x, -4)
				draw_line(Vector2(0, -4), tip, Color(0.95, 0.97, 1.0, 0.9 * k), 5.0)
				DU.flat(self, PackedVector2Array([tip + Vector2(facing * 14, 0), tip + Vector2(0, -6), tip + Vector2(0, 6)]), Color(1, 1, 1, k))
				for i in 4:
					draw_line(Vector2(-facing * (10 + i * 14), -14 + i * 7), Vector2(-facing * (40 + i * 14), -14 + i * 7), Color(0.7, 0.85, 1.0, 0.4 * k), 2.0)
			"low":
				if weapon()["ranged"]:
					return
				var kl := clampf(attack_t / ATTACK_TIME, 0.0, 1.0)
				var lc := Color(1.0, 0.6, 0.25, kl) if attack_crit else Color(weapon()["color"], 0.9 * kl)
				var pts := PackedVector2Array()
				for i in 11:
					var u := i / 10.0
					pts.append(Vector2(facing * (6.0 + r.size.x * u), c.y + 4.0 - sin(u * PI) * 9.0))
				draw_polyline(pts, lc, 6.0 * kl + 1.0)
				draw_polyline(pts, Color(1, 1, 1, 0.5 * kl), 2.0)
			"air_spin":
				var k := clampf(attack_t / (ATTACK_TIME * 1.4), 0.0, 1.0)
				var rot := (1.0 - k) * TAU * 2.0 * facing
				_smear(Vector2(0, -2), 50.0, rot, rot + 4.5 * facing, 12.0, Color(0.75, 0.9, 1.0), k)
			_:
				if weapon()["ranged"]:
					return
				if GameState.weapon() == "fouet" and attack_dir.y == 0.0:
					# fouet : liane ondulée jusqu'au bout de la zone de coup
					# la liane va exactement de la main au bout de la zone de coup
					var k2 := clampf(attack_t / (ATTACK_TIME * (1.4 if attack_kind == "finisher" else 1.0)), 0.0, 1.0)
					var start := Vector2(facing * 8.0, -4.0)
					var end_x: float = (r.end.x if facing > 0 else r.position.x) - global_position.x
					var pts := PackedVector2Array()
					for i in 13:
						var u := i / 12.0
						var wave := sin(u * 9.0 + anim_t * 40.0) * 6.0 * (1.0 - u)
						pts.append(Vector2(lerpf(start.x, end_x, u), lerpf(start.y, c.y, u) + wave))
					var vine := Color(1.0, 0.6, 0.25, k2) if attack_crit else Color(0.6, 0.85, 0.45, k2)
					draw_polyline(pts, vine, 4.0)
					for i in range(2, 12, 2):
						draw_line(pts[i], pts[i] + Vector2(-facing * 4.0, -5.0), Color(vine.darkened(0.3), k2), 1.5)   # épines
					draw_circle(pts[12], 5.0, Color(0.85, 1.0, 0.65, k2))
					return
				var fin := attack_kind == "finisher"
				var k := clampf(attack_t / (ATTACK_TIME * (1.4 if fin else 1.0)), 0.0, 1.0)
				var wcol: Color = weapon()["color"]
				var col := Color(1.0, 0.88, 0.55) if fin else wcol
				if attack_crit:
					col = Color(1.0, 0.6, 0.25)
				var hammer := GameState.weapon() == "marteau"
				var rad := (40.0 if fin else 30.0) * (1.25 if hammer else 1.0)
				var piv := c - attack_dir * 14.0
				var prog := 1.0 - k
				var ease := 1.0 - pow(1.0 - prog, 3.0)
				# sens du coup : de haut en bas devant soi, et pour les coups verticaux dans le sens du regard
				var sweep: float = 1.3 * (float(facing) if attack_dir.y != 0.0 else 1.0)
				var a0: float = ang - sweep
				var a_now := lerpf(a0, ang + sweep, minf(ease * 1.15, 1.0))
				var thick := (20.0 if fin else 15.0) * (1.4 if hammer else 1.0)
				_smear(piv, rad, a0, a_now, thick, col, k)
				if fin:
					_smear(piv, rad - 9.0, a0 + 0.3 * signf(sweep), a_now, thick * 0.6, Color(1, 1, 1), k * 0.7)
				# l'arme suit le coup
				var wdir := Vector2.from_angle(a_now)
				if hammer:
					var hp := piv + wdir * (rad + 2.0)
					draw_line(piv + wdir * 6.0, hp, Color(0.45, 0.32, 0.2), 3.4)
					var hn := wdir.orthogonal()
					DU.poly(self, PackedVector2Array([hp - hn * 8.0 - wdir * 4.0, hp + hn * 8.0 - wdir * 4.0, hp + hn * 8.0 + wdir * 5.0, hp - hn * 8.0 + wdir * 5.0]), Color(0.55, 0.56, 0.64))
				else:
					var tip := piv + wdir * (rad + 6.0)
					var hn := wdir.orthogonal()
					draw_line(piv + wdir * 5.0 + hn * 3.0, piv + wdir * 5.0 - hn * 3.0, Color(0.75, 0.6, 0.32), 2.2)
					DU.flat(self, PackedVector2Array([piv + wdir * 6.0 + hn * 1.6, tip, piv + wdir * 6.0 - hn * 1.6]), Color(0.9, 0.93, 1.0))
					draw_line(piv + wdir * 7.0, tip - wdir * 2.0, Color(1, 1, 1, 0.8), 1.0)
				# éclats le long du coup
				for i in 4:
					var aa := lerpf(a0, a_now, 0.25 + i * 0.22)
					var sp := piv + Vector2.from_angle(aa) * (rad + 4.0 + fposmod(i * 7.3, 6.0))
					draw_circle(sp, 1.4 * k + 0.4, Color(col.lightened(0.5), k))

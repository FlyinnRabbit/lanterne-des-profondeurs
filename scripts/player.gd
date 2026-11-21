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
# Estoc repoussant : l'estoc projette les petits ennemis au loin (toutes armes sauf shuriken),
# puis il faut attendre THRUST_PUSH_CD avant le prochain estoc repoussant.
const THRUST_PUSH_CD := 2.0
const THRUST_PUSH_FORCE := 1150.0
var thrust_push_cd := 0.0
var thrust_push := false          # l'estoc en cours repousse
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
var attack_buf := 0.0           # appui sur {attaque} pendant la recharge : le coup part dès qu'elle finit
var plunge_cd := 0.0
var plunge_kill_t := 0.0
var crit_ready := false         # coup critique prêt (après une parade parfaite)
var crit_t := 0.0
var attack_crit := false        # le coup en cours est critique
# Griffes Jumelles : arme à deux mains, chaque attaque = deux coups de griffe séparés
# (main avant, puis main arrière à la moitié du temps de recharge), chacun moitié des dégâts.
var claw_split := false
var claw_kind := ""
var claw_second := -1.0
var claw_hand := 0
var ult_frac := 0.0               # demi-points d'ultime en attente (griffes)
var soul_frac := 0.0              # demi-points d'âme en attente (griffes)
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
# Treuil : le héros est hissé le long de ces points (contrôle rendu à l'arrivée)
var hoist_path: Array = []
var rope = null            # treuil dont on tient la corde (montée / descente contrôlées)
var rope_grab_cd := 0.0    # après avoir lâché : pas de ré-accroche immédiate
var rope_hold_t := 0.0     # depuis combien de temps on grimpe sans s'arrêter (la vitesse monte)
const ROPE_UP := 240.0
const ROPE_DOWN := 330.0
var hoist_t := 0.0
var dead := false
var anim_t := 0.0
var squash := Vector2.ONE
var was_on_floor := true
var ice_t := 0.0          # sur une plaque de glace : on glisse (posé par le piège à chaque image)
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
	if GameState.mode == "duel":
		return false        # duel : pas d'emblèmes, à armes égales
	return GameState.has_charm(id)

# ---------------------------------------------------------------- duel local
# pid 2 : le second joueur, piloté par les actions « p2_… » (seconde manette).
var pid := 0
var duel_weapon := ""
var is_boss := false
var knock := Vector2.ZERO      # recul infligé par l'adversaire (estoc repoussant…)
var knock_resist := 1.0
var stun_t := 0.0
func _act(a: String) -> String:
	return ("p2_" + a) if pid == 2 else a
func _ok(a: String) -> bool:
	return pid != 2 or InputMap.has_action("p2_" + a)
func _ip(a: String) -> bool:
	return _ok(a) and Input.is_action_pressed(_act(a))
func _ijp(a: String) -> bool:
	return _ok(a) and Input.is_action_just_pressed(_act(a))
func _ijr(a: String) -> bool:
	return _ok(a) and Input.is_action_just_released(_act(a))
func _iaxis() -> float:
	return Input.get_axis(_act("move_left"), _act("move_right")) if _ok("move_left") else 0.0
func wid() -> String:
	return duel_weapon if duel_weapon != "" else GameState.weapon()
func wlv() -> int:
	return 2 if duel_weapon != "" else GameState.weapon_level()
func is_harmful() -> bool:
	return false
# touché par l'autre joueur (ses coups passent par la même logique que contre un ennemi)
func take_hit(dmg: int, dir: Vector2) -> void:
	if dead or GameState.mode != "duel":
		return
	var from := global_position - (dir if dir != Vector2.ZERO else Vector2(-facing, 0)) * 30.0
	var other = main.duel_other(self)
	if parry_t > 0.0:
		_on_parry(from, other)
		return
	if invuln_t > 0.0 or dash_t > 0.0:
		return
	take_damage(maxi(1, dmg), from.x)
# l'autre joueur a paré notre coup : on est repoussé et sonné un instant
func parried(d: Vector2) -> void:
	velocity = Vector2(d.x * 420.0, -180.0)
	knock_t = 0.45
	attack_t = 0.0

# niveau de l'emblème porté (0 s'il n'est pas équipé, sinon 1 à 3)
func cl(id: int) -> int:
	return GameState.charm_level(id) if eq(id) else 0

# valeur selon le niveau de l'emblème : v[0] au niveau 1, v[1] au niveau 2, v[2] au niveau 3
func clv(id: int, v: Array, off = 0):
	var l := cl(id)
	return off if l == 0 else v[l - 1]

func run_speed() -> float:
	return RUN_SPEED * float(clv(C.SWIFT_CLOAK, [1.12, 1.18, 1.24], 1.0)) * (0.5 if web_t > 0.0 else 1.0) * (0.0 if grab_t > 0.0 else 1.0)

# Toile de tisseuse : englué, on court deux fois moins vite et on saute moins haut. La ruée arrache la toile.
var web_t := 0.0
var goo_col := Color(0, 0, 0, 0)   # englué par une glue de slime (sinon : toile)
var grab_t := 0.0     # main squelettique : immobilisé (pas de course ni de saut) ; la ruée libère
func grab(secs: float) -> void:
	if dead or sitting or dash_t > 0.0:
		return
	grab_t = maxf(grab_t, secs)
	Audio.sfx("hit", 0.1, -8.0)
# goo : couleur de la glue d'un slime (transparente = toile d'araignée)
func ensnare(secs: float, goo := Color(0, 0, 0, 0)) -> void:
	if dead or sitting:
		return
	if web_t <= 0.0:
		Audio.sfx("spit" if goo.a > 0.0 else "whip", 0.1, -8.0)
	web_t = maxf(web_t, secs)
	goo_col = goo

func dash_cooldown() -> float:
	return DASH_COOLDOWN * float(clv(C.SWIFT_CLOAK, [0.5, 0.42, 0.35], 1.0))

func parry_window() -> float:
	return float(clv(C.MIRROR, [0.35, 0.42, 0.5], PARRY_WINDOW))

func focus_time() -> float:
	var quick := eq(C.QUICK_FOCUS)
	var rest := crouching and eq(C.SHADOW_REST)
	var m := 1.0
	var mq: float = clv(C.QUICK_FOCUS, [0.55, 0.47, 0.4], 1.0)
	var mr: float = clv(C.SHADOW_REST, [0.667, 0.57, 0.5], 1.0)
	if quick and rest:
		m = minf(mq, mr) * 0.9          # les deux : le meilleur bonus + un petit supplément
	elif quick:
		m = mq
	elif rest:
		m = mr
	return maxf(FOCUS_TIME * m, 0.4)

func soul_per_hit() -> int:
	# armes très rapides (griffes) : moins d'âme par coup, pour garder le même rythme de soins
	return roundi((SOUL_PER_HIT + int(clv(C.GREED, [6, 8, 10]))) * float(GameState.d("soul")) * float(weapon().get("soul", 1.0)))

# âme d'une attaque complète, sans arrondi (les griffes la partagent entre leurs deux coups)
func _soul_per_attack() -> float:
	return (SOUL_PER_HIT + int(clv(C.GREED, [6, 8, 10]))) * float(GameState.d("soul")) * float(weapon().get("soul", 1.0))

func ult_per_hit() -> int:
	return roundi((ULT_PER_HIT + int(clv(C.GREED, [4, 5, 6]))) * float(GameState.d("ult")) * ult_mult())

func ult_mult() -> float:
	return float(clv(C.STORM_HEART, [1.25, 1.35, 1.45], 1.0))

func nail_damage() -> int:
	var d := 2 if eq(C.BRUTE) else 1
	# Rage du Blessé : +1 dégât quand il reste peu de masques
	if eq(C.WOUNDED_RAGE) and hp <= int(clv(C.WOUNDED_RAGE, [1, 2, 3])):
		d += 1
	return d   # Force Brute : +1 dégât (le double au départ, plus en profondeur)

func reach() -> float:
	return float(clv(C.LONG_NAIL, [1.4, 1.55, 1.7], 1.0))

# ---- nouveaux emblèmes (21 à 41)
var air_dash2_used := false
var air_jump_used := false
var veil_cd := 0.0
var hazard_cd := 0.0    # après une chute dans les pics : pas de second coup avant de s'être remis
var bark_used := 0
var sap_kills := 0

func focus_cost() -> int:
	return int(clv(C.FRUGAL_LAMP, [27, 24, 20], FOCUS_COST))

func spell_cost() -> int:
	return 28 if cl(C.SOUL_FLAME) >= 3 else SPELL_COST

func charge_time() -> float:
	return CHARGE_TIME * float(clv(C.COMET, [0.6, 0.5, 0.4], 1.0))

# bonus de dégâts propre à l'ennemi touché (Croc du Chasseur)
func foe_bonus(e) -> int:
	if eq(C.HUNTER_FANG) and "hp_max" in e and int(e.hp_max) > 0:
		if float(e.hp) < float(e.hp_max) * float(clv(C.HUNTER_FANG, [0.4, 0.5, 0.6])):
			return 1
	return 0

# Calice de Sève : appelé à chaque ennemi vaincu (hors boss)
func on_kill_charms() -> void:
	if not eq(C.SAP_CHALICE):
		return
	sap_kills += 1
	if sap_kills >= int(clv(C.SAP_CHALICE, [15, 12, 10])):
		sap_kills = 0
		if hp < max_hp:
			hp += 1
			main.spawn_burst(global_position, Color(0.7, 0.9, 0.4), 18, 170.0, -100.0)
			Audio.sfx("heal", 0.0, -4.0)

# À appeler quand l'équipement change
func apply_equipment() -> void:
	max_hp = 5 + int(clv(C.GLASS_HEART, [2, 3, 4])) + GameState.max_hp_bonus()
	if GameState.mode == "duel":
		max_hp = 9
	hp = mini(hp, max_hp)

# arme équipée, avec les bonus de niveau (3 à 5) déjà appliqués
var _wcache_key := ""
var _wcache := {}
func weapon() -> Dictionary:
	var id: String = wid()
	var lv: int = 2 if duel_weapon != "" else GameState.weapon_level(id)
	var key := "%s:%d" % [id, lv]
	if key != _wcache_key:
		var w: Dictionary = Weapons.get_w(id).duplicate()
		var b: Dictionary = Weapons.bonus(id, lv)
		w["dmg"] = int(w["dmg"]) + int(b["dmg"])
		for k in ["w", "h", "v"]:
			w[k] = float(w[k]) * (1.0 + float(b["reach"]))
		w["cd"] = float(w["cd"]) / (1.0 + float(b["speed"]))
		w["crit"] = float(b["crit"])
		_wcache = w
		_wcache_key = key
	return _wcache

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
			"bench_lock_t", "web_t", "grab_t", "veil_cd", "hazard_cd", "ice_t"]:
		set(t, maxf(get(t) - delta, 0.0))
	if knock.length() > 10.0:
		# duel : recul infligé par l'adversaire
		velocity = knock
		knock_t = maxf(knock_t, 0.25)
		knock = Vector2.ZERO
	if attack_t > 0.0 or thrust_t > 0.0 or ult_charge_t > 0.0:
		bench_lock_t = BENCH_LOCK
	if thrust_push_cd > 0.0:
		thrust_push_cd = maxf(thrust_push_cd - delta, 0.0)
		if thrust_push_cd == 0.0:
			# prêt : petit éclat clair autour du héros
			main.spawn_burst(global_position + Vector2(0, -8), Color(0.85, 0.92, 1.0), 6, 70.0, 0.0)
	if claw_second > 0.0:
		claw_second -= delta
		if claw_second <= 0.0 and claw_split and attack_kind == claw_kind:
			claw_hand = 1                       # deuxième griffe
			attack_hit.clear()
			attack_t = maxf(attack_t, ATTACK_TIME * (1.4 if attack_kind in ["finisher", "air_spin"] else 1.0))
			Audio.sfx("slash", 0.22, -5.0)
	parry_t = maxf(parry_t - delta, 0.0)
	parry_cd = maxf(parry_cd - delta, 0.0)
	parry_flash = maxf(parry_flash - delta, 0.0)
	combat_t += delta
	if crouching and eq(C.SHADOW_REST) and soul < int(clv(C.SHADOW_REST, [FOCUS_COST, 50, 66])) and combat_t >= 3.0 and not _enemy_near(320.0):
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
	# en l'air, le corps s'étire avec la vitesse verticale (montée comme chute) ; au sol, il revient
	var rest := Vector2.ONE
	if not is_on_floor() and not sitting and rope == null and dash_t <= 0.0:
		var kv := clampf(absf(velocity.y) / 900.0, 0.0, 1.0)
		rest = Vector2(1.0 - kv * 0.12, 1.0 + kv * 0.16)
	squash = squash.lerp(rest, minf(delta * 12.0, 1.0))
	_anim_feet(delta)
	modulate.a = 0.35 if (invuln_t > 0.0 and fmod(invuln_t, 0.16) < 0.08 and not sitting and hoist_path.is_empty()) else 1.0
	queue_redraw()
	if dead:
		return
	rope_grab_cd = maxf(rope_grab_cd - delta, 0.0)
	if not hoist_path.is_empty():
		_hoist_step(delta)
		return
	if rope != null:
		_rope_step(delta)
		return
	if sitting:
		velocity = Vector2.ZERO
		sit_t += delta
		# Se relever : bouger, ou n'importe quelle action. On accepte une touche simplement
		# enfoncée (après un court délai) : un appui très bref pouvait passer inaperçu quand
		# le jeu tournait lentement, et on restait « collé » au banc.
		var want := absf(_iaxis()) > 0.5
		for a in ["jump", "down", "attack", "dash", "parry"]:
			if _ijp(a) or (sit_t > 0.25 and _ip(a)):
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
			main.ultimate_blast(global_position, self)
			invuln_t = maxf(invuln_t, 0.4)
		return
	if _ijp("ultimate") and knock_t <= 0.0:
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
	if _ijp("parry") and parry_cd <= 0.0 and knock_t <= 0.0:
		parry_t = parry_window()
		parry_cd = PARRY_COOLDOWN

	var dir := _iaxis()
	if absf(dir) < 0.3:
		dir = 0.0
	else:
		dir = signf(dir)
	if _ijp("jump"):
		buffer_t = JUMP_BUFFER
	var on_floor := is_on_floor()
	if on_floor:
		coyote_t = COYOTE
		air_dash_used = false
		air_dash2_used = false
		air_jump_used = false
		air_i = -1
		plunge_used = false
		rise_used = false
		if not was_on_floor:
			squash = Vector2(1.3, 0.7)
			main.spawn_burst(global_position + Vector2(0, SIZE.y / 2), Color(0.6, 0.65, 0.8, 0.6), 6, 80.0, 50.0)
		_update_safe_spot()

	# Concentration (soin) : maintenir L au sol avec 33 d'âme
	if _ip("focus") and on_floor and soul >= focus_cost() and hp < max_hp and knock_t <= 0.0 and not (GameState.curse == "fragile" and GameState.mode == "descent"):
		focus_t += delta
		_set_crouch(crouch_latch if Settings.crouch_toggle else _ip("down"))
		velocity.x = 0.0
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
		if focus_t >= focus_time():
			focus_t = 0.0
			soul -= focus_cost()
			hp += 1
			# Sève Bénie : chance de rendre un masque de plus
			if eq(C.BLESSED_SAP) and hp < max_hp and randf() < float(clv(C.BLESSED_SAP, [0.25, 0.35, 0.5])):
				hp += 1
				main.spawn_burst(global_position, Color(0.55, 0.95, 0.6), 16, 180.0, -120.0)
			GameState.j_add("heals")
			Audio.sfx("heal", 0.0)
			main.spawn_burst(global_position, Color(1, 1, 1), 20, 160.0, -100.0)
		move_and_slide()
		_post_move(on_floor)
		return
	focus_t = 0.0

	# Attaque plongée : en l'air, bas + ruée = piqué vers le sol, onde de choc à l'impact
	if not on_floor and not plunging and not plunge_used and plunge_cd <= 0.0 and _ip("down") and _ijp("dash") and knock_t <= 0.0:
		plunging = true
		plunge_used = true
		plunge_cd = 0.6
		GameState.j_add("plunges")
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
	# Ombre Jumelle : la seconde Ruée en l'air n'attend pas le temps de recharge (0,75 s), sinon
	# on retombait au sol avant de pouvoir la lancer ; il suffit que la première soit finie.
	var twin_ready: bool = not on_floor and air_dash_used and not air_dash2_used and eq(C.TWIN_SHADOW) and dash_t <= 0.0
	if can_dash and _ijp("dash") and (dash_cd <= 0.0 or twin_ready) and (on_floor or not air_dash_used or (eq(C.TWIN_SHADOW) and not air_dash2_used)) and knock_t <= 0.0:
		if dir != 0.0:
			facing = int(dir)
		dash_t = DASH_TIME * float(clv(C.TWIN_SHADOW, [1.0, 1.1, 1.2], 1.0))
		dash_hit.clear()
		if web_t > 0.0 or grab_t > 0.0:
			web_t = 0.0
			grab_t = 0.0
			main.spawn_burst(global_position, Color(0.9, 0.9, 0.95), 10, 140.0)
		GameState.j_add("dashes")
		dash_cd = dash_cooldown()
		Audio.sfx("dash")
		crouch_latch = false      # la ruée relève le héros (mode bascule compris)
		if not on_floor:
			if air_dash_used:
				air_dash2_used = true     # Ombre Jumelle : seconde Ruée en l'air
			air_dash_used = true
		squash = Vector2(1.3, 0.8)
		main.spawn_burst(global_position, Color(0.2, 0.2, 0.3, 0.8), 10, 120.0, 0.0)
	# Estoc : frapper pendant la ruée (ou juste après) = coup perçant en ligne droite
	if _ijp("attack") and (dash_t > 0.0 or post_dash_t > 0.0) and thrust_t <= 0.0 and knock_t <= 0.0:
		_start_attack("thrust", Vector2(facing, 0))
		thrust_t = THRUST_TIME
		thrust_push = thrust_push_cd <= 0.0 and wid() != "shuriken"
		GameState.j_add("thrusts")
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
		if eq(C.PHANTOM_DASH):
			_phantom_dash()
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
		var want_vx := dir * run_speed() * (0.35 if parry_t > 0.0 else 1.0) * (0.3 if crouching else 1.0)
		if ice_t > 0.0 and on_floor:
			# glace : l'élan se garde, on accélère et on freine lentement
			velocity.x = move_toward(velocity.x, want_vx, (380.0 if absf(want_vx) > absf(velocity.x) else 240.0) * delta)
		else:
			velocity.x = want_vx
		if dir != 0.0 and attack_t <= 0.0:
			facing = int(dir)
	# Le piqué se lance en maintenant « bas » : à l'atterrissage on ne s'accroupit pas tant que la
	# touche n'a pas été relâchée (avant : on se retrouvait accroupi, à ramper, avec un coup bas)
	if crouch_block and not _ip("down"):
		crouch_block = false
	if Settings.crouch_toggle:
		if on_floor and _ijp("down"):
			crouch_latch = not crouch_latch
		if not on_floor or _ijp("jump") or dash_t > 0.0:
			crouch_latch = false
		_set_crouch(on_floor and crouch_latch and knock_t <= 0.0)
	else:
		_set_crouch(on_floor and _ip("down") and knock_t <= 0.0 and not crouch_block)

	# Saut
	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	if buffer_t > 0.0 and coyote_t > 0.0 and knock_t <= 0.0 and grab_t <= 0.0:
		velocity.y = JUMP_VELOCITY * (0.8 if web_t > 0.0 else 1.0)
		Audio.sfx("jump", 0.1, -4.0)
		GameState.j_add("jumps")
		buffer_t = 0.0
		coyote_t = 0.0
		squash = Vector2(0.7, 1.3)
	elif buffer_t > 0.0 and not on_floor and eq(C.MOTH_WING) and not air_jump_used and knock_t <= 0.0 and grab_t <= 0.0 and web_t <= 0.0:
		# Aile de Phalène : second saut en l'air
		air_jump_used = true
		velocity.y = JUMP_VELOCITY * float(clv(C.MOTH_WING, [0.75, 0.9, 1.0], 1.0))
		Audio.sfx("jump", 0.1, -2.0)
		buffer_t = 0.0
		squash = Vector2(0.75, 1.25)
		main.spawn_burst(global_position + Vector2(0, SIZE.y / 2.0), Color(0.9, 0.85, 0.7, 0.8), 10, 130.0, 60.0)
	if _ijr("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Attaque : combo de 3 coups (le 3e est un coup final), coup chargé en maintenant.
	# Un appui un peu trop tôt (pendant la recharge) est gardé 0,25 s : enchaîner vite ne perd
	# plus de coup, et le combo (au sol comme en l'air) part au rythme de l'arme.
	attack_buf = maxf(attack_buf - delta, 0.0)
	if _ijp("attack"):
		attack_buf = 0.25
	if attack_buf > 0.0 and attack_cd <= 0.0 and knock_t <= 0.0:
		attack_buf = 0.0
		var adir := Vector2(facing, 0)
		if _ip("up"):
			adir = Vector2.UP
		elif _ip("down") and not on_floor:
			adir = Vector2.DOWN
		if not on_floor and adir.y == 0.0:
			# combo aérien : entaille, entaille montante, puis vrille
			air_i = (air_i + 1) % 3 if combo_t > 0.0 else 0
			_start_attack(["air", "air_rise", "air_spin"][air_i], adir)
			combo_t = attack_cd + COMBO_SLACK
			if air_i == 1 and not rise_used:
				# entaille montante : relance nette vers le haut, même en pleine montée
				rise_used = true
				velocity.y = maxf(minf(velocity.y, 0.0) - 400.0, -780.0)
				squash = Vector2(0.8, 1.2)
				main.spawn_burst(global_position + Vector2(0, SIZE.y / 2.0), Color(1.0, 0.95, 0.8, 0.8), 8, 110.0, 80.0)
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
	if _ip("attack") and attack_t <= 0.0 and knock_t <= 0.0:
		var before := charge_t
		charge_t += delta
		if before < charge_time() and charge_t >= charge_time():
			main.spawn_burst(global_position, Color(1.0, 0.95, 0.75), 10, 120.0, -100.0)
			Audio.sfx("pickup", 0.0, -8.0)
	if _ijr("attack"):
		if charge_t >= charge_time() and knock_t <= 0.0:
			_start_attack("spin", Vector2(facing, 0))
			attack_t = SPIN_TIME
			main.shake(6)
		charge_t = 0.0
	if attack_t > 0.0:
		_do_attack_hits()

	# Sort d'âme : lame d'âme qui traverse les ennemis (coûte 33 d'âme)
	if _ijp("spell") and soul >= spell_cost() and spell_cd <= 0.0 and knock_t <= 0.0:
		soul -= spell_cost()
		spell_cd = 0.45
		GameState.j_add("spells")
		bench_lock_t = BENCH_LOCK
		var crit := _take_crit()
		var sdmg := 3 + (1 if eq(C.BRUTE) else 0) + int(clv(C.SOUL_FLAME, [1, 2, 2]))
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

# couleur de la poussière soulevée : celle du sol du biome
func _dust_col() -> Color:
	var id := String(main.pal.get("id", ""))
	if id == "glace":
		return Color(0.9, 0.95, 1.0)
	if id in ["jungle", "jardins"]:
		return main.pal["moss"].darkened(0.3)
	return main.pal.get("rock_hi", Color(0.75, 0.72, 0.68)).lightened(0.25)

# demi-tour et départ de course au sol : petit écrasement et bouffée de poussière aux pieds
var _last_facing := 1
var _was_running := false
var _feet_cd := 0.0
var _step_t := 0.0
func _step_mat() -> String:
	match String(main.pal.get("id", "")):
		"jungle", "jardins": return "grass"
		"glace": return "snow"
		"desert": return "sand"
		"cristal": return "crystal"
		"bibliotheque": return "wood"
		"ruche": return "soft"
	return "stone"
func _anim_feet(delta: float) -> void:
	_feet_cd -= delta
	var on := is_on_floor() and not sitting and rope == null
	var running := on and absf(velocity.x) > 60.0
	if on and facing != _last_facing and absf(velocity.x) > 60.0 and _feet_cd <= 0.0:
		squash = Vector2(0.86, 1.1)
		main.spawn_fx("dust", global_position + Vector2(-facing * 6, SIZE.y / 2.0), _dust_col())
		_feet_cd = 0.25
	elif running and not _was_running and _feet_cd <= 0.0:
		squash = Vector2(1.1, 0.92)
		main.spawn_fx("dust", global_position + Vector2(-facing * 10, SIZE.y / 2.0), _dust_col())
		_feet_cd = 0.25
	_last_facing = facing
	_was_running = running
	# pas : le rythme suit la vitesse, le son la matière du sol
	if running:
		_step_t -= delta * absf(velocity.x) / RUN_SPEED
		if _step_t <= 0.0:
			_step_t = 0.27
			Audio.step(_step_mat())
	else:
		_step_t = 0.05

func _post_move(prev_on_floor: bool) -> void:
	was_on_floor = is_on_floor()
	if not prev_on_floor and was_on_floor and last_vy > 240.0:
		# atterrissage : écrasement et poussière à la mesure de la chute
		var kl := clampf((last_vy - 240.0) / 700.0, 0.0, 1.0)
		squash = Vector2(1.08 + 0.3 * kl, 0.92 - 0.3 * kl)
		Audio.step(_step_mat(), -16.0 + 8.0 * kl)
		if last_vy > 420.0:
			main.spawn_fx("dust", global_position + Vector2(0, SIZE.y / 2.0), _dust_col())
		if last_vy > 760.0:
			main.biome_debris(global_position + Vector2(0, SIZE.y / 2.0), 6, 150.0)
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
	if main.is_solid_at(l) and main.is_solid_at(r) and not _near_spikes(global_position, 24.0):
		last_safe = global_position

# le héros posé en pos serait-il dans (ou tout près de) des pics ?
func _near_spikes(pos: Vector2, margin: float) -> bool:
	var rr := Rect2(pos - SIZE / 2.0, SIZE).grow(margin)
	for s in main.spikes:
		if rr.intersects(s):
			return true
	return false

# Utilise le coup critique s'il est prêt
func _take_crit() -> bool:
	if crit_ready:
		crit_ready = false
		main.spawn_burst(global_position + Vector2(facing * 18, -4), Color(1.0, 0.8, 0.35), 14, 220.0, 0.0)
		return true
	# chance de critique de l'arme (niveaux 3 à 5 selon l'arme)
	var cc := float(weapon().get("crit", 0.0)) + float(clv(C.HAWK_EYE, [0.08, 0.12, 0.16], 0.0))
	if cc > 0.0 and randf() < cc:
		main.spawn_burst(global_position + Vector2(facing * 18, -4), Color(1.0, 0.8, 0.35), 8, 160.0, 0.0)
		return true
	return false

func _start_attack(kind: String, adir: Vector2) -> void:
	var wpn := weapon()
	attack_kind = kind
	attack_dir = adir
	attack_cd = ATTACK_COOLDOWN * (1.3 if kind == "finisher" else 1.0) * float(wpn["cd"]) * float(clv(C.BRUTE, [1.2, 1.12, 1.05], 1.0))
	attack_t = ATTACK_TIME * (1.4 if kind in ["finisher", "air_spin"] else 1.0)
	attack_hit.clear()
	attack_crit = _take_crit()
	claw_hand = 0
	claw_split = wid() == "griffes"
	claw_kind = kind
	claw_second = attack_cd * 0.5 if claw_split else -1.0
	match wid():
		"griffes": Audio.sfx("slash", 0.18, -3.0)
		"fouet": Audio.sfx("whip", 0.1, -3.0)
		"marteau": Audio.sfx("hammer", 0.08, -2.0)
		"shuriken": Audio.sfx("star", 0.15, -4.0)
		"faux": Audio.sfx("whip", 0.12, -1.0)
		"baton": Audio.sfx("hammer", 0.2, -9.0)
		_: Audio.sfx("slash", 0.12, -2.0 if kind == "slash" else 1.0)
	# bâton : accroupi, l'attaque est un saut à la perche
	if wid() == "baton" and kind == "low" and is_on_floor():
		velocity.y = JUMP_VELOCITY * 0.95
		_set_crouch(false)
		main.spawn_burst(global_position + Vector2(facing * 26.0, SIZE.y / 2.0), Color(0.8, 0.7, 0.5), 8, 140.0)
	if attack_crit:
		Audio.sfx("crit", 0.05, -1.0)
	if wpn["ranged"]:
		_throw_stars(kind, adir)
	elif kind == "finisher" and wlv() >= 2:
		match wid():
			"aiguille":
				main.spawn_projectile(global_position + Vector2(facing * 30, -4), Vector2(facing * 560.0, 0),
					{"kind": "slashwave", "hostile": false, "radius": 12.0, "life": 0.32, "pierce": true, "damage": nail_damage(), "crit": false})
			"faux":
				main.spawn_projectile(global_position + Vector2(facing * 20, -6), Vector2(facing * 420.0, 0),
					{"kind": "ghostscythe", "hostile": false, "radius": 16.0, "life": 1.4, "pierce": true, "boomerang": true, "damage": nail_damage(), "crit": false})
			"baton":
				# l'onde naît au bout du coup, mais jamais derrière un mur (avant : un mur fin
				# entre le héros et ce point laissait l'onde partir de l'autre côté)
				var wy := global_position.y + SIZE.y / 2.0 - 16.0
				var wd := minf(70.0, SIZE.x / 2.0 + _reach_h(wy, 70.0) - 6.0)
				var feet2 := global_position + Vector2(facing * wd, SIZE.y / 2.0 - 4.0)
				if is_on_floor() and not main.is_solid_at(feet2 + Vector2(0, -12)):
					main.spawn_projectile(feet2, Vector2(facing * 420.0, 0), {"kind": "wave", "hostile": false, "damage": nail_damage() + 1, "life": 0.6})
				main.shake(7)
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
			"pierce": big, "damage": dmg if (star_crit or not attack_crit) else _base_damage(), "crit": star_crit, "boomerang": wlv() >= 2, "volley": volley})
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
		"plunge":
			d += 1 + int(clv(C.ANVIL_FALL, [1, 1, 2]))
		"finisher", "thrust", "air_spin":
			d += 1
			if attack_kind == "finisher":
				d += int(clv(C.BLADE_DANCE, [1, 1, 2]))
		"spin":
			d = d * 2 + 1
	return crit_damage(d) if attack_crit else d

# Critique : ×1,5 arrondi au-dessus, et toujours au moins +1
func crit_damage(d: int) -> int:
	return maxi(d + 1, ceili(d * float(clv(C.OBSIDIAN_TIP, [2.0, 2.25, 2.5], CRIT_MULT))))

func attack_rect() -> Rect2:
	var p := global_position
	var wpn := weapon()
	if wpn["ranged"]:
		return Rect2(p, Vector2.ZERO)      # les shurikens touchent eux-mêmes
	if attack_kind == "spin":
		var rs := SPIN_REACH * reach() * maxf(1.0, float(wpn["w"]) * 0.6)
		return Rect2(p - Vector2(rs, rs * 0.8), Vector2(rs * 2.0, rs * 1.6))
	# faux : le coup final est un tourbillon tout autour du héros
	if attack_kind == "finisher" and wid() == "faux":
		var rf := 74.0 * reach()
		return Rect2(p - Vector2(rf, rf * 0.85), Vector2(rf * 2.0, rf * 1.6))
	# bâton niv. 2 : frappe géante, plus large et plus haute
	if attack_kind == "finisher" and wid() == "baton" and wlv() >= 2:
		var gw := _reach_h(p.y - 4.0, 150.0 * reach())
		var gx := p.x if facing > 0 else p.x - gw
		return Rect2(Vector2(gx, p.y - 70.0), Vector2(gw, 94.0))
	if attack_kind == "air_spin":
		var ra := 62.0 * reach()
		return Rect2(p - Vector2(ra, ra), Vector2(ra * 2.0, ra * 2.0))
	if attack_kind == "low":
		var lw := 70.0 * reach() * float(wpn["w"])
		if wid() == "baton":
			lw = _reach_h(p.y + 10.0, lw)
		var lx := p.x if facing > 0 else p.x - lw
		return Rect2(Vector2(lx, p.y + 2), Vector2(lw, 18))
	if attack_kind == "thrust":
		var tw := 120.0 * reach()
		var tx := p.x if facing > 0 else p.x - tw
		return Rect2(Vector2(tx, p.y - 16), Vector2(tw, 26))
	if attack_dir == Vector2.UP:
		var hu := 62.0 * reach() * float(wpn["v"])
		if wid() == "fouet":
			hu = _whip_reach_v(-1.0, hu)
		elif wid() == "baton":
			hu = _reach_v(-1.0, hu, 0.0)
		return Rect2(p + Vector2(-32, -SIZE.y / 2.0 + 4 - hu), Vector2(64, hu))
	if attack_dir == Vector2.DOWN:
		var hd := 62.0 * reach() * float(wpn["v"])
		if wid() == "fouet":
			hd = _whip_reach_v(1.0, hd)
		elif wid() == "baton":
			hd = _reach_v(1.0, hd, 0.0)
		return Rect2(p + Vector2(-32, SIZE.y / 2.0 - 6), Vector2(64, hd))
	var w := 70.0 * reach() * (1.3 if attack_kind == "finisher" else 1.0) * float(wpn["w"])
	var hgt := 54.0 * (1.25 if attack_kind == "finisher" else 1.0) * float(wpn["h"])
	if attack_kind == "air_rise":
		hgt *= 1.4
	# fouet et bâton : l'arme s'arrête au premier mur (pas de coup à travers la roche)
	if wid() in ["fouet", "baton"]:
		w = _reach_h(p.y - 4.0, w)
	var x := p.x + SIZE.x / 2.0 - 4.0 if facing > 0 else p.x - SIZE.x / 2.0 - w + 4.0
	return Rect2(Vector2(x, p.y - hgt * 0.55), Vector2(w, hgt))

# fouet vertical : un peu plus court qu'à l'horizontale, et la liane s'arrête au plafond ou au sol
func _whip_reach_v(dir: float, full: float) -> float:
	return _reach_v(dir, full * 0.8)

# portée verticale coupée au premier bloc de roche (plafond ou sol)
func _reach_v(dir: float, maxd: float, mind: float = 14.0) -> float:
	var y0 := global_position.y + dir * (SIZE.y / 2.0 - 4.0)
	var d := 0.0
	while d < maxd:
		if main.is_solid_at(Vector2(global_position.x, y0 + dir * d)):
			break
		d += 2.0
	return maxf(minf(d, maxd), mind)

# portée horizontale (devant soi, à la hauteur y) coupée au premier mur
func _reach_h(y: float, maxd: float) -> float:
	var x0 := global_position.x
	var d := 0.0
	while d < maxd:
		if main.is_solid_at(Vector2(x0 + facing * (SIZE.x / 2.0 + d), y)):
			break
		d += 4.0
	return maxf(minf(d, maxd), 24.0)

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
		if e == self:
			continue
		if not is_instance_valid(e) or attack_hit.has(e):
			continue
		if e.get_rect().intersects(r):
			# pas de coup à travers la roche (murs fins, sols, plafonds) : on vise le point de
			# l'ennemi le plus proche du héros, pour ne pas bloquer un gros ennemi à moitié caché
			var er: Rect2 = e.get_rect()
			var tgt := Vector2(clampf(global_position.x, er.position.x, er.end.x), clampf(global_position.y - 4.0, er.position.y, er.end.y))
			if main.wall_between(global_position + Vector2(0, -4), tgt):
				continue
			# le boss ne se touche que depuis l'intérieur de son arène
			if e.is_boss and main.entry_gate and is_instance_valid(main.entry_gate) and not main.in_arena(global_position):
				continue
			attack_hit[e] = true
			var kdir := attack_dir
			if attack_kind in ["spin", "air_spin"]:
				kdir = (e.global_position - global_position).normalized()
			if attack_crit:
				last_crit_t = 0.2
			var wpn := weapon()
			var kv: Vector2 = kdir * (1.6 if attack_kind == "finisher" else 1.0) * float(wpn["knock"])
			var split := claw_split and attack_kind == claw_kind
			var second := split and claw_hand == 1
			if e.get_script() != main.DummyScript:
				GameState.j_weapon_hit()
			if split:
				# coup puissant des griffes : 1 par griffe (2 au total), coup normal 0,6 par griffe ;
				# la deuxième griffe ne repousse presque pas : sinon l'ennemi, repoussé 8 fois par
				# seconde, ne pouvait plus jamais attaquer (blocage permanent)
				var per: float = 0.5 if attack_kind in ["finisher", "thrust", "air_spin", "spin", "plunge"] else 0.6
				_claw_hit(e, (hit_damage() + foe_bonus(e)) * per, kv * (0.25 if second else 1.0))
			else:
				e.take_hit(hit_damage() + foe_bonus(e), kv)
			# Givre Mordant : chance de geler brièvement l'ennemi
			if eq(C.FROST_BITE) and is_instance_valid(e) and not e.dead and not e.is_boss and randf() < float(clv(C.FROST_BITE, [0.15, 0.2, 0.25])):
				e.stun_t = maxf(e.stun_t, 0.6)
				main.spawn_burst(e.global_position, Color(0.7, 0.92, 1.0), 12, 120.0, 0.0)
			# Danse des Lames : le coup final rend de l'âme
			if attack_kind == "finisher" and eq(C.BLADE_DANCE) and not second:
				soul = mini(soul + int(clv(C.BLADE_DANCE, [4, 6, 8])), SOUL_MAX)
			# estoc repoussant : projette l'ennemi au loin (pas les boss), une fois toutes les 2 s
			if attack_kind == "thrust" and thrust_push and is_instance_valid(e) and not e.dead and not e.is_boss:
				e.knock = Vector2(facing, -0.35).normalized() * THRUST_PUSH_FORCE * float(e.knock_resist)
				e.stun_t = maxf(e.stun_t, 0.45)
				thrust_push_cd = THRUST_PUSH_CD
				main.thrust_shock(e.global_position)
				GameState.j_add("pushes")
			# saignée : 1 dégât une seconde plus tard (pas de cumul sur le même ennemi), avec une chance
			# par coup : 20 % avec les Griffes niv. 2, +30 % avec le Croc Sanglant (toutes armes)
			var bc := bleed_chance()
			if bc > 0.0 and is_instance_valid(e) and not e.dead and not e.has_meta("bleeding") and randf() < bc:
				_bleed(e)
			if float(wpn["stagger"]) > 0.0 and is_instance_valid(e) and not e.is_boss:
				e.stun_t = maxf(e.stun_t, float(wpn["stagger"]))
			# fouet niv. 2 : attire les petits ennemis
			if wid() == "fouet" and wlv() >= 2 and is_instance_valid(e) and not e.is_boss and not e.dead:
				# attire jusqu'à une distance de frappe (pas au contact) et étourdit brièvement :
				# l'ennemi attiré est inoffensif le temps d'arriver
				var pull: Vector2 = global_position - e.global_position
				var gap := pull.length() - 70.0
				if gap > 10.0:
					e.knock = pull.normalized() * minf(sqrt(4400.0 * gap), 900.0)   # s'arrête à ~70 px
					e.stun_t = maxf(e.stun_t, 0.7)
			Audio.sfx("hit")
			if split:
				# chaque griffe rapporte la moitié de l'âme d'une attaque, au demi-point près
				soul_frac += _soul_per_attack() * 0.5
				var whole_s := int(soul_frac)
				soul_frac -= whole_s
				soul = mini(soul + whole_s, SOUL_MAX)
			else:
				soul = mini(soul + soul_per_hit(), SOUL_MAX)
			if split:
				# demi-gain par griffe, sans perdre la moitié d'un point quand le gain est impair
				ult_frac += ult_per_hit() * 0.5
				var whole_u := int(ult_frac)
				ult_frac -= whole_u
				ult = mini(ult + whole_u, ULT_MAX)
			else:
				ult = mini(ult + ult_per_hit(), ULT_MAX)
			if not second:
				# poids de l'arme : le marteau secoue, les griffes et les étoiles à peine
				var heft: float = {"marteau": 1.6, "baton": 1.3, "faux": 1.2, "fouet": 0.9, "griffes": 0.7, "shuriken": 0.6}.get(wid(), 1.0)
				main.shake((4.0 if attack_kind == "slash" else 8.0) * heft)
				main.hit_stop((0.04 if attack_kind == "slash" else 0.07) * (0.6 + heft * 0.4))
				if is_instance_valid(e):
					main.biome_debris(e.global_position, int(3 + heft * 3), 140.0 * heft)
			if attack_kind in ["spin", "thrust", "air_spin", "air_rise"] or second:
				pass   # pas de recul : ces coups traversent (ni pour la 2e griffe : un seul rebond par attaque)
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
	GameState.j_add("pogos")
	velocity.y = POGO_VELOCITY
	air_dash_used = false
	air_dash2_used = false
	air_jump_used = false
	dash_cd = 0.0
	squash = Vector2(0.8, 1.2)
	if eq(C.REBOUND):
		# Lame Rebond : rebond plus haut et un peu d'âme (selon le niveau)
		velocity.y = POGO_VELOCITY * float(clv(C.REBOUND, [1.25, 1.35, 1.45], 1.0))
		soul = mini(soul + int(clv(C.REBOUND, [6, 9, 12])), SOUL_MAX)

func _check_hazards() -> void:
	if dead:
		return
	var r := get_rect().grow(-3)
	if hazard_cd <= 0.0:
		for s in main.spikes:
			if r.intersects(s):
				_hazard_respawn()
				return
	# Esquive : pendant la ruée on traverse ennemis et projectiles
	if dash_t > 0.0:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
		if is_instance_valid(e) and e.is_harmful() and r.intersects(e.get_rect()):
			if not e.is_boss and main.wall_between(global_position, e.global_position):
				continue      # pas de coup à travers un mur (estoc du lancier, charge…)
			if not e.is_boss and invuln_t <= 0.0 and parry_t <= 0.0 and not sitting:
				GameState.j_mob_hurt(String(e.get_script().resource_path.get_file()).get_basename())
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
	# Semelles d'Écorce : les premiers coups de piège du niveau sont ignorés
	if eq(C.BARK_SOLES) and _from_trap(source) and bark_used < int(clv(C.BARK_SOLES, [1, 2, 3])):
		bark_used += 1
		invuln_t = 0.8
		main.spawn_burst(global_position, Color(0.6, 0.45, 0.3), 14, 150.0)
		Audio.sfx("parry", 0.1, -6.0)
		return false
	# Voile d'Âme : l'âme absorbe le coup
	var vcost := int(clv(C.SOUL_VEIL, [33, 28, 22], 33))
	if eq(C.SOUL_VEIL) and veil_cd <= 0.0 and soul >= vcost:
		soul -= vcost
		veil_cd = float(clv(C.SOUL_VEIL, [8.0, 6.0, 5.0], 8.0))
		invuln_t = INVULN_TIME * 0.6
		main.spawn_burst(global_position, Color(0.75, 0.85, 0.95), 24, 200.0)
		main.shake(6)
		Audio.sfx("parry", 0.05, -2.0)
		return false
	take_damage(int(GameState.d("dmg")), from_pos.x)
	return false

func _on_parry(from_pos: Vector2, source) -> void:
	# parade parfaite : le prochain coup sera critique (×1,5) et l'ennemi est étourdi plus longtemps
	parry_perfect_now = parry_window() - parry_t <= PERFECT_PARRY
	if not _from_trap(source):
		Achievements.on_parry()
		GameState.j_add("parries")
	if parry_perfect_now:
		crit_ready = true
		crit_t = CRIT_TIME
		perfect_t = 1.2
		Audio.sfx("crit_ready", 0.0, 0.0)
		if not _from_trap(source):
			Achievements.on_perfect_parry()
			GameState.j_add("perfect")
			GameState.j_perfect(true)
		if eq(C.ECHO):
			var ed := signf(from_pos.x - global_position.x)
			if ed == 0.0:
				ed = float(facing)
			main.spawn_projectile(global_position + Vector2(ed * 20, -4), Vector2(ed * 620.0, 0),
				{"kind": "soulblade", "hostile": false, "radius": 14.0, "life": 1.1, "pierce": true, "damage": int(clv(C.ECHO, [3, 4, 5]))})
	parry_t = 0.0
	parry_cd = 0.12
	parry_flash = 0.25
	invuln_t = maxf(invuln_t, 0.4)
	if not _from_trap(source):
		ult = mini(ult + roundi(ULT_PER_PARRY * float(GameState.d("ult")) * ult_mult()), ULT_MAX)
		# Pendule : la parade recharge la Ruée et rend de l'âme
		if eq(C.PENDULUM):
			dash_cd = 0.0
			air_dash_used = false
			air_dash2_used = false
			soul = mini(soul + int(clv(C.PENDULUM, [5, 8, 12])), SOUL_MAX)
		soul = mini(soul + soul_per_hit(), SOUL_MAX)
		combat_t = 0.0
	var d := (from_pos - global_position).normalized()
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	if source and source.has_method("parried"):
		source.parried(d)
	# Parade Tranchante : l'attaquant (pas un projectile ni un piège) prend 2 dégâts
	if eq(C.RIPOSTE) and source and is_instance_valid(source) and source.is_in_group("enemies") and source.has_method("take_hit") and not source.dead:
		source.take_hit(int(clv(C.RIPOSTE, [2, 3, 4])), d)
		main.spawn_burst(global_position + d * 22.0, Color(1.0, 0.85, 0.5), 10, 160.0)
	velocity.x = -signf(d.x) * 200.0
	recoil_t = 0.1
	recoil_vx = velocity.x
	main.on_parry(global_position + d * 18.0)

# Arme tenue en main (dessinée dans le repère du personnage, pieds en 0, tourné à droite)
# traînée de coup « peinte » : croissant effilé, bord extérieur vif qui s'estompe vers l'intérieur
func _area(q: PackedVector2Array) -> float:
	var a := 0.0
	for i in q.size():
		a += q[i].cross(q[(i + 1) % q.size()])
	return a * 0.5

func _smear(piv: Vector2, rad: float, a0: float, a1: float, thick: float, col: Color, k: float, pale := true) -> void:
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
	# en tranches (quadrilatères) : un seul polygone fin échouait parfois à se trianguler
	var c_out := col.lightened(0.6) if pale else col
	for i in n:
		var u0 := float(i) / n
		var u1 := float(i + 1) / n
		var q := PackedVector2Array([outer[i], outer[i + 1], inner[i + 1], inner[i]])
		if q[0].distance_to(q[3]) < 0.05 and q[1].distance_to(q[2]) < 0.05:
			continue
		if q[0].distance_to(q[3]) < 0.05:
			q = PackedVector2Array([outer[i], outer[i + 1], inner[i + 1]])
		elif q[1].distance_to(q[2]) < 0.05:
			q = PackedVector2Array([outer[i], outer[i + 1], inner[i]])
		if absf(_area(q)) < 0.4:
			continue
		var cols := PackedColorArray()
		for j in q.size():
			var v: Vector2 = q[j]
			var on_out := v == outer[i] or v == outer[i + 1]
			var uu := u0 if (v == outer[i] or v == inner[i]) else u1
			cols.append(Color(c_out, (0.45 + 0.55 * uu) * k) if on_out else Color(col.darkened(0.1), 0.18 * k))
		draw_polygon(q, cols)
	draw_polyline(outer, Color(1, 1, 1, 0.7 * k) if pale else Color(col.lightened(0.35), 0.8 * k), 1.4 if pale else 1.0)

# ---------------------------------------------------------------- faux et bâton
const SCYTHE_HAFT := Color(0.28, 0.22, 0.2)
const SCYTHE_BLADE := Color(0.78, 0.95, 0.9)
const STAFF_RED := Color(0.34, 0.24, 0.16)   # bois
const STAFF_GOLD := Color(0.62, 0.36, 0.24)  # cuivre

# lame de faux : croissant effilé, du talon (root) dans la direction d, courbé du côté n
func _scythe_blade(root: Vector2, d: Vector2, n: Vector2, size: float, col: Color) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 9:
		var u := i / 8.0
		var curve := sin(u * PI * 0.5)
		outer.append(root + d * (u * size) + n * (curve * size * 0.55 - u * u * size * 0.15) + n * 3.0 * (1.0 - u))
		inner.append(root + d * (u * size * 0.92) + n * (curve * size * 0.38 - u * u * size * 0.1))
	# en quadrilatères : un croissant concave d'un seul tenant se triangule mal
	for i in 8:
		var q := PackedVector2Array([outer[i], outer[i + 1], inner[i + 1], inner[i]])
		if absf((q[1] - q[0]).cross(q[3] - q[0])) + absf((q[2] - q[1]).cross(q[3] - q[1])) < 0.5:
			continue
		draw_colored_polygon(q, col)
	draw_line(root, root + n * 3.0, col.darkened(0.3), 3.0)
	draw_polyline(outer, Color(1, 1, 1, 0.8), 1.2)

# bâton : tige de bois, embouts et cerclages de cuivre
func _staff(a: Vector2, b: Vector2, w: float) -> void:
	var d := (b - a).normalized()
	draw_line(a, b, Color(0.16, 0.1, 0.06), w + 1.6)
	draw_line(a, b, STAFF_RED, w)
	draw_line(a + d.orthogonal() * w * 0.25, b + d.orthogonal() * w * 0.25, STAFF_RED.lightened(0.18), maxf(w * 0.3, 0.8))
	var cap := minf(9.0, (b - a).length() * 0.18)
	for e in [[a, d], [b, -d]]:
		var p0: Vector2 = e[0]
		var dd: Vector2 = e[1]
		draw_line(p0, p0 + dd * cap, STAFF_GOLD, w + 1.0)
		draw_line(p0 + dd * (cap + 1.5), p0 + dd * (cap + 3.0), STAFF_GOLD.darkened(0.15), w + 0.6)
		draw_circle(p0, (w + 1.0) * 0.5, STAFF_GOLD.lightened(0.2))

func _draw_scythe_attack(r: Rect2, c: Vector2) -> void:
	var fin := attack_kind == "finisher"
	var k := clampf(attack_t / (ATTACK_TIME * (1.4 if fin else 1.0)), 0.0, 1.0)
	var col := Color(1.0, 0.6, 0.25) if attack_crit else (Color(0.85, 1.0, 0.95) if fin else Color(0.55, 0.95, 0.85))
	var prog := 1.0 - k
	var ease := 1.0 - pow(1.0 - prog, 3.0)
	if fin:
		# tourbillon : la faux fait un tour complet, traînée en anneau
		var rot := ease * TAU * float(facing)
		var rad: float = r.size.x * 0.45
		_smear(Vector2(0, -6), rad, -PI / 2.0, -PI / 2.0 + rot, 16.0, col, k, false)
		_smear(Vector2(0, -6), rad - 12.0, -PI / 2.0, -PI / 2.0 + rot * 0.85, 7.0, Color(1, 1, 1), k * 0.6)
		var wd := Vector2.from_angle(-PI / 2.0 + rot)
		draw_line(Vector2(0, -6) - wd * 10.0, Vector2(0, -6) + wd * (rad - 6.0), SCYTHE_HAFT, 3.0)
		_scythe_blade(Vector2(0, -6) + wd * (rad - 6.0), wd.orthogonal() * float(facing), -wd, 34.0, SCYTHE_BLADE)
		DU.glow(self, Vector2(0, -6), rad * (1.1 - k * 0.3), col, 0.22 * k)
		return
	# fauchage : grand arc de haut en bas devant soi (ou vertical pour les coups haut/bas)
	var ang := attack_dir.angle()
	var piv := Vector2(0, -6)
	var rad2: float = (46.0 if attack_dir.y == 0.0 else 40.0) * reach()
	var sweep: float = 1.7 * (float(facing) if attack_dir.y != 0.0 else 1.0)
	var a0 := ang - sweep
	var a_now := lerpf(a0, ang + sweep * 0.8, minf(ease * 1.15, 1.0))
	_smear(piv, rad2, a0, a_now, 18.0, col, k, false)
	_smear(piv, rad2 - 10.0, a0 + 0.2 * signf(sweep), a_now, 6.0, Color(1, 1, 1), k * 0.5)
	var wd2 := Vector2.from_angle(a_now)
	draw_line(piv - wd2 * 8.0, piv + wd2 * rad2, SCYTHE_HAFT, 3.0)
	_scythe_blade(piv + wd2 * rad2, wd2.orthogonal() * signf(sweep), -wd2, 32.0, SCYTHE_BLADE)

func _draw_staff_attack(r: Rect2, c: Vector2) -> void:
	var fin := attack_kind == "finisher"
	var k := clampf(attack_t / (ATTACK_TIME * (1.4 if fin else 1.0)), 0.0, 1.0)
	var prog := 1.0 - k
	var col := Color(1.0, 0.6, 0.25) if attack_crit else STAFF_GOLD
	if fin and wlv() >= 2:
		# frappe géante : le bâton grandit et s'abat devant soi
		var e := 1.0 - pow(1.0 - minf(prog * 1.6, 1.0), 3.0)
		var a := lerpf(-PI / 2.0 - 0.3, 0.05, e)
		var dirv := Vector2(cos(a) * facing, sin(a))
		var length: float = r.size.x * 0.95
		_smear(Vector2(0, -6), length * 0.9, (-PI / 2.0 - 0.3) if facing > 0 else (-PI / 2.0 + 0.3), dirv.angle(), 22.0, col, k * 0.8)
		_staff(Vector2(0, -6) - dirv * 8.0, Vector2(0, -6) + dirv * length, 6.0)
		if e >= 1.0:
			DU.glow(self, Vector2(facing * length * 0.8, SIZE.y / 2.0), 40.0, col, 0.5 * k)
		return
	if fin:
		# finisher : moulinet au-dessus de la tête qui s'abat
		var a0 := -PI * 0.9
		var a1 := 0.15
		var e2 := 1.0 - pow(1.0 - prog, 3.0)
		var a_now := lerpf(a0, a1, e2)
		var dv := Vector2(cos(a_now) * facing, sin(a_now))
		var L: float = r.size.x * 0.9
		_smear(Vector2(0, -6), L * 0.85, a0 if facing > 0 else PI - a0, dv.angle(), 16.0, col, k)
		_staff(Vector2(0, -6) - dv * 10.0, Vector2(0, -6) + dv * L, 4.5)
		return
	# estoc : le bâton jaillit jusqu'au bout de la zone, puis revient
	var ext := sin(minf(prog * 1.3, 1.0) * PI * 0.5) * (1.0 - maxf(prog - 0.7, 0.0) / 0.3 * 0.6)
	var tip: Vector2
	if attack_dir.y != 0.0:
		var vlen: float = r.size.y
		tip = Vector2(0, attack_dir.y * vlen * ext + (-SIZE.y * 0.3 if attack_dir.y < 0 else SIZE.y * 0.3))
	else:
		var hl: float = r.size.x
		tip = Vector2(facing * (SIZE.x / 2.0 + hl * ext), c.y)
	var back := -tip.normalized() * 14.0
	_staff(back, tip, 4.0)
	for i in 3:
		var u := 0.25 + i * 0.25
		draw_line(tip * u + tip.orthogonal().normalized() * (4.0 - i * 3.0), tip * (u - 0.18) + tip.orthogonal().normalized() * (4.0 - i * 3.0), Color(col, 0.5 * k), 1.5)
	DU.glow(self, tip, 10.0, col, 0.35 * k)

func _draw_held(wid: String, bob: float) -> void:
	match wid:
		"faux":
			# faux portée dans le dos : manche en diagonale, lame au-dessus de l'épaule
			var a := Vector2(-12, 10 + bob)
			var b := Vector2(-2, -30 + bob)
			draw_line(a, b, SCYTHE_HAFT, 2.8)
			draw_line(a, b, SCYTHE_HAFT.lightened(0.25), 1.0)
			draw_line(b + Vector2(-2, 1), b + Vector2(2, -1), Color(0.6, 0.6, 0.65), 2.4)
			_scythe_blade(b, Vector2(1, 0.15).normalized(), Vector2(0, 1), 24.0, SCYTHE_BLADE)
		"baton":
			# bâton en travers du dos
			_staff(Vector2(-13, 10 + bob), Vector2(9, -30 + bob), 2.8)
		"griffes":
			# une griffe à chaque main : trois lames courbes sur un gantelet, violet pâle.
			# Main arrière d'abord (plus sombre, lames vers l'arrière), puis main avant.
			for hand in [-1, 1]:
				var g := Vector2(11 * hand, -8 + bob + (1.0 if hand < 0 else 0.0))
				var dk := 0.0 if hand > 0 else 0.25
				DU.box(self, Rect2(g + Vector2(-4 if hand > 0 else -3, -3), Vector2(7, 6)), Color(0.35, 0.28, 0.4).darkened(dk))
				for i in 3:
					var o := Vector2(3 * hand, -3 + i * 3)
					var pts := PackedVector2Array([g + o, g + o + Vector2(5 * hand, -2), g + o + Vector2(9 * hand, 1), g + o + Vector2(4 * hand, 1)])
					DU.flat(self, pts, Color(0.85, 0.78, 0.98).darkened(dk))
					draw_line(g + o + Vector2(1 * hand, 0), g + o + Vector2(8 * hand, 0.5), Color(1, 1, 1, 0.6 - dk), 0.8)
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
		if e == self:
			continue
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
				soul = mini(soul + int(clv(C.METEOR, [0, 10, 20])), SOUL_MAX)
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
		if e == self:
			continue
		if is_instance_valid(e) and e.global_position.distance_to(feet) < float(clv(C.ANVIL_FALL, [142.0, 165.0, 190.0], 95.0)):
			if attack_crit:
				last_crit_t = 0.2
			e.take_hit(hit_damage(), (e.global_position - feet).normalized())
	for d in [-1.0, 1.0]:
		main.spawn_projectile(feet + Vector2(d * 20.0, -4.0), Vector2(d * 360.0, 0), {"kind": "wave", "hostile": false, "damage": 1, "life": 0.9 if eq(C.ANVIL_FALL) else 0.6})
	attack_crit = false

# Dernier Souffle : un coup fatal laisse à 1 masque, une fois par niveau (renvoie true si sauvé)
var last_breath_used := false
func _last_breath() -> bool:
	if not eq(C.LAST_BREATH) or last_breath_used:
		return false
	last_breath_used = true
	hp = mini(int(clv(C.LAST_BREATH, [1, 2, 3], 1)), max_hp)
	invuln_t = maxf(invuln_t, 1.6)
	main.spawn_burst(global_position, Color(1.0, 0.45, 0.45), 40, 300.0)
	main.shake(14)
	main.show_message("Dernier Souffle !", 2.0)
	Audio.sfx("crit_ready", 0.0, 2.0)
	return true

# Ruée Spectrale : chaque ennemi traversé pendant une Ruée prend 1 dégât (une fois par Ruée)
var dash_hit := {}
func _phantom_dash() -> void:
	var r := get_rect().grow(6.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
		if is_instance_valid(e) and not e.dead and not dash_hit.has(e) and e.get_rect().intersects(r):
			if not e.is_boss and main.wall_between(global_position, e.global_position):
				continue
			dash_hit[e] = true
			e.take_hit(int(clv(C.PHANTOM_DASH, [1, 2, 3])), Vector2(facing, 0))
			main.spawn_burst(e.global_position, Color(0.75, 0.65, 1.0), 8, 140.0)

# Coup d'une griffe : demi-dégâts. Les demi-points s'accumulent sur l'ennemi
# (deux coups de 0,5 = 1 point de vie) ; un coup puissant (2) fait 1 par griffe.
func _claw_hit(e, amount: float, kv: Vector2) -> void:
	var tot: float = float(e.get_meta("claw_frac", 0.0)) + amount
	var whole := int(floor(tot + 0.001))
	e.set_meta("claw_frac", tot - whole)
	e.take_hit(whole, kv)

const BLEED_CLAWS := 0.2
const BLEED_FANG := 0.3
func bleed_chance() -> float:
	var ch := 0.0
	if wid() == "griffes" and wlv() >= 2:
		ch += BLEED_CLAWS
	if eq(C.BLOOD_FANG):
		ch += float(clv(C.BLOOD_FANG, [BLEED_FANG, BLEED_FANG + 0.1, BLEED_FANG + 0.2]))
	return ch

func _bleed(e) -> void:
	e.set_meta("bleeding", true)
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(e):
		e.remove_meta("bleeding")
		if not e.dead:
			e.take_hit(1, Vector2.ZERO)
			main.spawn_burst(e.global_position, Color(0.85, 0.35, 0.55), 8, 90.0, 60.0)

func _from_trap(source) -> bool:
	return source != null and is_instance_valid(source) and (("from_trap" in source and source.from_trap) or source.get_script() == TrapScript)

func _enemy_near(r: float) -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
		if is_instance_valid(e) and not e.dead and e.global_position.distance_to(global_position) < r and e.get_script() != DummyScript:
			return true
	return false

func take_damage(amount: int, from_x: float) -> void:
	combat_t = 0.0
	bench_lock_t = BENCH_LOCK
	if dead:
		return
	hp -= amount
	if rope != null:
		release_rope(false)     # un coup fait lâcher la corde
	invuln_t = INVULN_TIME * float(clv(C.STONE_SKIN, [1.4, 1.6, 1.8], 1.0))
	GameState.j_add("hurt")
	GameState.j_perfect(false)
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
		main.thorns_burst(global_position, int(clv(C.THORNS, [3, 4, 5])))
	if hp <= 0 and _last_breath():
		return
	if hp <= 0:
		_die()

func _hazard_respawn() -> void:
	rope = null
	hp -= int(GameState.d("dmg"))
	main.on_player_hurt()
	if hp <= 0 and not _last_breath():
		_die()
		return
	# repli : si le dernier point sûr touche des pics, retour au départ du niveau (ou au dernier banc)
	var spot := last_safe
	if _near_spikes(spot, 6.0):
		spot = main.respawn_pos
	global_position = spot
	velocity = Vector2.ZERO
	invuln_t = INVULN_TIME
	knock_t = 0.3
	hazard_cd = 1.0
	# la ruée, l'estoc ou le piqué en cours s'arrêtent : avant, une Ruée lancée juste avant la chute
	# continuait après la réapparition et ramenait le héros dans les pics, plusieurs fois de suite
	dash_t = 0.0
	post_dash_t = 0.0
	thrust_t = 0.0
	attack_t = 0.0
	recoil_t = 0.0
	plunging = false

func _die() -> void:
	if GameState.mode == "duel":
		dead = true
		hp = 0
		velocity = Vector2.ZERO
		main.duel_ko(self)
		return
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
# Treuil : montée verticale puis petit pas de côté sur le sol du haut, en ~1,5 s au total.
var hoist_speed := 1.0
func hoist(path: Array, speed := 1.0) -> void:
	hoist_path = path
	hoist_speed = speed
	hoist_t = 0.0
	velocity = Vector2.ZERO
	attack_t = 0.0
	dash_t = 0.0
	charge_t = 0.0
	if crouching:
		_set_crouch(false)

# ---------------------------------------------------------------- corde des treuils
# On s'accroche (en bas, en l'air contre la corde, ou d'en haut), puis {up} / {down} pour monter
# ou descendre ; {jump} saute de la corde, {down} + {jump} la lâche. Arrivé en haut, le héros
# est déposé sur le rebord ; arrivé en bas, il pose pied au sol.
func can_grab_rope() -> bool:
	return rope == null and hoist_path.is_empty() and not dead and not sitting and rope_grab_cd <= 0.0 \
		and knock_t <= 0.0 and not plunging and ult_charge_t <= 0.0

func _rope_top(wn) -> float:
	return wn.top.y + SIZE.y / 2.0 + 8.0

func _rope_bottom(wn) -> float:
	return wn.position.y - SIZE.y / 2.0

func grab_rope(wn, y: float) -> void:
	rope = wn
	rope_hold_t = 0.0
	global_position = Vector2(wn.position.x, clampf(y, _rope_top(wn), _rope_bottom(wn)))
	velocity = Vector2.ZERO
	attack_t = 0.0
	dash_t = 0.0
	charge_t = 0.0
	thrust_t = 0.0
	if crouching:
		_set_crouch(false)
	crouch_latch = false
	# s'accrocher rend les mouvements aériens, comme un appui au sol
	air_dash_used = false
	air_dash2_used = false
	air_jump_used = false
	plunge_used = false
	buffer_t = 0.0
	Audio.sfx("door", 0.1, -10.0)

func release_rope(hop: bool) -> void:
	if rope == null:
		return
	rope = null
	rope_grab_cd = 0.3
	velocity = Vector2.ZERO
	if hop:
		var dir := _iaxis()
		if absf(dir) > 0.3:
			facing = int(signf(dir))
		velocity = Vector2(facing * 160.0, JUMP_VELOCITY * 0.7)
		squash = Vector2(0.8, 1.2)

func _rope_step(delta: float) -> void:
	var wn = rope
	if not is_instance_valid(wn):
		rope = null
		return
	velocity = Vector2.ZERO
	var dir := _iaxis()
	if absf(dir) > 0.3:
		facing = int(signf(dir))   # on choisit de quel côté sauter
	if _ijp("jump"):
		release_rope(not _ip("down"))
		return
	var fast := 2.0 if eq(C.CLIMBER) else 1.0
	# on part doucement (facile de s'arrêter où l'on veut), puis on accélère sur les longues cordes
	var v := 0.0
	if _ip("up"):
		v = -ROPE_UP
	elif _ip("down"):
		v = ROPE_DOWN
	rope_hold_t = rope_hold_t + delta if v != 0.0 else 0.0
	v *= fast * lerpf(1.0, 2.2, clampf((rope_hold_t - 0.25) / 0.8, 0.0, 1.0))
	var y := global_position.y + v * delta
	if v != 0.0:
		wn.pulling = maxf(wn.pulling, 0.12)
		anim_t += delta
	if v < 0.0 and y <= _rope_top(wn):
		# en haut : on se hisse sur le rebord
		rope = null
		var pos := Vector2(wn.position.x, _rope_top(wn))
		hoist([pos, Vector2(wn.position.x, wn.arrive.y), wn.arrive], 2.5 * fast)
		return
	if v > 0.0 and y >= _rope_bottom(wn):
		# en bas : on pose pied au sol
		global_position.y = _rope_bottom(wn)
		release_rope(false)
		return
	global_position = Vector2(wn.position.x, clampf(y, _rope_top(wn), _rope_bottom(wn)))

func _hoist_step(delta: float) -> void:
	hoist_t += delta
	velocity = Vector2.ZERO
	invuln_t = maxf(invuln_t, 0.2)
	var a: Vector2 = hoist_path[0]
	var b: Vector2 = hoist_path[1]
	var c: Vector2 = hoist_path[2]
	var up_time := clampf(a.distance_to(b) / 520.0, 0.6, 1.4) / hoist_speed
	if hoist_t < up_time:
		var k := hoist_t / up_time
		k = k * k * (3.0 - 2.0 * k)
		global_position = a.lerp(b, k)
	elif hoist_t < up_time + 0.25 / hoist_speed:
		global_position = b.lerp(c, (hoist_t - up_time) / (0.25 / hoist_speed))
	else:
		global_position = c
		hoist_path = []
		rope_grab_cd = 0.3        # pas de prise d'une autre corde juste en arrivant
		last_safe = c
		invuln_t = maxf(invuln_t, 0.4)

func _leave_bench() -> void:
	invuln_t = maxf(invuln_t, 1.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self:
			continue
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
	# Prière du Banc : s'asseoir remplit l'âme
	if eq(C.BENCH_PRAYER):
		soul = maxi(soul, int(clv(C.BENCH_PRAYER, [33, 66, 99])))

# ---------------------------------------------------------------- dessin
func _draw() -> void:
	if web_t > 0.0 and goo_col.a > 0.0:
		# glue aux pieds : paquets collants et filaments qui s'étirent
		var wa := minf(web_t / 0.3, 1.0)
		var fy := SIZE.y / 2.0
		for k in 3:
			var x := (k - 1) * 6.0
			draw_circle(Vector2(x, fy - 2.5), 4.4 - absf(k - 1) * 0.8, Color(goo_col.darkened(0.15), 0.85 * wa))
		var st := 3.0 + absf(sin(anim_t * 6.0)) * 3.0
		draw_line(Vector2(-4, fy - 3.0), Vector2(-5, fy - 3.0 - st), Color(goo_col, 0.6 * wa), 1.6)
		draw_line(Vector2(5, fy - 3.0), Vector2(6, fy - 2.0 - st * 0.7), Color(goo_col, 0.55 * wa), 1.3)
		draw_line(Vector2(-6, fy - 3.0), Vector2(1, fy - 3.4), Color(1, 1, 1, 0.4 * wa), 1.0)
	elif web_t > 0.0:
		var wa := minf(web_t, 1.0)
		for k in 5:
			var a := k * 1.3 + 0.4
			draw_line(Vector2(cos(a) * 12.0, -14 + sin(a) * 14.0), Vector2(cos(a + 2.2) * 11.0, -14 + sin(a + 2.2) * 12.0), Color(0.92, 0.92, 0.98, 0.55 * wa), 1.0)
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
	var wid: String = wid()
	if (attack_t <= 0.0 or wid == "griffes") and not sitting:
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
		var ck := clampf(charge_t / charge_time(), 0.0, 1.0)
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
				if wid() == "fouet" and attack_dir.y == 0.0:
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
				if wid() == "fouet":
					# fouet vers le haut ou le bas : la liane fouette verticalement jusqu'au bout de la zone
					var k3 := clampf(attack_t / ATTACK_TIME, 0.0, 1.0)
					var up := attack_dir.y < 0.0
					var s0 := Vector2(facing * 6.0, -8.0 if up else 4.0)
					var ey: float = (r.position.y if up else r.end.y) - global_position.y
					var lash := 1.0 - pow(k3, 2.0)
					var vpts := PackedVector2Array()
					for i in 13:
						var u := i / 12.0
						var wave := sin(u * 9.0 + anim_t * 40.0) * 7.0 * (1.0 - u)
						vpts.append(Vector2(s0.x * (1.0 - u) + wave, lerpf(s0.y, lerpf(s0.y, ey, lash), u)))
					var vine2 := Color(1.0, 0.6, 0.25, k3) if attack_crit else Color(0.6, 0.85, 0.45, k3)
					draw_polyline(vpts, vine2, 4.0)
					for i in range(2, 12, 2):
						draw_line(vpts[i], vpts[i] + Vector2(-5.0 if i % 4 == 0 else 5.0, 4.0 if up else -4.0), Color(vine2.darkened(0.3), k3), 1.5)
					draw_circle(vpts[12], 5.0, Color(0.85, 1.0, 0.65, k3))
					return
				if wid() == "faux":
					_draw_scythe_attack(r, c)
					return
				if wid() == "baton":
					_draw_staff_attack(r, c)
					return
				var fin := attack_kind == "finisher"
				var k := clampf(attack_t / (ATTACK_TIME * (1.4 if fin else 1.0)), 0.0, 1.0)
				var wcol: Color = weapon()["color"]
				var col := Color(1.0, 0.88, 0.55) if fin else wcol
				if attack_crit:
					col = Color(1.0, 0.6, 0.25)
				var hammer := wid() == "marteau"
				var rad := (40.0 if fin else 30.0) * (1.25 if hammer else 1.0)
				var piv := c - attack_dir * 14.0
				var prog := 1.0 - k
				var ease := 1.0 - pow(1.0 - prog, 3.0)
				# sens du coup : de haut en bas devant soi, et pour les coups verticaux dans le sens du regard
				var sweep: float = 1.3 * (float(facing) if attack_dir.y != 0.0 else 1.0)
				# griffes : la deuxième griffe (main arrière) remonte de bas en haut, un peu plus bas
				if claw_split and claw_hand == 1 and attack_kind == claw_kind:
					sweep = -sweep
					piv += Vector2(0, 5)
					col = col.lightened(0.15)
				var a0: float = ang - sweep
				var a_now := lerpf(a0, ang + sweep, minf(ease * 1.15, 1.0))
				var thick := (20.0 if fin else 15.0) * (1.4 if hammer else 1.0)
				if wid() == "griffes":
					# trois griffures parallèles, une par lame, violettes (dorées sur un coup puissant)
					var ccol := Color(1.0, 0.6, 0.25) if attack_crit else (Color(0.95, 0.6, 0.15) if fin else Color(0.42, 0.12, 0.85))
					for j in 3:
						_smear(piv, rad - 7.0 + j * 7.0, a0 + j * 0.06 * signf(sweep), a_now, 4.5 if j == 1 else 3.5, ccol, k, false)
				else:
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
				elif wid() == "griffes":
					# la griffe qui frappe : gantelet au bout du bras, trois lames courbes en éventail
					var gp := piv + wdir * (rad * 0.62)
					var hn := wdir.orthogonal() * signf(sweep)
					DU.box(self, Rect2(gp - Vector2(4, 3.5), Vector2(8, 7)), Color(0.35, 0.28, 0.4))
					for j in 3:
						var bd := wdir.rotated((j - 1) * 0.32)
						var root := gp + bd * 3.0
						var tip2 := root + bd * 13.0 + hn * 3.5
						DU.flat(self, PackedVector2Array([root + hn * 1.8, root + bd * 7.0 + hn * 2.6, tip2, root - hn * 1.4]), Color(0.85, 0.78, 0.98))
						draw_line(root + bd * 2.0, tip2 - bd * 2.0, Color(1, 1, 1, 0.7), 0.9)
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

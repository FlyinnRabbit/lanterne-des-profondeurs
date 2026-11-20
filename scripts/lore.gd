extends RefCounted
# Mémoires de l'Ancien : chroniques du monde, passé des habitants du Sanctuaire, ancienne vie des
# gardiens (boss) et paroles entendues. Chaque mémoire se débloque en jouant ; la première fois
# qu'on l'écoute, l'Ancien remercie d'une poignée d'éclats (REWARD).

const REWARD := 20

# Chroniques : une par palier terminé (0 = dès l'arrivée de l'Ancien)
const CHRONICLES := [
	{"id": "c0", "title": "La Lanterne", "need": 0,
		"text": "Autrefois, la Lanterne des Profondeurs éclairait chaque palier jusqu'au fond du monde. Sous sa lumière, les jardins fongiques fleurissaient, les forges chantaient et la Bibliothèque ne connaissait pas le silence. On disait qu'aucune ombre ne pouvait tenir debout devant elle."},
	{"id": "c1", "title": "Les Veilleurs", "need": 1,
		"text": "Pour garder la flamme, on forma les Veilleurs : de petits porteurs de lanterne qui descendaient d'un palier à l'autre, une étincelle confiée au creux de la main. Chacun la recevait ici, au Sanctuaire. Le Gardien du Puits fut le premier d'entre eux à prendre son poste."},
	{"id": "c2", "title": "La Grande Pluie", "need": 2,
		"text": "Un jour, l'eau est montée des fissures. Elle a noyé la Citadelle, ses cloches et ses prières. La lumière de la Lanterne tremblait dans l'eau noire, et pour la première fois, on a vu des paliers entiers s'éteindre."},
	{"id": "c3", "title": "Le Bourdonnement", "need": 3,
		"text": "Quand la lumière a faibli, la Ruche s'est affolée. Les abeilles ne trouvaient plus le chemin des fleurs ; elles se sont mises à tourner autour de ce qui brillait encore. Même autour des Veilleurs. Surtout autour des Veilleurs."},
	{"id": "c4", "title": "Ceux d'avant", "need": 4,
		"text": "Beaucoup de Veilleurs ne sont pas remontés. Leurs os se sont entassés au fond de l'Ossuaire, et l'obscurité, qui n'aime pas le gâchis, les a rassemblés en un seul corps. Le Colosse se souvient de toutes leurs descentes et d'aucun de leurs noms."},
	{"id": "c5", "title": "Le chemin mangé", "need": 5,
		"text": "Les tunnels qui reliaient les paliers au Sanctuaire ont disparu un à un. Le Ver, affamé dans le noir, a dévoré le chemin du retour. Depuis, chaque descente recommence d'ici, et l'ascenseur est le seul fil qui nous relie encore aux profondeurs."},
	{"id": "c6", "title": "Le serment", "need": 6,
		"text": "Le plus brave des Veilleurs jura de rallumer la Lanterne. Il descendit seul, avec son épée et sa promesse. On ne l'a jamais revu vivant. Son serment, lui, erre encore dans les couloirs, et il cherche quelqu'un d'assez digne pour le porter."},
	{"id": "c7", "title": "L'Ombre", "need": 7,
		"text": "Au septième palier, la flamme s'est éteinte pour de bon. Mais une flamme laisse toujours une ombre derrière elle, et cette ombre a pris sa place. Elle garde la Lanterne froide, entourée de ce qui reste des gardiens. Rallume-la, petit veilleur. C'est tout ce que je demande."},
]

# Habitants du Sanctuaire : leur passé, en deux temps (« b » se dévoile plus profond)
const PEOPLE := [
	{"id": "elder", "name": "L'Ancien", "prop": "elder", "need": 0, "need_b": 7,
		"a": "Un vieil escargot, le dernier des premiers Veilleurs. Il descendait lentement, si lentement que la Lanterne s'est éteinte avant qu'il n'arrive en bas. Il est remonté avec sa lanterne froide, et ne l'a jamais posée depuis.",
		"b": "Il ne s'est jamais pardonné son retard. S'il raconte tout ce qu'il sait à qui veut l'entendre, c'est pour que personne d'autre n'arrive trop tard. Le jour où la Lanterne brillera de nouveau, il dit qu'il posera enfin sa canne."},
	{"id": "plume", "name": "Maître Plume", "prop": "scriptorium", "need": 0, "need_b": 4,
		"a": "La chouette archiviste tenait les registres de la Bibliothèque Silencieuse, du temps où elle ne l'était pas. Quand le silence est tombé sur les rayonnages, elle n'a sauvé qu'une plume et un livre vierge.",
		"b": "Maître Plume croit qu'une chose oubliée finit toujours par devenir un monstre : les gardiens ne sont que des serments dont plus personne ne se souvient. Alors il écrit tout. Chaque coup, chaque chute, chaque victoire. Pour que toi, on ne t'oublie pas."},
	{"id": "merchant", "name": "Le marchand", "prop": "merchant", "need": 0, "need_b": 3,
		"a": "Un grand papillon de nuit voyageur : il va là où il y a de la lumière, et il y en a si peu qu'il s'est installé au Sanctuaire. Sa bête de somme l'a suivi depuis les Sables Enfouis sans jamais se plaindre.",
		"b": "On murmure qu'avant la nuit, il vendait des mèches de lanterne à tous les paliers. Il fait payer cher ses merveilles, mais il garde chaque éclat dans un coffre qu'il n'ouvre jamais : sa part pour le jour où il faudra rallumer la Lanterne."},
	{"id": "tailor", "name": "La tailleuse", "prop": "tailor", "need": 0, "need_b": 5,
		"a": "Une phalène couturière. C'est elle qui tissait les capes des Veilleurs, une par serment. Elle dit qu'une cape, c'est une promesse qu'on porte sur le dos.",
		"b": "Elle a cousu la cape du Chevalier, autrefois. Il manquait un dernier point quand il est parti, et elle a gardé l'aiguille plantée dans le tissu depuis. Si un jour tu le libères, elle aimerait finir son ouvrage."},
	{"id": "smith", "name": "La forgeronne", "prop": "smith", "need": 1, "need_b": 4,
		"a": "Une scarabée trapue, venue de la Forge Ardente quand ses fourneaux se sont refroidis. Elle forge sans relâche, comme si chaque coup de marteau gardait le froid à distance.",
		"b": "Le Gardien du Puits est son frère. C'est elle qui a forgé son armure, il y a longtemps. Elle forge tes armes dans l'espoir que tu le délivres de son poste, et qu'il puisse enfin se souvenir de son nom : Orm."},
	{"id": "cartographer", "name": "Le cartographe", "prop": "cartographer", "need": 2, "need_b": 5,
		"a": "Une mite à lunettes et redingote. Il a tracé la route des premiers Veilleurs, palier après palier. Depuis que le Ver a mangé les tunnels, ses cartes ne tiennent jamais deux descentes de suite.",
		"b": "Il a dessiné, une fois, un palier sous le septième. Il a brûlé la carte aussitôt. Il refuse d'en parler, mais il garde une bougie allumée près de sa table, au cas où quelqu'un remonterait de là-dessous."},
	{"id": "jeweler", "name": "Le joaillier", "prop": "jeweler", "need": 2, "need_b": 6,
		"a": "Un pharaon momifié du Temple Antique. C'est lui qui avait serti les verres de la Lanterne. Les emblèmes que tu trouves en descente, dit-il, en sont des éclats.",
		"b": "Il s'est enroulé de bandelettes pour durer jusqu'au retour de la lumière. Il compte les jours sur ses doigts secs. Le chiffre est si grand qu'il a cessé de le dire à voix haute."},
	{"id": "hero", "name": "Le petit veilleur", "prop": "", "need": 7, "need_b": 99,
		"a": "La dernière étincelle confiée au Sanctuaire. Personne ne croyait qu'elle tiendrait jusqu'au septième palier. Elle a tenu. L'Ancien te regarde différemment, maintenant.",
		"b": ""},
]

# Gardiens : ce qu'ils étaient avant la nuit (débloqué en les vainquant)
const GUARDIANS := {
	"gardien": "Il s'appelait Orm. Premier des Veilleurs, il gardait l'entrée du Puits pour que personne ne descende sans flamme. Quand la Lanterne a faibli, il a fermé le passage pour protéger les vivants. Puis il a oublié pourquoi, et il ne laisse plus passer personne.",
	"abbesse": "Elle menait les prières de la Citadelle, au son des cloches, devant le reflet de la Lanterne dans les vitraux. Quand l'eau est montée, elle n'a pas voulu partir. Ses prières ont moisi avec elle ; ce sont elles, ces spores qui flottent autour d'elle.",
	"reine": "Elle régnait sur la Ruche, dont les abeilles pollinisaient les jardins sous la lumière. Elle a cru que la flamme était la plus grande des fleurs. Depuis qu'elle s'est éteinte, son essaim tourne autour du vide, et elle défend ce vide comme un trésor.",
	"colosse": "Ce n'est pas une créature, ce sont des dizaines : les Veilleurs tombés pendant la descente. L'obscurité a assemblé leurs os pour qu'ils continuent ensemble. Il frappe les vivants parce qu'il croit qu'ils sont en retard.",
	"ver": "Il creusait autrefois les tunnels entre les paliers, un humble ouvrier que les Veilleurs saluaient en passant. Dans le noir, affamé, il a mangé la terre, puis les tunnels, puis le chemin du retour. Il ne sait plus s'arrêter.",
	"chevalier": "Le plus brave des Veilleurs. Il a juré de rallumer la Lanterne et il est descendu seul. Il a échoué, mais son serment est resté debout sans lui. Il défie chaque veilleur qui passe pour trouver quelqu'un d'assez digne de le reprendre.",
	"ombre": "Pendant des siècles, la Lanterne a projeté une ombre derrière elle, sans que personne y prenne garde. Quand la flamme est morte, l'ombre a gardé sa forme. Elle n'a jamais connu que le dos de la lumière, et elle déteste son visage.",
	"cerbere": "Trois chiens de forge gardaient le grand fourneau et soufflaient sur les braises pour qu'elles ne meurent jamais. Quand la Forge s'est refroidie, ils se sont serrés les uns contre les autres pour garder la chaleur, si fort qu'ils n'ont plus fait qu'un.",
	"centaure": "Archer des Sables Enfouis, il tirait des flèches de feu pour porter les signaux d'un palier à l'autre. Dans la nuit, il a pris toutes les lumières pour des ennemis. Il tire encore sur la moindre lueur, la tienne comprise.",
	"oeil": "Le fond du monde a toujours regardé vers le haut, vers la Lanterne. Sans elle, l'Œil ne voit plus rien. Ses tentacules tâtonnent à la recherche de la lumière perdue, et ils serrent tout ce qu'ils trouvent.",
}

const BOSS_ORDER := ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre", "cerbere", "centaure", "oeil"]

# ---------------------------------------------------------------- état
static func boss_beaten(id: String) -> bool:
	var bd: Dictionary = (GameState.journal.get("bosses", {}) as Dictionary).get(id, {})
	if int(bd.get("w", 0)) > 0:
		return true
	for p in range(1, mini(GameState.record, 6) + 1):
		if GameState.boss_for(p) == id:
			return true
	return false

# Toutes les mémoires : [id, débloquée]
static func entries() -> Array:
	var out := []
	for c in CHRONICLES:
		out.append([c["id"], GameState.record >= int(c["need"])])
	for p in PEOPLE:
		out.append(["p_" + p["id"], GameState.record >= int(p["need"])])
		if p["b"] != "":
			out.append(["p_" + p["id"] + "_b", GameState.record >= int(p["need_b"])])
	for b in BOSS_ORDER:
		out.append(["g_" + b, boss_beaten(b)])
	return out

static func read_list() -> Array:
	if not GameState.prog.has("lore_read"):
		GameState.prog["lore_read"] = []
	return GameState.prog["lore_read"]

static func is_read(id: String) -> bool:
	return read_list().has(id)

static func unread_count() -> int:
	var n := 0
	var rl := read_list()
	for e in entries():
		if e[1] and not rl.has(e[0]):
			n += 1
	return n

static func unlocked_count() -> int:
	var n := 0
	for e in entries():
		if e[1]:
			n += 1
	return n

# ---------------------------------------------------------------- paroles entendues
# Journal des répliques des habitants : {nom: [répliques]}, sans doublons, ordre d'écoute.
static func hear(who: String, line: String) -> void:
	line = line.strip_edges()
	if who == "" or line == "" or not line.begins_with("«"):
		return
	if not GameState.prog.has("talk"):
		GameState.prog["talk"] = {}
	var d: Dictionary = GameState.prog["talk"]
	if not d.has(who):
		d[who] = []
	var arr: Array = d[who]
	if not arr.has(line):
		arr.append(line)
		while arr.size() > 40:
			arr.pop_front()

static func talk() -> Dictionary:
	return GameState.prog.get("talk", {})

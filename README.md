# Lanterne des Profondeurs

Petit metroidvania 2D pour **Godot 4.3+**, inspiré de Hollow Knight : grottes sombres,
combat à l'aiguille, rebond sur les ennemis, soin avec l'âme, banc de repos et un boss.
Tout est dessiné en code : aucune image à importer.

## Télécharger (Windows)
Dernière version : onglet **Releases** → `LanterneDesProfondeurs_Windows.zip`, décompresser,
lancer `LanterneDesProfondeurs.exe`. L'exe n'étant pas signé, Windows SmartScreen peut afficher
« Windows a protégé votre ordinateur » → *Informations complémentaires* → *Exécuter quand même*.

## Lancer le projet dans Godot
1. Installe Godot 4 (version standard, pas .NET) : https://godotengine.org/download
2. Dans le gestionnaire de projets : **Importer** → choisis le dossier `lanterne` (fichier `project.godot`).
3. Appuie sur **F5**.

## Commandes par défaut (clavier AZERTY ou QWERTY, manette Xbox / XInput)
| Action | Clavier | Manette |
|---|---|---|
| Bouger | Q / D ou flèches | Stick gauche / croix |
| Sauter (maintenir = plus haut) | Espace | A |
| Frapper | J ou **clic gauche** | X |
| Frapper vers le haut / le bas | Z ou S + J | haut/bas + X |
| Ruée / esquive | K ou Maj | RT |
| Parade | I ou **clic droit** | LB |
| Ultime (jauge pleine) | U ou R | Y |
| Se soigner (maintenir, coûte 33 d'âme) | L ou F | B |
| Se reposer au banc | Z / flèche haut | haut |
| **Pause et menu** | **Échap ou P** | **Menu (Start)** |
| **Inventaire / équipement** | **Tab ou B** | **View (Back)** |

### Menu « Commandes »
Échap → **Commandes** : clique (ou valide à la manette) une case, puis appuie sur la nouvelle
touche. Chaque action a 2 touches clavier et 1 bouton manette ; si l'entrée est déjà prise,
les deux actions sont échangées. Suppr efface une touche clavier, Échap annule.
Les cases « Touche » acceptent aussi les boutons de la souris (gauche, droit, milieu,
boutons latéraux). Les menus et l'inventaire se pilotent à la souris ; en jeu, le curseur se
cache après 2 s d'immobilité.
Les réglages sont sauvegardés automatiquement (`user://controls.cfg`).
Le stick gauche reste toujours actif pour se déplacer.

### Manette (XInput)
Sous Windows, Godot lit les manettes Xbox via XInput : il suffit de la brancher.
Le jeu affiche la manette détectée, utilise les noms de boutons Xbox (A, B, X, Y, LB, RB, LT, RT),
accepte les gâchettes dans le menu et fait vibrer la manette (coups, dégâts, boss).
Les vibrations se coupent dans le menu Commandes. Les aides à l'écran s'adaptent
au dernier périphérique utilisé (clavier ou manette).

## Écran titre et difficulté
Au lancement : **Jouer** → choix de la difficulté (et option « Passer le tutoriel »).
Aussi accessible en cours de partie : Pause → « Nouvelle partie… ».

| Difficulté | Âme / ultime | Ennemis | Dégâts reçus |
|---|---|---|---|
| Facile | +35 % / +30 % | plus lents, -25 % de vie, moins nombreux, pas d'élites | 1 |
| Normal | normal | normal, quelques élites | 1 |
| Difficile | -25 % / -20 % | +25 % de vitesse, plus agressifs, +35 % de vie, +35 % d'ennemis, 30 % d'élites, plus de nouveaux ennemis | 1 |
| Cauchemar | -40 % / -35 % | +40 % de vitesse, très agressifs, +60 % de vie, +60 % d'ennemis, 50 % d'élites | **2** |

Les boss sont aussi plus rapides et plus résistants selon la difficulté.

### Ennemis
- **Rampant**, **Volant**, **Cracheur** (comme avant).
- **Sauteur** (nouveau) : sauterelle qui bondit vers toi.
- **Garde à bouclier** (nouveau) : bloque les coups de face. Frappe-le par-dessus (coup vers
  le bas), dans le dos, ou avec l'ultime.
- **Élites** (lueur rouge) : plus de vie, plus rapides, double butin, et une attaque en plus —
  le rampant fonce sur toi, le volant fait des piqués, le cracheur tire 3 spores,
  le sauteur enchaîne deux bonds, le garde charge au bouclier.
Les nouveaux ennemis et les élites deviennent plus fréquents en profondeur.

## Parties aléatoires (façon Dead Cells)
Chaque partie : **tutoriel**, puis **5 niveaux générés** dans 5 biomes tirés au hasard parmi 9,
dans un ordre aléatoire. Les niveaux sont reconstruits à chaque partie en assemblant des
« salles » (sol plat, plateformes, fosses à pics, piliers, collines, murs à escalader, puits,
couloirs bas, ponts, arènes, grands gouffres à franchir en Ruée…). Chaque biome a ses
couleurs, sa musique, ses types de salles favoris et ses ennemis :

| Biome | Particularité |
|---|---|
| Les Profondeurs | grottes bleutées, collines et puits, rampants et volants |
| Les Jardins Fongiques | murs à escalader, puits, beaucoup de cracheurs |
| La Citadelle Engloutie | piliers au-dessus des pics, arènes, ponts |
| Les Mines de Cristal | grands gouffres (Ruée), couloirs bas, volants |
| La Forge Ardente | pics partout, braises, rampants en masse |
| La Bibliothèque Silencieuse | escalade et plateformes, nuées de volants |
| Les Abysses Gelés | neige, ponts fragiles et gouffres, cracheurs |
| La Ruche Bourdonnante | couloirs étroits envahis de volants |
| L'Ossuaire | collines et arènes, rampants et cracheurs |

- Un banc au départ et un à mi-parcours de chaque niveau.
- **Gardien du Puits** à la fin du niveau 3, **Abbesse Engloutie** à la fin du niveau 5, puis le sanctuaire.
- Les emblèmes (losanges) et encoches sont placés au hasard dans les niveaux.
- La difficulté monte avec la profondeur (niveaux plus longs, plus d'ennemis).
- Le menu pause affiche le numéro de la partie et le parcours. « Recommencer le niveau »
  redonne exactement le même niveau ; « Nouvelle partie » tire un nouveau parcours
  (avec ou sans tutoriel).
- Le tutoriel reste fait à la main (`scripts/levels.gd`) ; le générateur est dans
  `scripts/levelgen.gd` et les biomes dans `scripts/biomes.gd` (facile d'en ajouter).

## Musique et sons
Bande-son **originale** générée pour le jeu (aucun droit d'auteur, elle est à toi) :
16 morceaux en boucle dans `music/` — une ou deux pistes par biome qui s'enchaînent
avec un fondu, un thème par boss, un pour le tutoriel et un pour le sanctuaire.
12 bruitages dans `sfx/`. Volumes **général / musique / effets** dans Options ;
la musique baisse un peu quand le jeu est en pause.

## Options (menu pause → Options)
- **Taille du HUD** (60 – 160 %) et **taille des menus** (60 – 130 %, s'applique aussi à l'inventaire).
- **Zoom de la caméra**, **plein écran** (aussi avec F11), **synchronisation verticale**.
- **Aides à l'écran** (rappels de touches en bas de l'écran).
- **Secousses de l'écran** (0 – 150 %), **arrêt sur image** aux impacts, **vibrations** de la manette.
Tout est sauvegardé dans `user://settings.cfg`. Le menu Commandes est désormais une liste
défilante (molette, ou navigation clavier/manette).

## Inventaire et emblèmes
Tab ouvre l'inventaire (le jeu se met en pause) : objets, éclats, statistiques et la grille des
8 **emblèmes** à trouver dans les niveaux (losanges colorés flottants). Chaque emblème coûte des
encoches ; on en a 3 au départ et deux **encoches** supplémentaires sont cachées (anneaux dorés).
Comme dans l'inspiration, on ne change d'équipement qu'**assis sur un banc**.

| Emblème | Coût | Effet |
|---|---|---|
| Aiguille Longue | 2 | portée des coups +40 % |
| Cœur de Verre | 2 | +2 fragments de vie |
| Cape Rapide | 1 | course +12 %, Ruée rechargée 2× plus vite |
| Coquille Épineuse | 2 | des épines blessent les ennemis proches quand on est touché |
| Miroir Parfait | 1 | fenêtre de parade 0,35 s |
| Âme Vorace | 2 | plus d'âme et d'ultime à chaque coup |
| Concentration Vive | 1 | soin presque 2× plus rapide |
| Force Brute | 3 | dégâts de l'aiguille ×2 |

Les effets sont définis dans `scripts/charms.gd` et appliqués dans `scripts/player.gd`.

## Combat
- **Parade** : courte fenêtre (0,2 s). Un contact paré étourdit l'ennemi (il devient inoffensif
  et vulnérable) ; un boss paré est sonné une seconde. Une spore parée repart vers les ennemis.
  Rapporte de l'âme et beaucoup de charge d'ultime.
- **Esquive** : pendant la Ruée, on traverse les ennemis et les projectiles (pas les pics).
- **Ultime** : la jauge dorée se remplit en frappant (+6) et en parant (+25). Quand elle est
  pleine, le héros se fige, se charge une demi-seconde (invulnérable), puis libère une onde de
  choc : 8 dégâts à tout ce qui est proche et destruction des spores.
- Un coup d'aiguille détruit aussi les spores ennemies.

## Modifier
- Les cartes sont dans `scripts/levels.gd` : ajoute une entrée à `LEVELS` pour créer un niveau (`#` roche, `^` pics, `c`/`f`/`s`
  ennemis, `B` banc, `D` orbe, `K` boss…). Change un caractère et relance.
- Les réglages du personnage (vitesse, saut, ruée, dégâts) sont les constantes en haut de
  `scripts/player.gd`.

## Tests
`tests/test_run.gd` joue automatiquement tous les niveaux (entrées simulées, boss, menus) :
`godot --headless --fixed-fps 120 -s res://tests/test_run.gd`.
`tests/dump_maps.gd` génère des centaines de niveaux pour vérifier qu'ils sont franchissables.

## Licence
Code, musiques (générées pour le jeu) et bruitages : licence **MIT** — voir `LICENSE`.
Le jeu s'inspire de Hollow Knight (Team Cherry) mais n'en réutilise ni personnages ni ressources.

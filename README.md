# Lanterne des Profondeurs

<p align="center"><img src="art/icon_1024.png" width="160" alt="Logo : lanterne médiévale"></p>

Petit metroidvania 2D pour **Godot 4.3+**, inspiré de Hollow Knight : grottes sombres,
combat à l'aiguille, rebond sur les ennemis, soin avec l'âme, banc de repos et un boss.
Tout est dessiné en code : aucune image à importer.

## Télécharger (Windows)
Dernière version : onglet **Releases** → `LanterneDesProfondeurs_Windows.zip`, décompresser,
lancer `LanterneDesProfondeurs.exe`. L'exe n'étant pas signé, Windows SmartScreen peut afficher
« Windows a protégé votre ordinateur » → *Informations complémentaires* → *Exécuter quand même*.

## macOS (Intel et Apple Silicon)
1. Télécharger `LanterneDesProfondeurs_macOS.zip` dans la Release, le décompresser et glisser
   **Lanterne des Profondeurs** dans le dossier Applications.
2. L'app n'est pas validée par Apple (il faudrait un compte développeur payant), macOS la bloque donc
   au premier lancement :
   - **clic droit (ou Ctrl + clic) sur l'app → Ouvrir**, puis **Ouvrir** dans la fenêtre ;
   - sur **macOS 15 (Sequoia)** et plus récent : lancer l'app une fois, puis **Réglages Système →
     Confidentialité et sécurité** → en bas, **« Ouvrir quand même »** ;
   - si macOS affiche « l'app est endommagée », ouvrir le **Terminal** et taper :
     `xattr -cr "/Applications/Lanterne des Profondeurs.app"`, puis relancer.
3. Ensuite le jeu se lance normalement. Les manettes Xbox et PlayStation fonctionnent.
   Sauvegardes : `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs/`.

## Version portable
`LanterneDesProfondeurs_Windows_Portable.zip` / `LanterneDesProfondeurs_Linux_Portable.tar.gz` :
le jeu avec un fichier `portable.txt`. Tant que ce fichier est à côté de l'exécutable,
la progression, les réglages et les touches sont enregistrés dans le dossier `sauvegardes`
du jeu (rien n'est écrit ailleurs) : copier le dossier sur une clé USB suffit pour emporter
le jeu et sa partie. Supprimer `portable.txt` pour revenir aux sauvegardes habituelles.

## Linux et Steam Deck
Dans les Releases : `LanterneDesProfondeurs_Linux_SteamDeck.tar.gz` (Linux x86_64).

**Linux** : extraire l'archive, puis lancer `./LanterneDesProfondeurs.x86_64`
(si besoin : clic droit → Propriétés → « Autoriser l'exécution », ou `chmod +x`).

**Steam Deck** :
1. Passer en **mode Bureau** (bouton Steam → Alimentation → Passer au bureau).
2. Télécharger l'archive depuis la page Releases avec le navigateur, l'extraire
   (clic droit → *Extract archive here*), par exemple dans `~/Jeux/Lanterne`.
3. Ouvrir Steam en mode Bureau → *Jeux* → **Ajouter un jeu non-Steam à ma bibliothèque**
   → *Parcourir* → choisir `LanterneDesProfondeurs.x86_64` → *Ajouter les programmes
   sélectionnés*.
4. Revenir en **mode Jeu** : le jeu est dans la bibliothèque (onglet *Non-Steam*).
   Il se lance en plein écran, les commandes du Deck fonctionnent directement
   (A sauter, X frapper, RT ruée, LB parade, Y ultime, B soin) et l'écran 16:10 est rempli.
   L'icône `LanterneDesProfondeurs.png` fournie peut être choisie dans les propriétés du raccourci.

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
| S'accroupir (esquive les attaques hautes) | S ou flèche bas (maintenir au sol) | bas |
| Attaque plongée (en l'air) | S + K | bas + RT |
| Ruée / esquive | K ou Maj | RT |
| Parade | I ou **clic droit** | LB |
| Sort d'âme (33 d'âme) | O ou clic milieu | RB |
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

### Icônes de commandes
Les aides à l'écran, les panneaux, les messages et le menu Commandes affichent des **icônes** :
touches et souris dessinées au clavier, boutons A/B/X/Y colorés, LB/RT… pour une manette Xbox,
croix/rond/carré/triangle, L1/R2… pour une manette PlayStation (symboles génériques).

### Manette (XInput)
Sous Windows, Godot lit les manettes Xbox via XInput : il suffit de la brancher.
Le jeu affiche la manette détectée, utilise les noms de boutons Xbox (A, B, X, Y, LB, RB, LT, RT),
accepte les gâchettes dans le menu et fait vibrer la manette (coups, dégâts, boss).
Les vibrations se coupent dans le menu Commandes. Les aides à l'écran s'adaptent
au dernier périphérique utilisé (clavier ou manette).

## Écran titre et difficulté
**3 emplacements de sauvegarde** : écran titre → « Parties ». Chaque emplacement a sa propre partie
et sa propre difficulté (par exemple une partie Normal et une partie Cauchemar en parallèle).
« Continuer » reprend le dernier emplacement joué. L'ancienne sauvegarde devient l'emplacement 1.
Les succès et les options sont communs à tous les emplacements.

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
- **Bulbe explosif** : roule vers toi, s'allume et explose (les ennemis proches aussi). Tue-le avant !
- **Tisseuse** : araignée suspendue au plafond qui se laisse tomber quand tu passes dessous.
- **Lancier** : se met en garde puis porte un long estoc ; une parade l'étourdit.
- **Spectre** : s'estompe (intouchable), réapparaît près de toi et lance une orbe lente.
- **Rampant**, **Volant**, **Cracheur** (comme avant).
- **Sauteur** (nouveau) : sauterelle qui bondit vers toi.
- **Garde à bouclier** (nouveau) : bloque les coups de face. Frappe-le par-dessus (coup vers
  le bas), dans le dos, ou avec l'ultime.
- **Élites** (lueur rouge) : plus de vie, plus rapides, double butin, et une attaque en plus —
  le rampant fonce sur toi, le volant fait des piqués, le cracheur tire 3 spores,
  le sauteur enchaîne deux bonds, le garde charge au bouclier.
Les nouveaux ennemis et les élites deviennent plus fréquents en profondeur.

## Combat : coups spéciaux
- **Combo au sol** : 3 coups, le 3e est un coup final ; maintenir puis relâcher = **tourbillon** ;
  frapper pendant la Ruée = **estoc**.
- **Combo aérien** (différent du combo au sol) : entaille, **entaille montante** qui relance vers
  le haut, puis **vrille** qui touche tout autour.
- **Attaque plongée** : en l'air, bas + Ruée. Piqué vers le sol, rebond sur l'ennemi touché, ou
  **onde de choc** à l'atterrissage.
- **Accroupi** : maintenir bas au sol. Plus lent, mais les attaques hautes passent au-dessus
  (estoc du lancier, balayage du Colosse, fléchettes, lames-pendules). Frapper accroupi = coup bas.
- **Parade parfaite** : parer au tout dernier moment affiche « PARFAITE ! » ; une **lumière dorée**
  brille au bout de l'arme et le prochain coup (normal, final, tourbillon, estoc, aérien, plongée
  ou lame d'âme) est **critique : ×1,5 dégâts**. Le journal des dégâts affiche « CRITIQUE ».

## Équilibrage (v1.8)
- **Étoiles de Lune** : 3 étoiles « simples » maximum à l'écran, moins d'âme par touche, et les boss
  n'encaissent que 60 % des dégâts à distance.
- **Marteau** un peu plus lent ; **Force Brute** : +1 dégât mais coups 20 % plus lents.
- **Critique** : ×1,5 arrondi au-dessus, et toujours au moins +1 dégât.
- **Attaque plongée** : une seule par saut (petite recharge).
- **Pièges** : 50 % de chance maximum par salle, et moins d'ennemis dans les salles piégées.
- **Ombre** : en mourant en descente, ton ombre garde les éclats perdus là où tu es tombé.
  Retourne au même palier et vaincs-la pour les récupérer (une nouvelle mort la remplace).

## Carte, annonces et accessibilité
- **Carte** (touche M / R3) : tout ce que tu as découvert du niveau, avec banc, sortie, ombre, objets.
  **Mini-carte** en haut à droite (Options). Le **cartographe** vend une plume qui révèle tout.
- **Annonces d'attaque** : un « ! » jaune au-dessus d'un ennemi qui prépare un coup, orange avec
  une flèche quand c'est une attaque haute (s'accroupir).
- **Options → Accessibilité** : dangers très contrastés (daltonisme), accroupi en appuyant (bascule),
  vitesse du jeu 100 / 90 / 80 / 70 %.
- **Statistiques** de descente (ennemis, dégâts, critiques, parades parfaites, coups reçus, temps)
  affichées au retour au Sanctuaire.
- **Sons** propres à chaque arme, au coup critique et à la parade parfaite.

## Nouveautés du Sanctuaire
- **Mannequin d'entraînement** (à droite de l'arsenal) qui affiche les dégâts par seconde.
  À l'arsenal, **Essayer** prête une arme le temps de rester au Sanctuaire.
- **Habitants** qui arrivent au fil des paliers terminés : la **forgeronne** (palier 1, armes niv. 2),
  le **cartographe** (palier 2, carte complète), l'**ancien** (palier 3, l'histoire de la Lanterne).
- **Ascenseur** : chaque palier peut se jouer avec une **malédiction** (Hâte, Obscurité, Fragilité)
  pour +50 à 60 % d'éclats ; **Descente du jour** (même niveau pour tout le monde, meilleur temps) ;
  **Défi des boss** (les 7 boss à la suite, chronométré) une fois le palier 6 terminé.
- **Succès** (17), consultables depuis l'écran titre ou le menu pause.

## Armes niveau 2 (forgeronne)
| Arme | Effet niv. 2 |
|---|---|
| Aiguille | le coup final projette une courte lame d'air |
| Fouet | attire vers toi les petits ennemis touchés |
| Marteau | le coup final fait jaillir une onde de choc des deux côtés |
| Étoiles | reviennent comme un boomerang et touchent à nouveau |

## Nouveaux emblèmes
- **Météore Ardent** : une plongée qui touche prépare un coup critique.
- **Repos de l'Ombre** (2 encoches) : accroupi hors combat, l'âme remonte lentement jusqu'à 33 ; soin accroupi 1,5 fois plus rapide
  (avec Concentration Vive : les bonus ne se multiplient pas, soin jamais sous 0,4 s).
- **Écho Parfait** : une parade parfaite lance une lame d'âme gratuite.
- **Pas Léger** : franchir un piège sans être touché rapporte 5 éclats.

## Salles spéciales
- **Trésor** : un sol fissuré cache un coffre ; casse-le (coups vers le bas ou plongée).
- **Défi chronométré** : touche la stèle au sablier, puis atteins le drapeau en 13 secondes.
- **Arène d'élites** : réveille l'autel, bats trois élites, gagne des éclats et un emblème.
- **Marchand ambulant** : parfois près du banc de mi-parcours (les achats font partie du butin).

## Boss finaux
Au palier 7 (puis tous les 7 paliers), un boss final **tiré au hasard pour chaque partie**,
chacun avec son propre thème musical :
- **L'Ombre de la Lanterne** : couronnes de braises, balayage à hauteur de tête, pluie de cendres,
  colonnes de lumière, spectres en phase 2.
- **Le Cerbère des Profondeurs** : souffle de braises des trois têtes, bond avec onde de choc,
  triple morsure à hauteur de tête (s'accroupir), hurlement qui fait jaillir des flammes.
- **Le Centaure Archer** : galop à travers l'arène, salves de flèches, pluie de flèches annoncée
  au sol, coup de lance à hauteur de tête (s'accroupir), sauts par-dessus le joueur.
- **L'Œil d'en Dessous** : tentacules qui jaillissent du sol, rayon qui balaie l'arène à hauteur
  de tête (s'accroupir) ou au ras du sol (sauter), spirales de spores, yeux volants.

Le vaincre lance **l'animation de fin** : la Lanterne se rallume, la lumière remonte palier par
palier jusqu'au Sanctuaire puis à la surface, et le générique défile sur le thème de fin.
Ensuite, les paliers continuent. Succès « Les quatre gardiens » : vaincre les quatre.

## L'arsenal (au Sanctuaire)
| Arme | Prix | Style |
|---|---|---|
| Aiguille du Veilleur | — | équilibrée |
| Fouet de Ronces | 150 | très longue portée devant et vers le haut, un peu plus lent |
| Marteau d'Enclume | 220 | lent, +1 dégât, gros recul, étourdit |
| Étoiles de Lune (shurikens) | 260 | à distance ; coup final = 3 étoiles, tourbillon = 8 en cercle, estoc = grande étoile perçante |

## Pièges et plateformes
Les niveaux ont maintenant du relief (le sol monte et descend d'une salle à l'autre) et de
nouvelles salles : îlots flottants, puits en zigzag, chemins doubles, grottes basses, ponts fragiles,
gouffres à plateforme mobile, couloirs de lames.
- **Totem à fléchettes** : tire à hauteur de tête — s'accroupir, sauter ou parer.
- **Lame-pendule** : son point bas passe juste au-dessus d'un héros accroupi.
- **Stalactite** : se décroche quand on passe dessous.
- **Blocs fragiles** : s'effondrent peu après qu'on s'y pose, puis se reforment.
- **Plateforme mobile** : fait l'aller-retour au-dessus d'un gouffre.

## Le Sanctuaire et les paliers sans fin
Après le tutoriel, on arrive au **Sanctuaire de la Lanterne**, la base du jeu :
- **Banc** : repos, vie restaurée, changement d'emblèmes.
- **Marchand** : échange les éclats contre des **fragments de vie** (+1 vie max, jusqu'à 4),
  des **encoches** d'emblème et les **emblèmes** pas encore trouvés.
- **Arsenal** : achète et équipe ton arme de base (voir plus haut).
- **Ascenseur** : choisit le **palier** où descendre.

Un **palier = 2 niveaux générés** (biomes tirés au hasard parmi 9) **puis un boss**. Le terminer ramène
au Sanctuaire et **débloque le palier suivant** — sans fin. Plus on descend, plus les ennemis
ont de vie, de vitesse, d'agressivité et d'élites (≈ ×1,9 de vie au palier 6, ×2,6 au palier 10).

**Mort** pendant une descente : retour au Sanctuaire, le butin ramassé depuis le départ
(éclats, emblèmes, encoches) est perdu, mais les paliers débloqués et les achats restent.
**Sauvegarde automatique** (`user://save.cfg`) : l'écran titre propose **Continuer**.

Les 9 biomes :

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

## Musique et sons
Bande-son **originale** générée pour le jeu (aucun droit d'auteur, elle est à toi) :
16 morceaux en boucle dans `music/` — une ou deux pistes par biome qui s'enchaînent
avec un fondu, un thème par boss, un pour le tutoriel et un pour le sanctuaire.
12 bruitages dans `sfx/`. Volumes **général / musique / effets** dans Options ;
la musique baisse un peu quand le jeu est en pause.

## Options (menu pause → Options)
- **Langue / Language** : Automatique (langue du système), Français, English, Español, Deutsch.
  Les traductions sont dans `tools/translations.py` (texte français → anglais, espagnol, allemand) ;
  lancer `python3 tools/translations.py` régénère `scripts/translations.gd`.
- **Taille du HUD** (60 – 160 %) et **taille des menus** (60 – 130 %, s'applique aussi à l'inventaire).
- **Zoom de la caméra**, **plein écran** (aussi avec F11), **synchronisation verticale**.
- **Barres de vie des ennemis** (trait au-dessus de chaque ennemi blessé, encadré rouge pour les élites)
  et **dégâts infligés** affichés brièvement en haut à droite (couleur selon le coup).
- **Aides à l'écran** (rappels de touches en bas de l'écran).
- **Secousses de l'écran** (0 – 150 %), **arrêt sur image** aux impacts, **vibrations** de la manette.
Tout est sauvegardé dans `user://settings.cfg`. Le menu Commandes est désormais une liste
défilante (molette, ou navigation clavier/manette).

## Les boss
Le Gardien ouvre toujours la marche ; les cinq autres arrivent dans un **ordre propre à chaque
partie**, puis le cycle recommence en plus coriace. Chacun a sa forme, ses attaques, une
**phase 2** à mi-vie (nouvelles variantes plus agressives) et son propre thème musical.
Une parade sur un contact étourdit le boss une seconde.

| Boss | Style | Attaques |
|---|---|---|
| Gardien du Puits | scarabée cuirassé | charge annoncée, bond écrasant ; phase 2 : ondes de choc au sol |
| L'Abbesse Engloutie | reine des spores | charge, bond, salve en éventail, anneau de spores (plus dense en phase 2) |
| La Reine Essaim | guêpe géante **volante** | piqués (enchaînés en phase 2), salve de dards visés, anneaux en spirale, invoque des volants |
| Le Colosse d'Os | géant d'ossements | poing au sol (ondes + rochers qui tombent), balayage du bras ; phase 2 : bond + rangée de piliers d'os |
| Le Ver des Profondeurs | ver **fouisseur** | s'enfouit, un sillon de poussière le trahit, jaillit sous toi en crachant de l'acide ; charge ; phase 2 : trois jaillissements + ondes |
| Le Chevalier Spectral | duelliste fantôme | estocs fulgurants (combos ×3 en phase 2), **téléportation dans ton dos**, piliers spectraux en ligne, salve de braises |

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
- **Combo** : trois coups d'affilée, le 3e est un **coup final** plus large et plus fort.
- **Coup chargé** : maintenir Frapper ~0,7 s (l'aiguille scintille) puis relâcher = **tourbillon**
  qui touche tout autour (gros dégâts).
- **Estoc** : frapper **pendant (ou juste après) une ruée** = estoc perçant en ligne droite.
- **Sort d'âme** : lame d'âme lancée devant soi, qui **traverse** les ennemis (coûte 33 d'âme,
  comme un soin — à toi de choisir).
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

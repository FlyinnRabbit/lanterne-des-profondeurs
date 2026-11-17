# Lanterne des Profondeurs

<p align="center"><img src="docs/banner.jpg" width="900" alt="Le héros sous la Lanterne, entouré des gardiens des profondeurs"></p>

[English](README.md) · **Français** · [Español](README.es.md) · [Deutsch](README.de.md)

Roguelite metroidvania 2D pour **Godot 4.3+**, inspiré de Hollow Knight : grottes sombres, combat
à l'aiguille, rebonds sur les ennemis, soin avec l'âme, bancs de repos et dix boss.
Tout est dessiné en code : le jeu ne contient aucune image.

**Jouer dans le navigateur : https://flyinnrabbit.github.io/lanterne-des-profondeurs/**

## Bande-annonce

<p align="center"><a href="docs/video/trailer_fr.mp4"><img src="docs/video/preview.gif" width="820" alt="Aperçu de la bande-annonce : cliquer pour la regarder"></a></p>

<p align="center"><b><a href="docs/video/trailer_fr.mp4">▶ Regarder la bande-annonce (80 s)</a></b> · <a href="docs/booklet/booklet_fr.pdf">Livret (PDF, 10 pages)</a></p>

## Le but

Autrefois, la Lanterne des Profondeurs éclairait chaque palier jusqu'au fond du monde. Sa flamme s'est
éteinte. Depuis le **Sanctuaire**, prends l'ascenseur et descends palier après palier, vaincs le gardien
de chacun et **rallume la Lanterne**, puis remonte vivant. Chaque chute te ramène au Sanctuaire : ton
ombre garde les éclats perdus là où tu es tombé, et l'ascenseur se souvient de ta profondeur.

<p align="center"><img src="docs/screenshots/surface.jpg" width="820" alt="La lumière touche enfin la surface"></p>

## En bref

- **9 biomes** ; les niveaux sont générés à chaque descente, avec grottes, strates sur trois étages et treuils
- **10 boss** : 6 gardiens de palier et 4 boss finaux, chacun avec une phase 2 et sa musique
- **Combat** : combos en 3 coups, tourbillon chargé, combo aérien, pogo, attaque plongée, estoc en ruée, parade (parfaite = coup critique), lame d'âme, ultime
- **5 armes** améliorées chez la forgeronne (les Griffes Jumelles se portent aux deux mains), **21 emblèmes**
- **Le Sanctuaire** : marchand, arsenal, forgeronne, cartographe, tailleuse (53 cosmétiques), ancien et quatre fêtes dans l'année
- **4 difficultés** et un mode une seule vie, malédictions, **Descente du jour** avec classement en ligne, **Défi des boss**
- Français, anglais, espagnol et allemand ; clavier et manette Xbox ; navigateur, Windows, macOS, Linux et Steam Deck ; mises à jour automatiques
- Tout est dessiné en code ; musique et sons originaux

## Captures d'écran

| | |
|---|---|
| ![Le Sanctuaire et ses habitants](docs/screenshots/sanctuary.jpg) | ![L'ascenseur descend vers le palier suivant](docs/screenshots/lift_descent.jpg) |
| ![Parade parfaite à l'Ossuaire, en Cauchemar](docs/screenshots/nightmare_parry.jpg) | ![La Lanterne rallumée](docs/screenshots/lantern_rekindled.jpg) |
| ![Les Jardins Fongiques](docs/screenshots/fungal_gardens.jpg) | ![La Forge Ardente](docs/screenshots/blazing_forge.jpg) |
| ![Les Mines de Cristal](docs/screenshots/crystal_mines.jpg) | ![L'Abîme Gelé](docs/screenshots/frozen_abyss.jpg) |
| ![La Bibliothèque Silencieuse](docs/screenshots/silent_library.jpg) | ![La Ruche Bourdonnante](docs/screenshots/humming_hive.jpg) |
| ![Le Cerbère des Profondeurs](docs/screenshots/boss_cerberus.jpg) | ![Le Colosse d'Os](docs/screenshots/boss_bone_colossus.jpg) |
| ![La Reine Essaim](docs/screenshots/boss_swarm_queen.jpg) | ![Effets de combat et projectiles](docs/screenshots/combat_effects.jpg) |
| ![La carte, un parchemin perdu avec sa légende](docs/screenshots/map.jpg) | ![L'arsenal du Sanctuaire](docs/screenshots/arsenal.jpg) |
| ![La tailleuse du Sanctuaire](docs/screenshots/seamstress.jpg) | ![La garde-robe](docs/screenshots/wardrobe.jpg) |
| ![Quelques tenues](docs/screenshots/outfits.jpg) | ![Les styles d'ultime](docs/screenshots/ultimates.jpg) |

**Les fêtes au Sanctuaire** (Saint-Valentin, Pâques, Veillée des Ombres, Noël)

![Les quatre fêtes](docs/screenshots/festivals.jpg)

**Écrans de chargement** (lancement, entrée dans une boutique, ascenseur)

| | | |
|---|---|---|
| ![Lancement](docs/screenshots/loading_launch.jpg) | ![Entrée dans une boutique](docs/screenshots/loading_shop.jpg) | ![L'ascenseur](docs/screenshots/loading_lift.jpg) |

*Les captures montrent l'interface en anglais ou en français ; le jeu est en français, anglais, espagnol et allemand.*

## Télécharger et jouer

Le jeu existe en français, anglais, espagnol et allemand.

### Navigateur (PC, Xbox, tablette)
**https://flyinnrabbit.github.io/lanterne-des-profondeurs/** — mis à jour automatiquement à chaque envoi.
Clavier, souris et manette fonctionnent ; les sauvegardes restent dans le navigateur.
- **Xbox Series** : ouvrir **Microsoft Edge**, aller à l'adresse ci-dessus, puis passer en plein écran.
- Le premier chargement télécharge environ 55 Mo.
- Dans le navigateur, les noms de touches suivent le clavier QWERTY par défaut : choisir AZERTY dans
  **Commandes → Clavier** si besoin.

### Windows
Dernière version : onglet **Releases** → `LanterneDesProfondeurs_Windows.zip`, décompresser, lancer
`LanterneDesProfondeurs.exe`. L'exécutable n'est pas signé : Windows SmartScreen peut afficher
« Windows a protégé votre ordinateur » → *Informations complémentaires* → *Exécuter quand même*.

### macOS (Intel et Apple Silicon)
1. Télécharger `LanterneDesProfondeurs_macOS.zip` dans la Release, le décompresser et glisser
   **Lanterne des Profondeurs** dans le dossier Applications.
2. L'application n'est pas notariée par Apple (il faudrait un compte développeur payant) : macOS la
   bloque au premier lancement.
   - **clic droit (ou Ctrl + clic) sur l'application → Ouvrir**, puis **Ouvrir** dans la fenêtre ;
   - sur **macOS 15 (Sequoia)** et suivants : lancer l'application une fois, puis **Réglages Système →
     Confidentialité et sécurité** → en bas, **« Ouvrir quand même »** ;
   - si macOS dit que « l'application est endommagée », ouvrir le **Terminal** et taper :
     `xattr -cr "/Applications/Lanterne des Profondeurs.app"`, puis relancer.
3. Ensuite le jeu se lance normalement. Les manettes Xbox et PlayStation fonctionnent.
   Sauvegardes : `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs/`.

### Linux et Steam Deck
Dans les Releases : `LanterneDesProfondeurs_Linux_SteamDeck.tar.gz` (Linux x86_64).

**Linux** : extraire l'archive, puis lancer `./LanterneDesProfondeurs.x86_64`
(si besoin : clic droit → Propriétés → « Autoriser l'exécution », ou `chmod +x`).

**Steam Deck** :
1. Passer en **mode Bureau** (bouton Steam → Alimentation → Passer au bureau).
2. Télécharger l'archive depuis la page Releases avec le navigateur et l'extraire
   (clic droit → *Extraire ici*), par exemple dans `~/Games/Lanterne`.
3. Ouvrir Steam en mode Bureau → *Jeux* → **Ajouter un jeu non-Steam à ma bibliothèque**
   → *Parcourir* → choisir `LanterneDesProfondeurs.x86_64` → *Ajouter les programmes sélectionnés*.
4. Revenir en **mode Jeu** : le jeu est dans la bibliothèque (onglet *Non-Steam*).
   Il démarre en plein écran, les commandes du Deck marchent directement
   (A sauter, X frapper, RT ruée, LB parade, Y ultime, B soin) et l'écran 16:10 est rempli.
   L'icône `LanterneDesProfondeurs.png` fournie peut être choisie dans les propriétés du raccourci.

### Version portable
`LanterneDesProfondeurs_Windows_Portable.zip` / `LanterneDesProfondeurs_Linux_Portable.tar.gz` :
le jeu accompagné d'un fichier `portable.txt`. Tant que ce fichier reste à côté de l'exécutable,
progression, réglages et touches sont enregistrés dans le dossier `sauvegardes` du jeu (rien n'est
écrit ailleurs) : copiez le dossier sur une clé USB pour emporter le jeu et votre partie.
Supprimez `portable.txt` pour revenir à l'emplacement habituel des sauvegardes.

### Lancer le projet dans Godot
1. Installer Godot 4 (version standard, pas .NET) : https://godotengine.org/download
2. Dans le gestionnaire de projets : **Importer** → choisir le dossier du projet (le fichier `project.godot`).
3. Appuyer sur **F5**.

Pour l'exporter soi-même : *Éditeur → Gérer les modèles d'exportation → Télécharger et installer*,
puis *Projet → Exporter* et choisir un des préréglages déjà présents (Windows Desktop, Linux, macOS, Web).

## Commandes (clavier et manette Xbox / XInput)

Les touches sont enregistrées **par position** sur le clavier : on se déplace avec **Z Q S D** en AZERTY
et **W A S D** en QWERTY et QWERTZ, sans rien régler. Les noms affichés suivent la disposition du système ;
si elle est mal détectée (machine virtuelle, Steam Deck…), choisir **Commandes → Clavier : AZERTY /
QWERTY / QWERTZ**. Le tableau utilise les noms AZERTY.

| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Q / D ou flèches | Stick gauche / croix |
| Sauter (maintenir = plus haut) | Espace | A |
| Frapper | J ou **clic gauche** | X |
| Frapper vers le haut / le bas | Z ou S + J | haut/bas + X |
| S'accroupir (esquive les attaques hautes) | S ou flèche bas (maintenir, au sol) | bas |
| Piqué (en l'air) | S + K | bas + RT |
| Ruée / esquive | K ou Maj | RT |
| Parade | I ou **clic droit** | LB |
| Sort d'âme (33 d'âme) | O ou clic molette | RB |
| Ultime (jauge pleine) | U ou R | Y |
| Se soigner (maintenir, 33 d'âme) | L ou F | B |
| Se reposer sur un banc | Z / flèche haut | haut |
| Carte | M | R3 |
| **Pause et menu** | **Échap ou P** | **Menu (Start)** |
| **Inventaire / équipement** | **Tab ou B** | **Affichage (Back)** |

### Menu « Commandes »
Échap → **Commandes** : cliquer (ou valider à la manette) une case, puis appuyer sur la nouvelle touche.
Chaque action a 2 touches clavier et 1 bouton de manette ; si la touche est déjà prise, les deux actions
sont échangées. Suppr efface une touche clavier, Échap annule. Les cases acceptent aussi les boutons
de la souris (gauche, droit, molette, boutons latéraux). Menus et inventaire se pilotent à la souris ;
en jeu, le curseur se cache après 2 secondes d'immobilité.
Les réglages sont enregistrés automatiquement (`user://controls.cfg`). Le stick gauche déplace toujours le héros.

### Icônes de commandes
Les aides à l'écran, panneaux, messages et le menu Commandes montrent des **icônes** : touches et
boutons de souris dessinés pour le clavier, A/B/X/Y colorés, LB/RT… pour une manette Xbox, et croix /
rond / carré / triangle, L1/R2… pour une manette PlayStation (symboles génériques).

### Manette (XInput)
Sous Windows, Godot lit les manettes Xbox par XInput : il suffit d'en brancher une. Le jeu affiche
la manette détectée, utilise les noms de boutons Xbox, accepte les gâchettes dans les menus et vibre
aux coups, aux dégâts et pendant les boss. La vibration se coupe dans le menu Commandes. Les aides
à l'écran suivent le dernier appareil utilisé (clavier ou manette).

## Sauvegardes et difficulté

**3 emplacements de sauvegarde** : écran-titre → « Parties ». Chaque emplacement a sa propre partie et
sa propre difficulté (par exemple une partie Normale et une partie Cauchemar côte à côte). « Continuer »
reprend le dernier emplacement joué. Succès, cosmétiques et options sont communs à tous les emplacements.
La sauvegarde est automatique.

Au lancement : **Jouer** → choisir la difficulté (et l'option « Passer le tutoriel »).
Aussi possible en cours de partie : Pause → « Nouvelle partie… ».

**Une seule vie** (case à cocher à la création de la partie, dans toutes les difficultés) : la première mort
efface l'emplacement (hors tutoriel). Un petit crâne à côté des éclats le rappelle. Les succès et les
cosmétiques sont gardés, car ils sont communs à toutes les parties.

| Difficulté | Âme / ultime | Ennemis | Dégâts reçus |
|---|---|---|---|
| Facile | +35 % / +30 % | plus lents, -25 % de vie, moins nombreux, aucune élite | 1 |
| Normal | normal | normaux ; élites : 8 % au début, jusqu'à 35 % en profondeur | 1 |
| Difficile | -25 % / -20 % | +25 % de vitesse, plus agressifs, +35 % de vie, +35 % d'ennemis ; élites : de 25 % à 65 % | 1 |
| Cauchemar | -40 % / -35 % | +40 % de vitesse, très agressifs, +60 % de vie, +60 % d'ennemis ; élites : de 42 % à 85 % | **2** |

Les boss sont eux aussi plus rapides et plus résistants selon la difficulté, mais leurs préparations ne
descendent jamais sous 0,25 s : même en Cauchemar, chaque attaque se lit et s'esquive. Un boss n'a jamais
plus de 3 sbires invoqués en vie à la fois, et n'essaie pas d'invoquer quand son essaim est complet.

**Éclats** : chaque ennemi en donne 10 % de plus par palier (palier 6 : +50 %), le double pour une élite,
et le boss en donne 60 + 20 × palier. En Facile, où les ennemis sont moins nombreux et sans élites, ils en
donnent 40 % de plus et le boss 10 % de plus : on progresse à peu près au même rythme qu'en Normal.
Difficile et Cauchemar rapportent davantage, grâce à leurs ennemis et élites en plus.

## Le Sanctuaire et les paliers sans fin

Après le tutoriel, on arrive au **Sanctuaire de la Lanterne**, le cœur du jeu :
- **Banc** : se reposer, récupérer sa vie, changer d'emblèmes. En descente, chaque banc ne soigne qu'une
  fois par niveau (on peut s'y rasseoir pour le point de réapparition et les emblèmes), et pas juste après
  un combat (1,5 s).
- **Marchand** : échange des éclats contre des **masques de vie** (+1 vie maximale, jusqu'à 4), des
  **encoches** d'emblèmes et les **emblèmes** pas encore trouvés.
- **Arsenal** : acheter et équiper son arme de base. **Essayer** prête une arme tant qu'on reste au Sanctuaire.
- **Mannequin d'entraînement** (à droite de l'arsenal) : affiche les dégâts par seconde.
- **Tailleuse** (à gauche du banc) : la garde-robe et les cosmétiques.
- **Ascenseur** : choisir le **palier** où descendre.
- Des **habitants** arrivent au fil des paliers : la **forgeronne** (palier 1, forge tes armes au niveau 2), le
  **cartographe** (palier 2, vend une plume qui révèle toute la carte) et l'**ancien** (palier 3,
  l'histoire de la Lanterne).

Ta vie est conservée au portail entre les deux niveaux d'un palier (Facile et Normal rendent 1 masque,
Difficile et Cauchemar rien).

Un **palier = 2 niveaux générés** (biomes tirés au sort parmi 9) **puis un boss**. Le terminer ramène
au Sanctuaire et **débloque le palier suivant**, sans fin. Plus on descend, plus les ennemis ont de vie,
de vitesse, d'agressivité et d'élites (environ ×1,9 de vie au palier 6, ×2,6 au palier 10).

**Mourir** pendant une descente : retour au Sanctuaire, et le butin ramassé depuis le départ (éclats,
emblèmes, encoches) est perdu, mais les paliers débloqués et les achats restent. Ton **ombre** garde les
éclats perdus là où tu es tombé : retourne au même palier et bats-la pour les récupérer (une nouvelle
mort la remplace).

Depuis l'ascenseur, on peut aussi :
- jouer n'importe quel palier avec une **malédiction** (Hâte, Obscurité, Fragilité) pour +50 à 60 % d'éclats ;
- jouer la **Descente du jour** (même niveau pour tout le monde, meilleur temps), avec un **classement en
  ligne** par difficulté : ton temps est envoyé à la fin avec le pseudo que tu choisis (Ascenseur →
  « Classement du jour »), et tu vois le top 10 et ton rang. L'envoi se coupe sur le même écran ;
- relever le **Défi des boss** (boss à la chaîne, chronométré) une fois le palier 6 terminé : +600 éclats à chaque fois, +200 de plus en battant ton meilleur temps, et une encoche d'emblème à la première victoire.

Il y a 29 **succès**, consultables depuis l'écran-titre ou le menu pause.

### Les 9 biomes

| Biome | Particularités |
|---|---|
| Les Profondeurs | grottes bleutées, collines et puits, rampants et volants |
| Les Jardins Fongiques | murs à escalader, puits, beaucoup de cracheurs |
| La Citadelle Engloutie | piliers au-dessus des pics, arènes, ponts |
| Les Mines de Cristal | larges gouffres (Ruée), couloirs bas, volants |
| La Forge Ardente | des pics partout, des braises, des rampants en nombre |
| La Bibliothèque Silencieuse | escalade et plateformes, nuées de volants |
| L'Abîme Gelé | neige, ponts fragiles et gouffres, cracheurs |
| La Ruche Bourdonnante | couloirs étroits envahis de volants |
| L'Ossuaire | collines et arènes, rampants et cracheurs |

### Profondeurs : grottes et strates

| | | |
|---|---|---|
| ![Grotte des Jardins Fongiques](docs/screenshots/grotto_gardens.jpg) | ![Grotte de la Bibliothèque Silencieuse](docs/screenshots/grotto_library.jpg) | ![Treuil au pied d'un puits (Mines de Cristal)](docs/screenshots/strata_winch.jpg) |

Les niveaux ne sont plus de simples bandes à plat :
- **Grottes** (tous les biomes) : des trous dans le chemin mènent à une grotte creusée sous le niveau,
  aménagée selon le biome (champignons géants, rayonnages, alvéoles, salle inondée, crypte d'os,
  stalagmites de cristal, pont de glace fragile, fosses de braises…). Chacune cache un **coffre**, des
  ennemis, et parfois un **marchand** ou un emblème.
- **Strates** (les Profondeurs, les Mines de Cristal, les Abysses Gelés, la Forge Ardente) : le niveau
  s'enfonce en trois étages. Le premier va vers la droite, le deuxième revient vers la gauche, le
  troisième repart vers la droite jusqu'à la sortie. Un large puits relie chaque étage au suivant.
- **Treuil** : au pied de chaque grotte et de chaque puits, une corde pend d'un treuil. **Haut** à côté
  te hisse en haut en ~1,5 s : pas besoin de refaire la fosse en plateforme.

### Salles spéciales
- **Trésor** : un sol fissuré cache un coffre ; le briser (coups vers le bas ou piqué).
- **Défi chronométré** : toucher la stèle au sablier, puis atteindre le drapeau en 13 secondes.
- **Arène d'élites** : réveiller l'autel, vaincre trois élites, gagner des éclats et un emblème.
- **Marchand itinérant** : parfois près du banc de mi-niveau (les achats comptent comme butin).

### Pièges et plateformes
Les niveaux ont du relief (le sol monte et descend d'une salle à l'autre) et des salles variées : îles
flottantes, puits en zigzag, doubles chemins, grottes basses, ponts fragiles, gouffres avec plateforme
mobile, couloirs de lames.
- **Totem à fléchettes** : tire à hauteur de tête — s'accroupir, sauter ou parer. Jamais près de l'arène d'un boss.
- **Lame pendulaire** : son point le plus bas passe juste au-dessus d'un héros accroupi.
- **Stalactite** : tombe quand on passe dessous.
- **Blocs fragiles** : s'effondrent peu après qu'on s'y pose, puis se reforment.
- **Plateforme mobile** : fait des allers-retours au-dessus d'un gouffre.
- Les pièges occupent au plus 50 % des salles, et les salles piégées ont moins d'ennemis.

## Combat

- **Combo au sol** : trois coups, le 3ᵉ est un **coup final** plus large et plus fort.
- **Coup chargé** : maintenir Frapper environ 0,7 s (l'aiguille scintille) puis relâcher = un
  **tourbillon** qui touche tout autour.
- **Estoc** : frapper **pendant (ou juste après) une Ruée** = un coup perçant en ligne droite.
- **Combo aérien** (différent du combo au sol) : taillade, **taillade montante** qui fait remonter,
  puis une **vrille** qui touche tout autour.
- **Piqué** : en l'air, bas + Ruée. On fonce vers le sol, on rebondit sur l'ennemi touché, ou on crée une
  **onde de choc** à l'atterrissage. Un par saut. Après un piqué on atterrit debout : on ne s'accroupit
  qu'une fois « bas » relâché.
- **S'accroupir** : maintenir bas au sol. Plus lent, mais les attaques hautes passent au-dessus (estoc
  du lancier, balayage du Colosse, fléchettes, lames pendulaires). Frapper accroupi = coup bas.
- **Sort d'âme** : une lame d'âme lancée devant soi qui **traverse** les ennemis (coûte 33 d'âme,
  autant qu'un soin — à toi de choisir).
- **Parade** : une courte fenêtre (0,2 s). Un contact paré étourdit l'ennemi ; un boss paré est étourdi
  une seconde. Une spore parée repart vers les ennemis. Rapporte de l'âme et beaucoup d'ultime.
- **Parade parfaite** : parer au tout dernier moment affiche « PARFAITE ! » ; une **lueur dorée** brille
  au bout de l'arme et le coup suivant est **critique : dégâts ×1,5** (arrondis au-dessus, toujours au moins +1).
- **Esquive** : pendant la Ruée, on traverse ennemis et projectiles (pas les pics).
- **Ultime** : la jauge dorée se remplit en frappant (+6) et en parant (+25). Pleine, le héros se fige,
  se charge une demi-seconde (invulnérable), puis libère une onde de choc : 8 dégâts à tout ce qui est
  proche, et les spores sont détruites.
- Un coup d'aiguille détruit aussi les spores ennemies.
- **Recul** : chaque coup repousse un peu le héros (environ 9 px sur les deux premiers coups du combo,
  24 px sur le coup final, aucun accroupi) : tout le combo atteint une cible qui ne bouge pas.
- **Annonces d'attaque** : un « ! » jaune au-dessus d'un ennemi qui prépare un coup ; orange avec une
  flèche quand c'est une attaque haute (s'accroupir).

### L'arsenal

| Arme | Prix | Style | Niveau 2 (forgeronne) |
|---|---|---|---|
| Aiguille du Veilleur | — | équilibrée | le coup final lance une courte lame d'air |
| Griffes Jumelles | 180 | une griffe à chaque main : chaque attaque frappe deux fois (0,5 dégât par griffe, 0,875 par griffe sur un coup puissant), très rapides, portée courte, moitié moins d'âme par griffe | saignée : chaque coup de griffe a 20 % de chances (50 % avec le Croc Sanglant) de faire perdre 1 vie de plus une seconde plus tard |
| Fouet de Ronces | 150 | très longue portée devant et vers le haut, un peu plus lent | attire les petits ennemis vers soi |
| Marteau d'Enclume | 220 | lent, +1 dégât, gros recul, étourdit | le coup final envoie une onde de choc des deux côtés (elle franchit les marches) |
| Étoiles de Lune (shurikens) | 260 | à distance ; coup final = 3 étoiles, tourbillon = 8 en cercle, estoc = une grande étoile perçante | elles reviennent comme un boomerang et touchent à nouveau |

Étoiles de Lune : au plus 3 étoiles simples à l'écran, moins d'âme par coup, et les boss n'encaissent
que 75 % des dégâts à distance.

### Emblèmes
Tab ouvre l'inventaire (le jeu se met en pause) : objets, éclats, statistiques et la grille des
**emblèmes** à trouver dans les niveaux. Chaque emblème coûte des encoches ; on en a 3 au départ, et on
en trouve (anneaux dorés) ou on en achète d'autres. On ne change d'équipement **qu'assis sur un banc**.

| Emblème | Coût | Effet |
|---|---|---|
| Aiguille Longue | 2 | portée des coups +40 % |
| Cœur de Verre | 2 | +2 masques de vie |
| Cape Rapide | 1 | course +12 %, Ruée deux fois plus vite rechargée |
| Coquille Épineuse | 2 | des épines blessent les ennemis proches quand on est touché |
| Miroir Parfait | 1 | fenêtre de parade de 0,35 s |
| Âme Vorace | 2 | plus d'âme et d'ultime à chaque coup |
| Concentration Vive | 1 | soin presque deux fois plus rapide |
| Force Brute | 3 | +1 dégât, mais coups 20 % plus lents |
| Météore Ardent | 2 | un piqué qui touche prépare un coup critique |
| Repos de l'Ombre | 2 | accroupi hors combat, l'âme remonte lentement jusqu'à 33 ; soin accroupi 1,5× plus rapide |
| Écho Parfait | 2 | une parade parfaite lance une lame d'âme gratuite |
| Pas Léger | 1 | traverser un piège sans être touché rapporte 5 éclats |
| Lame Rebond | 1 | rebondir sur un ennemi te propulse 25 % plus haut et rend 6 d'âme |
| Enclume Tombante | 2 | piqué +1 dégât, onde de choc 50 % plus large |
| Parade Tranchante | 2 | une parade réussie inflige 2 dégâts à l'attaquant |
| Ruée Spectrale | 2 | la Ruée blesse les ennemis traversés (1 dégât) |
| Récolte d'Âme | 1 | chaque ennemi vaincu rend 8 d'âme |
| Flair du Pilleur | 1 | coffres des grottes et cachettes : +60 % d'éclats |
| Nœud de Grimpeur | 1 | treuils deux fois plus rapides ; la première remontée de chaque treuil rend 33 d'âme |
| Dernier Souffle | 3 | un coup fatal te laisse à 1 masque, une fois par niveau |
| Croc Sanglant | 2 | +30 % de chances de faire saigner à chaque coup, avec toutes les armes (1 dégât une seconde plus tard) ; 50 % avec les Griffes niv. 2 |

Les effets sont définis dans `scripts/charms.gd` et appliqués dans `scripts/player.gd`.

## Ennemis
- **Rampant**, **Volant**, **Cracheur** : les bases — marche, piqués, tirs de spores.
- **Sauteur** : une sauterelle qui bondit sur toi.
- **Garde au bouclier** : bloque les coups de face. Frapper par-dessus, par derrière, ou avec l'ultime.
- **Bulbe explosif** : roule vers toi, s'allume et explose (blessant aussi les ennemis proches).
- **Tisseuse** : une araignée pendue au plafond qui se laisse tomber quand on passe dessous.
- **Lancier** : prend la pose puis porte un long estoc ; une parade l'étourdit.
- **Spectre** : disparaît (intouchable), réapparaît près de toi et lance un orbe lent.
- **Élites** (lueur rouge) : plus de vie, plus rapides, butin double et une attaque en plus — le rampant
  charge, le volant pique, le cracheur tire 3 spores, le sauteur enchaîne deux bonds, le garde charge
  avec son bouclier.

Aucun ennemi ne peut toucher à travers un mur. Les ennemis coriaces et les élites deviennent plus
fréquents en profondeur.

## Boss

Le Gardien vient toujours en premier ; les cinq autres arrivent dans un **ordre propre à chaque partie**,
puis le cycle recommence, plus dur. Chacun a sa forme, ses attaques, une **phase 2** à mi-vie et son
propre thème musical. Parer un contact étourdit le boss une seconde.

| Boss | Style | Attaques |
|---|---|---|
| Gardien du Puits | scarabée cuirassé | charge annoncée, bond écrasant ; phase 2 : ondes de choc au sol |
| L'Abbesse Engloutie | reine des spores | charge, bond, salve en éventail, anneau de spores (plus dense en phase 2) |
| La Reine Essaim | guêpe géante **volante** | piqués (enchaînés en phase 2), salve de dards visée, anneaux en spirale, appelle des volants |
| Le Colosse d'Os | géant d'ossements | coup de poing au sol (ondes + chute de rochers), balayage du bras ; phase 2 : bond + rangée de piliers d'os |
| Le Ver des Profondeurs | ver **fouisseur** | s'enfouit, une traînée de poussière le trahit, surgit sous toi en crachant de l'acide ; charge ; phase 2 : trois surgissements + ondes |
| Le Chevalier Spectral | duelliste fantôme | estocs éclair (combos ×3 en phase 2), **se téléporte dans ton dos**, piliers spectraux en ligne, salve de braises |

### Boss finaux
Au palier 7 (puis tous les 7 paliers), un boss final **tiré au sort pour chaque partie**, chacun avec
son thème :
- **L'Ombre de la Lanterne** : couronnes de braises, balayage à hauteur de tête, pluie de cendres,
  colonnes de lumière, spectres en phase 2.
- **Le Cerbère des Profondeurs** : souffle de braises des trois têtes, bond avec onde de choc, triple
  morsure à hauteur de tête (s'accroupir), un hurlement qui fait jaillir des flammes.
- **Le Centaure Archer** : galope d'un bout à l'autre de l'arène, salves de flèches, pluie de flèches
  annoncée au sol, coup de lance à hauteur de tête (s'accroupir), saute par-dessus le joueur.
- **L'Œil d'en Dessous** : tentacules qui jaillissent du sol, rayon qui balaie l'arène à hauteur de
  tête (s'accroupir) ou au ras du sol (sauter), spirales de spores, yeux volants.

Le vaincre lance **la fin** : la Lanterne se rallume, la lumière remonte palier par palier jusqu'au
Sanctuaire puis à la surface, et le générique défile. Ensuite, les paliers continuent.
Succès « Les quatre gardiens » : vaincre les quatre.

## Graphismes

Tout est dessiné en code, dans un style détaillé et peint :

- **roche** texturée par un shader propre à chaque biome (strates, pierre de taille, cristal, veines de
  lave, glace, alvéoles, ossements), plus sombre en profondeur, aux arêtes éclairées ;
- **sols décorés** selon le biome (herbe, champignons lumineux, cristaux, crânes, livres, bougies, neige,
  miel) et **fonds en parallaxe** sur trois plans avec brume et rayons de lumière ;
- **héros, ennemis, 10 boss et habitants du Sanctuaire** avec ombrages, reflets et détails ;
- **pièges, grilles, piliers d'attaque, portail de sortie** (un modèle par biome) et **la fin** ;
- **emblèmes** : chacun a son médaillon gravé et son icône ; les **coups d'arme** laissent des traînées peintes ;
- **ATH** : fiole d'âme en verre cerclée de laiton, masques peints, jauge d'ultime en laiton, cristal
  d'éclats facetté et mini-carte sur parchemin ;
- **menus et écran-titre** : fond peint (puits, lanterne, braises), panneaux de bois sombre et de laiton ;
- **effets de combat** : étoile d'impact, anneau de mort avec fumée et débris, éclats qui volent vers le
  héros, poussière à l'atterrissage, image rémanente de la Ruée, projectiles avec traînée ;
- **ambiance par biome** : spores et lucioles, neige, pages volantes, braises, feux follets, gouttes au
  plafond, lave qui bouillonne, amas de cristaux lumineux ;
- **carte** dessinée comme une carte perdue : parchemin déchiré, plié, taché et brûlé.

## Carte, options et accessibilité
- **Carte** (M / R3) : tout ce qu'on a découvert du niveau, avec un pictogramme et une légende pour
  chaque lieu trouvé (banc, sortie, marchand, habitants, coffres, emblèmes, autel, défi, ombre…).
  **Mini-carte** dans le coin en haut à droite (Options).
- **Langue** : Automatique (langue du système), Français, English, Español, Deutsch.
  Les traductions sont dans `tools/translations.py` ; `python3 tools/translations.py` régénère
  `scripts/translations.gd`.
- **Taille de l'ATH** (60–160 %) et **des menus** (60–130 %), **zoom de la caméra**, **plein écran**
  (aussi F11), **synchronisation verticale**.
- **Qualité graphique** : Haute, Équilibrée (sans rayons de lumière ni bancs de brume à l'arrière-plan,
  moitié moins de particules) ou Basse (arrière-plan lointain seul, plus de lumières 2D sauf celles du héros,
  ni particules ni vignette). Équilibrée par défaut sur Mac et dans le navigateur. Le changement est immédiat.
- **Barres de vie des ennemis** et **dégâts infligés** affichés brièvement en haut à droite.
- **Aides à l'écran**, **tremblement de l'écran** (0–150 %), **arrêt sur image** à l'impact, **vibrations** de la manette.
- **Accessibilité** : dangers en contraste élevé (daltonisme), s'accroupir en bascule, vitesse du jeu
  100 / 90 / 80 / 70 %.
- **Statistiques de la descente** (ennemis, dégâts, critiques, parades parfaites, coups reçus, temps)
  affichées au retour au Sanctuaire.

Tout est enregistré dans `user://settings.cfg`.

## Cosmétiques et garde-robe
La **tailleuse** du Sanctuaire (à gauche du banc) ouvre la garde-robe, où l'on change l'apparence du
héros avec un aperçu animé : **53 cosmétiques** dans 6 catégories, dont 21 de saison. Tout est purement
visuel et commun à tous les emplacements de sauvegarde. Les capes claires sont adoucies pour ne pas
éblouir sur les décors sombres.

| Catégorie | Exemples |
|---|---|
| Cape | ombre, braise, mousse, givre, améthyste, ivoire, Veilleur doré, nuit étoilée |
| Écharpe | sarcelle, écarlate, dorée, blanche, violette, braise vive |
| Couvre-chef | plume de corbeau, bougie, couronne de fleurs, couronne d'or, auréole, cornes d'os |
| Traînée et lueurs | couleur de la Ruée, de l'œil et des coups : braise, givre, spectre, or pur… |
| Familier | luciole, papillon de nuit, feu follet, petite lanterne, guêpe de la Reine (suit le héros, purement décoratif) |
| Ultime | apparence de l'onde de choc : onde dorée, nova de givre, brasier, éclipse, essaim spectral |

Trois façons de les obtenir :
- les **acheter** à la tailleuse contre des éclats (les plus courants) ;
- réussir un **succès** : la récompense est indiquée dans la liste des succès ;
- **battre un boss** : le Colosse, la Reine, le Chevalier, le Cerbère et l'Œil ont chacun un cosmétique
  rare (25 % de chance par victoire).

Il y a **29 succès**, dont plusieurs offrent un cosmétique, et « Calendrier du Veilleur » : ouvrir le
cadeau des quatre fêtes.

### Fêtes
Quatre fêtes reviennent chaque année, automatiquement, selon la date. Pendant chacune, le Sanctuaire
est décoré, un **cadeau** s'ouvre une fois par an (le couvre-chef de la fête et 50 éclats), et la
tailleuse vend la collection de la fête. Ce qui est gagné ou acheté reste toute l'année.

| Fête | Dates | Cadeau | En vente |
|---|---|---|---|
| Saint-Valentin | 8 – 16 février | serre-tête à cœurs | cape de roses, traînée cœur battant, petit cœur, ultime Coup de foudre |
| Pâques | de la semaine avant à la semaine après | oreilles de lapin | cape de printemps, poussin, ultime Éclosion |
| Veillée des Ombres | 20 octobre – 2 novembre | citrouille creusée | cape de la veillée, feu de citrouille, chauve-souris, ultime Nuée de chauves-souris |
| Noël | 1er décembre – 6 janvier | bonnet de Noël | cape de Noël, guirlande lumineuse, bois de renne, flocons, flocon vivant, ultime Étoile de Noël |

Chaque fête a sa **musique** au Sanctuaire et sur l'écran-titre, composée pour le jeu par
`tools/synth_fetes.py` (mêmes instruments que le reste de la bande-son, aucune mélodie existante).

Pour essayer une fête hors saison : lancer le jeu avec la variable d'environnement
`LANTERNE_EVENT=noel` (ou `halloween`, `valentin`, `paques`).

## Écrans de chargement
Tous dessinés en code, dans le style du jeu ; n'importe quelle touche les accélère.
- **Lancement** : dans le noir, une lanterne s'allume, des braises montent, puis le titre et une astuce
  apparaissent, avec une rangée de braises qui s'allument en guise de barre de progression, sur un
  crépitement de braises (synthétisé par le jeu).
- **Entrée dans une boutique** : deux battants de bois cloutés de laiton se ferment sur l'enseigne de
  l'habitant (bourse, enclume, carte et plume, parchemin, bobine, lames croisées), puis s'ouvrent sur le comptoir.
- **Ascenseur** : la cage, avec le héros dans sa tenue, descend un puits de pierre pendant que les chaînes
  cliquettent ; le numéro du palier est gravé sur une plaque de laiton sous la cage. Le niveau se construit
  pendant la descente et la cage s'arrête avec un choc sourd. Elle remonte au Sanctuaire après un palier
  terminé. Les chaînes sont un enregistrement libre de droits (`sfx/lift_chains.ogg`).

## Mises à jour automatiques
Au lancement, le jeu (Windows, macOS, Linux, Steam Deck) demande à GitHub quelle est la dernière
Release. Si elle est plus récente :
- un petit **patch** (scripts et shaders, quelques centaines de Ko) est téléchargé, puis appliqué au
  prochain lancement — l'écran-titre propose **« Mise à jour prête — redémarrer »** ;
- si le patch ne suffit pas (nouvelles musiques, nouvelle version de Godot), l'écran-titre affiche
  **« Version disponible — télécharger »** et ouvre la page de la Release.

Le numéro de version est affiché en bas de l'écran-titre. **Options → Mises à jour automatiques** coupe
le téléchargement (l'avis reste affiché). Sans réseau, rien ne se passe. Si le jeu ne démarre pas
correctement avec un patch, celui-ci est retiré au lancement suivant. La version navigateur est toujours
à jour. Détails : `scripts/updater.gd` ; le patch est fabriqué par le workflow de publication
(préréglage d'export « Patch »). Augmenter `config/data_gen` dans `project.godot` quand on ajoute des
musiques, des sons ou des images : les anciennes installations verront alors l'avis de téléchargement.

## Musique et sons
Une bande-son **originale** générée pour le jeu (libre de tout droit) : 29 morceaux en boucle dans
`music/` — un ou deux par biome qui s'enchaînent en fondu, un thème par boss, un pour le tutoriel, un
pour le Sanctuaire et un par fête. Les bruitages sont dans `sfx/`, avec des sons propres à chaque arme,
aux coups critiques et à la parade parfaite. Volumes **général / musique / effets** dans les Options ;
la musique baisse un peu quand le jeu est en pause.

## Modding
- Les cartes faites à la main sont dans `scripts/levels.gd` : ajouter une entrée à `LEVELS` pour créer
  un niveau (`#` roche, `^` pics, `c`/`f`/`s` ennemis, `B` banc, `D` orbe, `K` boss…).
- Les réglages du héros (vitesse, saut, Ruée, dégâts, recul) sont les constantes en tête de
  `scripts/player.gd`.

## Tests
`tests/test_run.gd` parcourt les niveaux automatiquement (entrées simulées, boss, menus) :
`godot --headless --fixed-fps 120 -s res://tests/test_run.gd`.
`tests/dump_maps.gd` génère des centaines de niveaux pour vérifier qu'ils sont tous faisables.

**Serveur du classement** : `server/` (Cloudflare Worker + D1), déployé par le workflow « Classement
(Cloudflare) » avec les secrets `CLOUDFLARE_API_TOKEN` et `CLOUDFLARE_ACCOUNT_ID`. `node server/test_worker.mjs`
le teste ; `node server/dev_server.mjs` le lance en local (jeu lancé avec
`LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787`).

## Licence
Code, musique (générée pour le jeu) et bruitages : licence **MIT** — voir `LICENSE`.
Exception : `sfx/lift_chains.ogg` provient de l'enregistrement *Chains Chiming* de freesound_community sur Pixabay (Pixabay Content License, utilisation libre, sans attribution requise).
Le jeu s'inspire de Hollow Knight (Team Cherry) mais n'en réutilise ni personnages ni ressources.

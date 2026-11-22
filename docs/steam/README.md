# Mise en place sur Steam

## Les éditions du jeu
Une seule base de code, trois éditions choisies à l'export (`scripts/edition.gd`, réécrit par le workflow) :

| Édition | Contenu | Mise à jour | Steam |
|---|---|---|---|
| Complète (dépôt, tests) | tout | automatique depuis GitHub | non |
| Démo (`DEMO`) — versions publiques depuis le fichier `PUBLIC_DEMO` | tutoriel + paliers 1 et 2, écran « Fin de la démo » | automatique depuis GitHub | non |
| Steam (`STEAM`) | tout | par Steam | succès Steam |
| Démo Steam (`DEMO` + `STEAM`) | comme la démo | par Steam | — |

Dans la démo : l'ascenseur s'arrête au palier 2 (un bouton « Palier 3 et au-delà » mène à l'écran de fin),
les modes spéciaux sont absents, l'écran-titre affiche « DÉMO ». Terminer le palier 2 ouvre l'écran
« Fin de la démo » au Sanctuaire avec « Ajouter à ma liste de souhaits ». La sauvegarde est la même que
celle du jeu complet : elle est reprise telle quelle après l'achat.

Pour tester la démo sans l'exporter : lancer le jeu avec la variable d'environnement `LANTERNE_EDITION=demo`.

## Construire
Actions → **Export Steam** → *Run workflow*. Trois artefacts : `Lanterne_Demo` (démo sans Steam, pour
itch.io ou GitHub), `Lanterne_Steam` (Windows, Linux, macOS) et `Lanterne_SteamDemo`. Le workflow ajoute
GodotSteam (GDExtension 4.15 pour Godot 4.1-4.3) ; il n'est pas dans le dépôt.

## À faire dans Steamworks
1. **Identifiant** : une fois l'app créée, mettre son numéro dans `STEAM_APP_ID` (`scripts/edition.gd`) :
   le bouton « Ajouter à ma liste de souhaits » ouvrira alors la page Steam (sinon la page GitHub).
2. **Succès** : les créer avec les noms d'API de [achievements.md](achievements.md) (généré par
   `python3 tools/steam_achievements.py > docs/steam/achievements.md`). Chacun demande deux icônes
   (obtenu / pas encore).
3. **Sauvegardes dans le cloud** : Steam Auto-Cloud, sans code. Fichiers `*.cfg` du dossier du jeu :
   - Windows : `%APPDATA%\Godot\app_userdata\Lanterne des Profondeurs`
   - Linux / Steam Deck : `~/.local/share/godot/app_userdata/Lanterne des Profondeurs`
   - macOS : `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs`

   Exclure `update/` (fichiers de mise à jour des versions GitHub).
4. **Options de lancement** : Windows `LanterneDesProfondeurs.exe`, Linux `LanterneDesProfondeurs.x86_64`,
   macOS `LanterneDesProfondeurs.app` (dans le zip de l'artefact).
5. **Dépôts (depots)** : téléverser les dossiers des artefacts avec SteamPipe (`steamcmd`), un dépôt par
   système.
6. **Questionnaire de contenu** : déclarer le contenu généré avec l'IA (graphismes, musique, textes et
   traductions créés avec un assistant IA avant la sortie ; rien n'est généré pendant le jeu).

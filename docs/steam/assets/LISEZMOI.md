# Visuels Steam

Tout est prêt aux dimensions exactes demandées par Steamworks.

| Fichier | Emplacement dans Steamworks |
|---|---|
| `header_capsule_920x430.jpg` | Magasin → Capsule d'en-tête |
| `small_capsule_462x174.jpg` | Magasin → Petite capsule |
| `main_capsule_1232x706.jpg` | Magasin → Capsule principale |
| `vertical_capsule_748x896.jpg` | Magasin → Capsule verticale |
| `page_background_1438x810.jpg` | Magasin → Arrière-plan de la page (facultatif) |
| `app_icon_184x184.jpg` | Icône de l'application (communauté) |
| `library_capsule_600x900.jpg` | Bibliothèque → Capsule |
| `library_header_920x430.jpg` | Bibliothèque → En-tête |
| `library_hero_3840x1240.png` | Bibliothèque → Image héros (sans texte) |
| `library_logo_1280x720.png` | Bibliothèque → Logo (fond transparent ; le placer en bas à gauche du héros) |
| `screenshots/` | Captures d'écran (12, en 1920×1080 ; Steam en demande au moins 5) |
| `achievements/` | Icônes des succès : `ACH_<ID>.jpg` (obtenu) et `ACH_<ID>_locked.jpg` (pas encore), 256×256 |

**Version anglaise** : le dossier `en/` contient les mêmes visuels avec le titre « Lantern of the Depths »
(capsules, en-tête et capsule de bibliothèque, logo). Dans Steamworks, sur chaque visuel, choisir la langue
« English » avant de téléverser la version de `en/` ; la version française reste celle par défaut. Le héros de
bibliothèque, le fond de page, l'icône et les captures sont communs à toutes les langues.

Le titre n'est jamais en haut à gauche des capsules : Steam y pose son bandeau « Démo » ou « Promo ».

## Refaire les visuels
1. Illustrations en 4K (rendu du jeu) :
   `xvfb-run -a -s "-screen 0 3840x2160x24" godot --path . --resolution 3840x2160 -s tools/steam/keyart.gd`
   (écrit dans `/tmp/keyart/` ; arguments possibles : `title`, un identifiant de boss, `biomes`).
2. Capsules, logo, icône et captures : `cd tools/steam && python3 compose.py` (écrit dans `out/`) ;
   `python3 compose.py en` pour la version anglaise (`out/en/`).
3. Icônes des succès : `cd tools/steam && python3 ach.py` (pictogrammes : Noto Color Emoji).

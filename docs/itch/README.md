# La démo sur itch.io

Page publique : https://flyinrabbit.itch.io/lantern-of-the-depths-demo (variable `ITCH_GAME` = `flyinrabbit/lantern-of-the-depths-demo`).

## Créer la page (une fois)
1. Créer un compte sur **itch.io** (gratuit), puis *Tableau de bord* → **Créer un nouveau projet**.
2. Réglages :
   - **Titre** : Lanterne des Profondeurs (Démo)
   - **URL du projet** : par exemple `lanterne-des-profondeurs`
   - **Type de projet** : **HTML** (le jeu se lance dans la page ; les téléchargements sont proposés en plus)
   - **Classification** : Jeux
   - **Prix** : *Gratuit* (ou « Pas de paiement »)
   - **Intégration** : taille de la fenêtre **1280 × 720**, cocher **Bouton plein écran** et
     **Mobile friendly : non** ; ne pas cocher *SharedArrayBuffer* (inutile)
   - **Genre** : Plateformes · **Tags** : metroidvania, roguelite, platformer, 2D, souls-like, dark-fantasy,
     godot, procedural-generation, singleplayer, controller
   - **Entrées / contrôles** : clavier, manette (Xbox, PlayStation)
   - **Langues** : français, anglais, espagnol, allemand
   - **Couverture** : `cover_630x500.jpg` ; **captures** : 4 ou 5 de `docs/steam/assets/screenshots/`
   - **Bannière** (Modifier le thème) : `banner_960x300.jpg`
   - **Trailer** : le lien YouTube du trailer, une fois mis en ligne
3. **Fichiers** : les quatre paquets de l'artefact `Lanterne_Demo_itch` du workflow « Export Steam »
   (Actions → Export Steam → Run workflow) :
   - `Lanterne_Demo_Web.zip` → cocher **« This file will be played in the browser »**
   - `Lanterne_Demo_Windows.zip` → Windows ; `Lanterne_Demo_Linux.tar.gz` → Linux ;
     `Lanterne_Demo_macOS.zip` → macOS
4. Enregistrer en **Brouillon**, vérifier la page, puis passer en **Public**.

## Envoi automatique (facultatif)
Pour que chaque export envoie la démo sur itch.io sans rien faire à la main :
1. itch.io → *Paramètres* → *Clés d'API* → **Générer une clé**.
2. GitHub → dépôt → *Settings* → *Secrets and variables* → *Actions* :
   - onglet **Secrets** → *New repository secret* : nom `BUTLER_API_KEY`, valeur : la clé
     (ne la colle nulle part ailleurs, pas même dans une conversation) ;
   - onglet **Variables** → *New repository variable* : nom `ITCH_GAME`, valeur `ton-pseudo-itch/lanterne-des-profondeurs`.
3. Lancer « Export Steam » : la démo part sur les canaux `windows-demo`, `linux-demo`, `mac-demo` et
   `html5-demo`. Sur itch.io, cocher « played in the browser » pour `html5-demo` (une seule fois).

---

## Texte de la page (français)

> **La Lanterne s'est éteinte au fond du monde.**
>
> Lanterne des Profondeurs est un metroidvania rogue-lite exigeant : depuis le Sanctuaire, descends palier
> après palier dans des niveaux générés à chaque partie, pare au dernier moment, enchaîne les combos et
> affronte les gardiens.
>
> **Cette démo contient** le tutoriel et les paliers 1 et 2 : deux gardiens, des niveaux tirés parmi les 12 biomes,
> le Sanctuaire et ses habitants, la forge, les emblèmes. Ta sauvegarde est reprise dans le jeu complet.
>
> **Le jeu complet** : 12 biomes, 10 boss, 12 champions géants, 7 armes, 42 emblèmes, 4 difficultés et un mode
> une seule vie, la Descente du jour et le Défi de la semaine avec classements en ligne, le Défi des boss, un
> duel local à deux… et des paliers sans fin. Bientôt sur Steam : ajoute-le à ta liste de souhaits !
>
> Clavier ou manette · français, English, español, Deutsch

## Page text (English)

> **The Lantern has gone out at the bottom of the world.**
>
> Lantern of the Depths is a demanding roguelite metroidvania: from the Sanctuary, descend tier after tier
> through levels generated every run, parry at the last moment, chain combos and face the guardians.
>
> **This demo includes** the tutorial and tiers 1 and 2: two guardians, levels drawn from all 12 biomes, the
> Sanctuary and its residents, the forge and the charms. Your save carries over to the full game.
>
> **The full game**: 12 biomes, 10 bosses, 12 giant champions, 7 weapons, 42 charms, 4 difficulties and a
> one-life mode, Daily Descent and Weekly Challenge with online leaderboards, a Boss Rush, a local two-player
> duel… and endless tiers. Coming soon to Steam: add it to your wishlist!
>
> Keyboard or gamepad · français, English, español, Deutsch

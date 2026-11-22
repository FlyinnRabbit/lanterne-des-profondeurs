# Versions gratuites : la démo

Depuis la v2.9.43, le fichier `PUBLIC_DEMO` à la racine du dépôt fait des versions publiques gratuites
(Releases GitHub et navigateur) la **démo** : le tutoriel et les paliers 1 et 2. Les workflows « Export Windows »
et « Version web » le lisent avant d'exporter.

- **Joueurs qui avaient le jeu complet** : la mise à jour automatique leur installe la démo. Leur sauvegarde
  est gardée telle quelle (paliers débloqués, éclats, emblèmes) ; l'ascenseur s'arrête simplement au palier 2,
  et le reste les attend dans la version Steam, qui lit les mêmes fichiers de sauvegarde.
- **La démo continue de se mettre à jour** depuis GitHub, comme avant.
- **Le jeu complet** n'est plus construit que par le workflow « Export Steam » (fichiers privés).

## Le jour où la page Steam est en ligne
Mettre le numéro du jeu dans `STEAM_APP_ID` (`scripts/edition.gd`) et publier : le bouton « Le jeu complet »
de l'écran-titre et « Ajouter à ma liste de souhaits » de la fin de démo ouvrent alors la page Steam.

## Revenir au jeu complet gratuit
Supprimer `PUBLIC_DEMO` et publier.

## Variante (non utilisée) : laisser le jeu complet aux joueurs actuels
`STEAM_MOVE := true` dans `scripts/edition.gd` publie une dernière version complète qui annonce « Le jeu
continue sur Steam » et coupe sa mise à jour automatique ; les versions suivantes peuvent alors être la démo
sans toucher ces joueurs.

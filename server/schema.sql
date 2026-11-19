-- Classements : un meilleur temps par joueur, par graine et par difficulté.
--   graine AAAAMMJJ : Descente du jour ; AAAASS (année + semaine ISO) : Défi de la semaine ; 1 : Défi des boss.
CREATE TABLE IF NOT EXISTS scores (
  seed INTEGER NOT NULL,          -- AAAAMMJJ (graine du jour)
  diff INTEGER NOT NULL,          -- 0 Facile … 3 Cauchemar
  player_id TEXT NOT NULL,        -- identifiant aléatoire de l'installation
  name TEXT NOT NULL,             -- pseudo choisi par le joueur
  time REAL NOT NULL,             -- secondes
  version TEXT,
  updated INTEGER NOT NULL,       -- horodatage (s)
  PRIMARY KEY (seed, diff, player_id)
);
CREATE INDEX IF NOT EXISTS scores_board ON scores (seed, diff, time);
-- Limite d'envois par adresse (adresse hachée, jamais stockée en clair).
CREATE TABLE IF NOT EXISTS hits (
  ip_hash TEXT NOT NULL,
  day INTEGER NOT NULL,
  n INTEGER NOT NULL,
  PRIMARY KEY (ip_hash, day)
);
-- Fantôme (parcours enregistré) du meilleur temps de chaque joueur, pour le jour et la semaine.
CREATE TABLE IF NOT EXISTS ghosts (
  seed INTEGER NOT NULL,
  diff INTEGER NOT NULL,
  player_id TEXT NOT NULL,
  data TEXT NOT NULL,
  PRIMARY KEY (seed, diff, player_id)
);
-- Petites valeurs du serveur (ex. dernier jour où le code Discord du jour a été posté).
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

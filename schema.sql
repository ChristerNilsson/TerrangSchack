PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS spelare (
  id       INTEGER PRIMARY KEY,
  namn     TEXT NOT NULL,
  telefon  TEXT NOT NULL,
  mail     TEXT NOT NULL UNIQUE,
  latitud  REAL,
  longitud REAL
);

CREATE TABLE IF NOT EXISTS parti (
  id          INTEGER PRIMARY KEY,
  latitud     REAL NOT NULL,
  longitud    REAL NOT NULL,
  rotation    INTEGER NOT NULL DEFAULT 0 CHECK (rotation >= 0 AND rotation < 360 AND rotation % 10 = 0),
  storlek     INTEGER NOT NULL CHECK (storlek > 0),
  vit_id      INTEGER NOT NULL REFERENCES spelare(id),
  svart_id    INTEGER NOT NULL REFERENCES spelare(id),
  inkrement   INTEGER NOT NULL DEFAULT 0 CHECK (inkrement >= 0),
  vit_tid     INTEGER NOT NULL CHECK (vit_tid >= 0),
  svart_tid   INTEGER NOT NULL CHECK (svart_tid >= 0),
  status      TEXT NOT NULL DEFAULT 'pågår'
              CHECK (status IN ('pågår', 'remi', 'vit vinst', 'svart vinst')),
  CHECK (vit_id <> svart_id)
);

CREATE TABLE IF NOT EXISTS drag (
  parti_id   INTEGER NOT NULL REFERENCES parti(id) ON DELETE CASCADE,
  nummer     INTEGER NOT NULL CHECK (nummer > 0),
  franruta   TEXT NOT NULL CHECK (franruta GLOB '[a-h][1-8]'),
  tillruta   TEXT NOT NULL CHECK (tillruta GLOB '[a-h][1-8]'),
  PRIMARY KEY (parti_id, nummer)
);

CREATE INDEX IF NOT EXISTS drag_parti_idx ON drag(parti_id, nummer);

-- Exempeldata för det parti som visas i klienten.
INSERT OR IGNORE INTO spelare (id, namn, telefon, mail, latitud, longitud) VALUES
  (1, 'Maja Lind', '+46 70 123 45 67', 'maja@example.se', 59.26914954, 18.14776681),
  (2, 'Erik Holm', '+46 70 987 65 43', 'erik@example.se', 59.27097982, 18.15197383);

INSERT OR IGNORE INTO parti (
  id, latitud, longitud, rotation, storlek,
  vit_id, svart_id, inkrement, vit_tid, svart_tid, status
) VALUES (
  1, 59.26996327, 18.14979067, 20, 800,
  1, 2, 30, 5262, 5118, 'pågår'
);

INSERT OR IGNORE INTO drag (parti_id, nummer, franruta, tillruta) VALUES
  (1, 1, 'e2', 'e4'),
  (1, 2, 'g8', 'f6'),
  (1, 3, 'f6', 'e4');

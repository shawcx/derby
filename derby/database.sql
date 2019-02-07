
--
-- Server settings
--
CREATE TABLE settings (
    "name"        TEXT    NOT NULL UNIQUE,
    "value"       TEXT
    );

--
-- Login accounts
--
CREATE TABLE racers (
    "name"            TEXT    NOT NULL UNIQUE,
    "den"             TEXT    NOT NULL,
    "car"             TEXT    NOT NULL,
    "avatar"          BLOB,   -- JPEG of racer or avatar
    "time1"           TEXT,
    "time2"           TEXT,
    "time3"           TEXT,
    "time4"           TEXT,
    "racer_id"        INTEGER PRIMARY KEY
    );

--
-- Friendly names for managing multiple accounts
--
CREATE TABLE times (
    "timestamp"      TEXT NOT NULL UNIQUE,
    "racer_id"       INTEGER NOT NULL,
    "time_id"        INTEGER PRIMARY KEY,
    FOREIGN KEY(racer_id) REFERENCES racers(id)
    );

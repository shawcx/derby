
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
    "avatar"          BLOB,   -- JPEG of racer or avatar
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

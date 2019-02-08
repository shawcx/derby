
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
    "avatar"          TEXT,   -- JPEG of racer or avatar

    "count"           TEXT,
    "time1"           TEXT,
    "time2"           TEXT,
    "time3"           TEXT,
    "time4"           TEXT,
    "lane1"           TEXT,
    "lane2"           TEXT,
    "lane3"           TEXT,
    "lane4"           TEXT,
    "total"           TEXT,

    "racer_id"        INTEGER PRIMARY KEY
    );

--
-- Friendly names for managing multiple accounts
--
CREATE TABLE times (
    "racer_id"       INTEGER NOT NULL,
    "lane"           TEXT,
    "time"           TEXT,
    "time_id"        INTEGER PRIMARY KEY,
    FOREIGN KEY(racer_id) REFERENCES racers(id)
    );

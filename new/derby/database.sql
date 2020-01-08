
--
-- Server settings
--
CREATE TABLE settings (
    "name"     TEXT NOT NULL UNIQUE,
    "value"    TEXT
    );

--
-- Groups
--
CREATE TABLE dens (
    "name"   TEXT NOT NULL UNIQUE,
    "den_id" INTEGER PRIMARY KEY
    );

--
-- Events
--
CREATE TABLE events (
    "name"     TEXT NOT NULL UNIQUE,
    "date"     TEXT NOT NULL,
    "event_id" INTEGER PRIMARY KEY
    );

--
-- Contestants
--
CREATE TABLE racers (
    "name"     TEXT    NOT NULL UNIQUE,
    "den_id"   INTEGER NOT NULL,
    "car"      TEXT    NOT NULL,
    "avatar"   TEXT, -- JPEG of racer or avatar

    "count"    INTEGER,
    "time1"    TEXT,
    "time2"    TEXT,
    "time3"    TEXT,
    "time4"    TEXT,
    "lane1"    TEXT,
    "lane2"    TEXT,
    "lane3"    TEXT,
    "lane4"    TEXT,
    "total"    TEXT,

    "racer_id" INTEGER PRIMARY KEY,

    FOREIGN KEY(den_id) REFERENCES dens(den_id)
    );

--
-- Friendly names for managing multiple accounts
--
CREATE TABLE times (
    "event_id" INTEGER NOT NULL,
    "racer_id" INTEGER NOT NULL,
    "lane"     TEXT,
    "time"     TEXT,
    "time_id"  INTEGER PRIMARY KEY,

    FOREIGN KEY(event_id) REFERENCES events(event_id),
    FOREIGN KEY(racer_id) REFERENCES racers(racer_id)
    );
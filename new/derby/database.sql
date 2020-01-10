
--
-- Server settings
--
CREATE TABLE settings (
    "name"     TEXT NOT NULL UNIQUE,
    "value"    TEXT
    );

--
-- Events
--
CREATE TABLE events (
    "event"     TEXT NOT NULL UNIQUE,
    "date"     TEXT NOT NULL,
    "event_id" INTEGER PRIMARY KEY
    );

--
-- Groups
--
CREATE TABLE groups (
    "group"    TEXT    NOT NULL,
    "event_id" INTEGER NOT NULL,
    "group_id" INTEGER PRIMARY KEY,

    UNIQUE("group", "event_id"),
    FOREIGN KEY(event_id) REFERENCES events(event_id)
    );

--
-- Contestants
--
CREATE TABLE racers (
    "racer"    TEXT    NOT NULL UNIQUE,
    "group_id" INTEGER NOT NULL,
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

    FOREIGN KEY(group_id) REFERENCES groups(group_id)
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

-- =============================================
-- MUSIC PLAYER SCHEMA (SQLite)
-- =============================================

PRAGMA foreign_keys = ON;

-- Base tables

CREATE TABLE "user"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL
);

CREATE TABLE "album_art"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "s3_key" TEXT NOT NULL,
    "image_url" TEXT NOT NULL
);

CREATE TABLE "artist"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL
);

CREATE TABLE "genre"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL
);

-- Tables with foreign key dependencies

CREATE TABLE "album"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "album_name" TEXT NOT NULL,
    "album_art_id" INTEGER,
    "release_date" TEXT NOT NULL,
    FOREIGN KEY("album_art_id") REFERENCES "album_art"("id")
);

CREATE TABLE "playlist"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "playlist_name" TEXT NOT NULL,
    "user_id" INTEGER NOT NULL,
    FOREIGN KEY("user_id") REFERENCES "user"("id")
);

CREATE TABLE "song"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "song_name" TEXT NOT NULL,
    "album_id" INTEGER NOT NULL,
    "genre_id" INTEGER,
    "s3_key" TEXT NOT NULL,
    "duration_seconds" INTEGER NOT NULL,
    "track_number" INTEGER NOT NULL,
    FOREIGN KEY("album_id") REFERENCES "album"("id"),
    FOREIGN KEY("genre_id") REFERENCES "genre"("id")
);

-- Junction tables

CREATE TABLE "song_artist"(
    "song_id" INTEGER NOT NULL,
    "artist_id" INTEGER NOT NULL,
    "role" TEXT DEFAULT 'primary',
    PRIMARY KEY("song_id", "artist_id"),
    FOREIGN KEY("song_id") REFERENCES "song"("id"),
    FOREIGN KEY("artist_id") REFERENCES "artist"("id")
);

CREATE TABLE "playlist_song"(
    "playlist_id" INTEGER NOT NULL,
    "song_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    PRIMARY KEY("playlist_id", "song_id"),
    FOREIGN KEY("playlist_id") REFERENCES "playlist"("id"),
    FOREIGN KEY("song_id") REFERENCES "song"("id")
);

CREATE TABLE "play_event"(
    "id" INTEGER NOT NULL PRIMARY KEY,
    "user_id" INTEGER NOT NULL,
    "song_id" INTEGER NOT NULL,
    "played_at" TEXT NOT NULL,
    FOREIGN KEY("user_id") REFERENCES "user"("id"),
    FOREIGN KEY("song_id") REFERENCES "song"("id")
);

-- Indexes

CREATE INDEX idx_play_event_user_time ON "play_event"("user_id", "played_at");
CREATE INDEX idx_play_event_song ON "play_event"("song_id");
CREATE INDEX idx_song_album ON "song"("album_id");
CREATE INDEX idx_playlist_user ON "playlist"("user_id");

-- =============================================
-- SEED DATA
-- =============================================

-- Users
INSERT INTO "user" VALUES (1, 'Alice Johnson');
INSERT INTO "user" VALUES (2, 'Bob Martinez');
INSERT INTO "user" VALUES (3, 'Charlie Kim');
INSERT INTO "user" VALUES (4, 'Dana Okafor');
INSERT INTO "user" VALUES (5, 'Eli Rosenberg');

-- Genres
INSERT INTO "genre" VALUES (1, 'Rock');
INSERT INTO "genre" VALUES (2, 'Pop');
INSERT INTO "genre" VALUES (3, 'Hip Hop');
INSERT INTO "genre" VALUES (4, 'Jazz');
INSERT INTO "genre" VALUES (5, 'Electronic');
INSERT INTO "genre" VALUES (6, 'R&B');
INSERT INTO "genre" VALUES (7, 'Classical');
INSERT INTO "genre" VALUES (8, 'Indie');

-- Artists
INSERT INTO "artist" VALUES (1, 'The Velvet Echoes');
INSERT INTO "artist" VALUES (2, 'Luna Park');
INSERT INTO "artist" VALUES (3, 'MC Voltage');
INSERT INTO "artist" VALUES (4, 'Sarah Blue');
INSERT INTO "artist" VALUES (5, 'Neon District');
INSERT INTO "artist" VALUES (6, 'The Quiet Hours');
INSERT INTO "artist" VALUES (7, 'DJ Phantom');
INSERT INTO "artist" VALUES (8, 'Ava Chen');
INSERT INTO "artist" VALUES (9, 'Glass Cathedral');
INSERT INTO "artist" VALUES (10, 'Marcus Cole');

-- Album art
INSERT INTO "album_art" VALUES (1, 'art/midnight-drive.jpg', 'https://cdn.example.com/art/midnight-drive.jpg');
INSERT INTO "album_art" VALUES (2, 'art/starlight.jpg', 'https://cdn.example.com/art/starlight.jpg');
INSERT INTO "album_art" VALUES (3, 'art/voltage-ep.jpg', 'https://cdn.example.com/art/voltage-ep.jpg');
INSERT INTO "album_art" VALUES (4, 'art/ocean-floor.jpg', 'https://cdn.example.com/art/ocean-floor.jpg');
INSERT INTO "album_art" VALUES (5, 'art/city-glow.jpg', 'https://cdn.example.com/art/city-glow.jpg');
INSERT INTO "album_art" VALUES (6, 'art/whispers.jpg', 'https://cdn.example.com/art/whispers.jpg');
INSERT INTO "album_art" VALUES (7, 'art/glass-ep.jpg', 'https://cdn.example.com/art/glass-ep.jpg');
INSERT INTO "album_art" VALUES (8, 'art/frequencies.jpg', 'https://cdn.example.com/art/frequencies.jpg');

-- Albums
INSERT INTO "album" VALUES (1, 'Midnight Drive',      1, '2023-03-15');
INSERT INTO "album" VALUES (2, 'Starlight Sessions',   2, '2023-07-22');
INSERT INTO "album" VALUES (3, 'Voltage EP',           3, '2024-01-10');
INSERT INTO "album" VALUES (4, 'Ocean Floor',          4, '2022-11-05');
INSERT INTO "album" VALUES (5, 'City Glow',            5, '2024-06-01');
INSERT INTO "album" VALUES (6, 'Whispers in the Dark', 6, '2023-09-18');
INSERT INTO "album" VALUES (7, 'Glass EP',             7, '2024-04-12');
INSERT INTO "album" VALUES (8, 'Frequencies',          8, '2024-08-30');

-- Songs (8 albums × ~4 songs each = 30 songs)
INSERT INTO "song" VALUES (1,  'Night Highway',        1, 1, 'songs/night-highway.mp3',        237, 1);
INSERT INTO "song" VALUES (2,  'Dashboard Lights',     1, 1, 'songs/dashboard-lights.mp3',     198, 2);
INSERT INTO "song" VALUES (3,  'Rearview',             1, 8, 'songs/rearview.mp3',              264, 3);
INSERT INTO "song" VALUES (4,  'Last Exit',            1, 1, 'songs/last-exit.mp3',             312, 4);

INSERT INTO "song" VALUES (5,  'Constellations',       2, 2, 'songs/constellations.mp3',        202, 1);
INSERT INTO "song" VALUES (6,  'Moonwalk',             2, 2, 'songs/moonwalk.mp3',              185, 2);
INSERT INTO "song" VALUES (7,  'Satellite Love',       2, 2, 'songs/satellite-love.mp3',        221, 3);
INSERT INTO "song" VALUES (8,  'Eclipse',              2, 5, 'songs/eclipse.mp3',               243, 4);

INSERT INTO "song" VALUES (9,  'Wire',                 3, 3, 'songs/wire.mp3',                  178, 1);
INSERT INTO "song" VALUES (10, 'Overload',             3, 3, 'songs/overload.mp3',              205, 2);
INSERT INTO "song" VALUES (11, 'Circuit Break',        3, 3, 'songs/circuit-break.mp3',         192, 3);

INSERT INTO "song" VALUES (12, 'Deep Blue',            4, 4, 'songs/deep-blue.mp3',             285, 1);
INSERT INTO "song" VALUES (13, 'Coral Dreams',         4, 6, 'songs/coral-dreams.mp3',          248, 2);
INSERT INTO "song" VALUES (14, 'Undertow',             4, 4, 'songs/undertow.mp3',              310, 3);
INSERT INTO "song" VALUES (15, 'Abyssal Plain',        4, 4, 'songs/abyssal-plain.mp3',         273, 4);

INSERT INTO "song" VALUES (16, 'Neon Rain',            5, 5, 'songs/neon-rain.mp3',             215, 1);
INSERT INTO "song" VALUES (17, 'Skyline',              5, 5, 'songs/skyline.mp3',               198, 2);
INSERT INTO "song" VALUES (18, 'After Dark',           5, 5, 'songs/after-dark.mp3',            242, 3);
INSERT INTO "song" VALUES (19, 'Pulse',                5, 5, 'songs/pulse.mp3',                 188, 4);

INSERT INTO "song" VALUES (20, 'Hush',                 6, 8, 'songs/hush.mp3',                  195, 1);
INSERT INTO "song" VALUES (21, 'Fog',                  6, 8, 'songs/fog.mp3',                   224, 2);
INSERT INTO "song" VALUES (22, 'Paper Walls',          6, 8, 'songs/paper-walls.mp3',           267, 3);
INSERT INTO "song" VALUES (23, 'Ghost Light',          6, 1, 'songs/ghost-light.mp3',           208, 4);

INSERT INTO "song" VALUES (24, 'Fracture',             7, 8, 'songs/fracture.mp3',              182, 1);
INSERT INTO "song" VALUES (25, 'Prism',                7, 2, 'songs/prism.mp3',                 213, 2);
INSERT INTO "song" VALUES (26, 'Hollow',               7, 8, 'songs/hollow.mp3',                199, 3);

INSERT INTO "song" VALUES (27, 'Hertz',                8, 5, 'songs/hertz.mp3',                 176, 1);
INSERT INTO "song" VALUES (28, 'Waveform',             8, 5, 'songs/waveform.mp3',              231, 2);
INSERT INTO "song" VALUES (29, 'Resonance',            8, 4, 'songs/resonance.mp3',             258, 3);
INSERT INTO "song" VALUES (30, 'Decay',                8, 5, 'songs/decay.mp3',                 204, 4);

-- Song-Artist relationships
INSERT INTO "song_artist" VALUES (1,  1, 'primary');
INSERT INTO "song_artist" VALUES (2,  1, 'primary');
INSERT INTO "song_artist" VALUES (3,  1, 'primary');
INSERT INTO "song_artist" VALUES (3,  8, 'featured');
INSERT INTO "song_artist" VALUES (4,  1, 'primary');

INSERT INTO "song_artist" VALUES (5,  2, 'primary');
INSERT INTO "song_artist" VALUES (6,  2, 'primary');
INSERT INTO "song_artist" VALUES (7,  2, 'primary');
INSERT INTO "song_artist" VALUES (7,  4, 'featured');
INSERT INTO "song_artist" VALUES (8,  2, 'primary');

INSERT INTO "song_artist" VALUES (9,  3, 'primary');
INSERT INTO "song_artist" VALUES (10, 3, 'primary');
INSERT INTO "song_artist" VALUES (10, 7, 'featured');
INSERT INTO "song_artist" VALUES (11, 3, 'primary');

INSERT INTO "song_artist" VALUES (12, 4, 'primary');
INSERT INTO "song_artist" VALUES (13, 4, 'primary');
INSERT INTO "song_artist" VALUES (14, 4, 'primary');
INSERT INTO "song_artist" VALUES (15, 4, 'primary');

INSERT INTO "song_artist" VALUES (16, 5, 'primary');
INSERT INTO "song_artist" VALUES (17, 5, 'primary');
INSERT INTO "song_artist" VALUES (18, 5, 'primary');
INSERT INTO "song_artist" VALUES (18, 10, 'featured');
INSERT INTO "song_artist" VALUES (19, 5, 'primary');

INSERT INTO "song_artist" VALUES (20, 6, 'primary');
INSERT INTO "song_artist" VALUES (21, 6, 'primary');
INSERT INTO "song_artist" VALUES (22, 6, 'primary');
INSERT INTO "song_artist" VALUES (23, 6, 'primary');

INSERT INTO "song_artist" VALUES (24, 9, 'primary');
INSERT INTO "song_artist" VALUES (25, 9, 'primary');
INSERT INTO "song_artist" VALUES (26, 9, 'primary');

INSERT INTO "song_artist" VALUES (27, 8, 'primary');
INSERT INTO "song_artist" VALUES (28, 8, 'primary');
INSERT INTO "song_artist" VALUES (29, 8, 'primary');
INSERT INTO "song_artist" VALUES (29, 10, 'featured');
INSERT INTO "song_artist" VALUES (30, 8, 'primary');

-- Playlists
INSERT INTO "playlist" VALUES (1, 'Late Night Vibes',   1);
INSERT INTO "playlist" VALUES (2, 'Workout Mix',        2);
INSERT INTO "playlist" VALUES (3, 'Chill',              1);
INSERT INTO "playlist" VALUES (4, 'Road Trip',          3);
INSERT INTO "playlist" VALUES (5, 'Focus Mode',         4);
INSERT INTO "playlist" VALUES (6, 'Party Starters',     5);
INSERT INTO "playlist" VALUES (7, 'Jazz & Soul',        2);

-- Playlist songs
INSERT INTO "playlist_song" VALUES (1, 1,  1);
INSERT INTO "playlist_song" VALUES (1, 16, 2);
INSERT INTO "playlist_song" VALUES (1, 20, 3);
INSERT INTO "playlist_song" VALUES (1, 21, 4);
INSERT INTO "playlist_song" VALUES (1, 18, 5);

INSERT INTO "playlist_song" VALUES (2, 9,  1);
INSERT INTO "playlist_song" VALUES (2, 10, 2);
INSERT INTO "playlist_song" VALUES (2, 19, 3);
INSERT INTO "playlist_song" VALUES (2, 11, 4);
INSERT INTO "playlist_song" VALUES (2, 27, 5);

INSERT INTO "playlist_song" VALUES (3, 12, 1);
INSERT INTO "playlist_song" VALUES (3, 13, 2);
INSERT INTO "playlist_song" VALUES (3, 22, 3);
INSERT INTO "playlist_song" VALUES (3, 25, 4);

INSERT INTO "playlist_song" VALUES (4, 1,  1);
INSERT INTO "playlist_song" VALUES (4, 2,  2);
INSERT INTO "playlist_song" VALUES (4, 5,  3);
INSERT INTO "playlist_song" VALUES (4, 17, 4);
INSERT INTO "playlist_song" VALUES (4, 4,  5);
INSERT INTO "playlist_song" VALUES (4, 7,  6);

INSERT INTO "playlist_song" VALUES (5, 24, 1);
INSERT INTO "playlist_song" VALUES (5, 26, 2);
INSERT INTO "playlist_song" VALUES (5, 28, 3);
INSERT INTO "playlist_song" VALUES (5, 29, 4);

INSERT INTO "playlist_song" VALUES (6, 10, 1);
INSERT INTO "playlist_song" VALUES (6, 16, 2);
INSERT INTO "playlist_song" VALUES (6, 6,  3);
INSERT INTO "playlist_song" VALUES (6, 9,  4);
INSERT INTO "playlist_song" VALUES (6, 19, 5);

INSERT INTO "playlist_song" VALUES (7, 12, 1);
INSERT INTO "playlist_song" VALUES (7, 29, 2);
INSERT INTO "playlist_song" VALUES (7, 15, 3);

-- Play events (listening history spread across recent months)
INSERT INTO "play_event" VALUES (1,  1, 1,  '2025-01-15 22:30:00');
INSERT INTO "play_event" VALUES (2,  1, 16, '2025-01-15 22:34:00');
INSERT INTO "play_event" VALUES (3,  1, 20, '2025-01-15 22:38:00');
INSERT INTO "play_event" VALUES (4,  2, 9,  '2025-01-16 07:00:00');
INSERT INTO "play_event" VALUES (5,  2, 10, '2025-01-16 07:03:00');
INSERT INTO "play_event" VALUES (6,  2, 11, '2025-01-16 07:07:00');
INSERT INTO "play_event" VALUES (7,  3, 1,  '2025-01-17 14:00:00');
INSERT INTO "play_event" VALUES (8,  3, 2,  '2025-01-17 14:04:00');
INSERT INTO "play_event" VALUES (9,  3, 5,  '2025-01-17 14:08:00');
INSERT INTO "play_event" VALUES (10, 4, 24, '2025-01-18 09:15:00');
INSERT INTO "play_event" VALUES (11, 4, 26, '2025-01-18 09:18:00');
INSERT INTO "play_event" VALUES (12, 4, 28, '2025-01-18 09:22:00');
INSERT INTO "play_event" VALUES (13, 5, 10, '2025-01-19 20:00:00');
INSERT INTO "play_event" VALUES (14, 5, 16, '2025-01-19 20:04:00');
INSERT INTO "play_event" VALUES (15, 5, 6,  '2025-01-19 20:07:00');
INSERT INTO "play_event" VALUES (16, 1, 12, '2025-01-20 23:00:00');
INSERT INTO "play_event" VALUES (17, 1, 13, '2025-01-20 23:05:00');
INSERT INTO "play_event" VALUES (18, 1, 1,  '2025-01-21 22:15:00');
INSERT INTO "play_event" VALUES (19, 2, 9,  '2025-01-22 06:45:00');
INSERT INTO "play_event" VALUES (20, 2, 19, '2025-01-22 06:48:00');
INSERT INTO "play_event" VALUES (21, 3, 17, '2025-01-23 15:30:00');
INSERT INTO "play_event" VALUES (22, 3, 7,  '2025-01-23 15:34:00');
INSERT INTO "play_event" VALUES (23, 1, 18, '2025-01-24 21:00:00');
INSERT INTO "play_event" VALUES (24, 1, 16, '2025-01-24 21:04:00');
INSERT INTO "play_event" VALUES (25, 4, 29, '2025-01-25 10:00:00');
INSERT INTO "play_event" VALUES (26, 4, 12, '2025-01-25 10:05:00');
INSERT INTO "play_event" VALUES (27, 5, 9,  '2025-01-26 19:30:00');
INSERT INTO "play_event" VALUES (28, 5, 11, '2025-01-26 19:33:00');
INSERT INTO "play_event" VALUES (29, 2, 27, '2025-01-27 07:15:00');
INSERT INTO "play_event" VALUES (30, 2, 28, '2025-01-27 07:18:00');
INSERT INTO "play_event" VALUES (31, 1, 1,  '2025-02-01 22:00:00');
INSERT INTO "play_event" VALUES (32, 1, 20, '2025-02-01 22:04:00');
INSERT INTO "play_event" VALUES (33, 1, 21, '2025-02-01 22:08:00');
INSERT INTO "play_event" VALUES (34, 3, 4,  '2025-02-02 16:00:00');
INSERT INTO "play_event" VALUES (35, 3, 5,  '2025-02-02 16:05:00');
INSERT INTO "play_event" VALUES (36, 2, 10, '2025-02-03 06:50:00');
INSERT INTO "play_event" VALUES (37, 2, 9,  '2025-02-03 06:54:00');
INSERT INTO "play_event" VALUES (38, 4, 25, '2025-02-04 11:00:00');
INSERT INTO "play_event" VALUES (39, 5, 16, '2025-02-05 20:30:00');
INSERT INTO "play_event" VALUES (40, 5, 18, '2025-02-05 20:34:00');
INSERT INTO "play_event" VALUES (41, 1, 1,  '2025-02-06 23:10:00');
INSERT INTO "play_event" VALUES (42, 1, 22, '2025-02-06 23:14:00');
INSERT INTO "play_event" VALUES (43, 3, 7,  '2025-02-07 14:20:00');
INSERT INTO "play_event" VALUES (44, 3, 8,  '2025-02-07 14:24:00');
INSERT INTO "play_event" VALUES (45, 2, 19, '2025-02-08 07:00:00');
INSERT INTO "play_event" VALUES (46, 4, 30, '2025-02-09 09:45:00');
INSERT INTO "play_event" VALUES (47, 5, 6,  '2025-02-10 21:00:00');
INSERT INTO "play_event" VALUES (48, 5, 10, '2025-02-10 21:03:00');
INSERT INTO "play_event" VALUES (49, 1, 16, '2025-02-11 22:30:00');
INSERT INTO "play_event" VALUES (50, 1, 18, '2025-02-11 22:34:00');

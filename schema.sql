-- ============================================================
--  NFL ROSTER TRACKER — schema.sql
--  MySQL 8.0+
--  Run this file first to create all tables.
-- ============================================================

CREATE DATABASE IF NOT EXISTS nfl_roster
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE nfl_roster;

-- ============================================================
-- 1. TEAMS
--    One team → many players  (1:M)
--    Many teams → many super bowls via junction  (M:N)
-- ============================================================
CREATE TABLE IF NOT EXISTS teams (
    team_id       INT UNSIGNED      AUTO_INCREMENT PRIMARY KEY,
    city          VARCHAR(50)       NOT NULL,
    name          VARCHAR(50)       NOT NULL,
    abbreviation  CHAR(3)           NOT NULL,
    conference    ENUM('AFC','NFC') NOT NULL,
    division      ENUM('North','South','East','West') NOT NULL,
    head_coach    VARCHAR(100)      NOT NULL DEFAULT 'TBD',
    stadium       VARCHAR(100),
    founded_year  YEAR,
    created_at    TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_abbrev (abbreviation),
    UNIQUE KEY uq_team   (city, name)
);

-- ============================================================
-- 2. POSITIONS
--    Stores two ranking-stat labels per position code.
--    One position → many players  (1:M)
-- ============================================================
CREATE TABLE IF NOT EXISTS positions (
    position_id   TINYINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    code          CHAR(3)           NOT NULL,
    name          VARCHAR(30)       NOT NULL,
    unit          ENUM('Offense','Defense','Special') NOT NULL,
    rank_stat_1   VARCHAR(50)       NOT NULL,
    rank_stat_2   VARCHAR(50)       NOT NULL,
    UNIQUE KEY uq_pos_code (code)
);

-- ============================================================
-- 3. PLAYERS
--    M:1  → teams      (many players belong to one team)
--    1:1  → positions  (each player has one position)
--    depth_rank enforced to 1 or 2 only (top-2 depth chart)
-- ============================================================
CREATE TABLE IF NOT EXISTS players (
    player_id          INT UNSIGNED       AUTO_INCREMENT PRIMARY KEY,
    first_name         VARCHAR(50)        NOT NULL,
    last_name          VARCHAR(50)        NOT NULL,
    jersey_number      TINYINT UNSIGNED,
    position_id        TINYINT UNSIGNED   NOT NULL,
    team_id            INT UNSIGNED       NOT NULL,
    depth_rank         TINYINT UNSIGNED   NOT NULL DEFAULT 1,
    rank_stat_1_value  DECIMAL(8,2)       NOT NULL DEFAULT 0.00,
    rank_stat_2_value  DECIMAL(8,2)       NOT NULL DEFAULT 0.00,
    date_of_birth      DATE,
    college            VARCHAR(100),
    years_exp          TINYINT UNSIGNED   NOT NULL DEFAULT 0,
    status             ENUM('Active','Injured','IR','Practice Squad','Suspended')
                           NOT NULL DEFAULT 'Active',
    created_at         TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
    -- only 1 or 2 allowed for depth_rank
    CONSTRAINT chk_depth_rank  CHECK (depth_rank IN (1, 2)),
    -- no two players share the same depth slot on the same team at the same position
    UNIQUE KEY uq_depth_slot (team_id, position_id, depth_rank),
    CONSTRAINT fk_player_team     FOREIGN KEY (team_id)
        REFERENCES teams     (team_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_player_position FOREIGN KEY (position_id)
        REFERENCES positions (position_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- 4. PRO BOWL
--    One pro_bowl row = one selection (season + conf + position)
--    M:N with players resolved via player_pro_bowl junction
-- ============================================================
CREATE TABLE IF NOT EXISTS pro_bowl (
    pro_bowl_id   INT UNSIGNED       AUTO_INCREMENT PRIMARY KEY,
    season_year   YEAR               NOT NULL,
    conference    ENUM('AFC','NFC')  NOT NULL,
    position_id   TINYINT UNSIGNED   NOT NULL,
    UNIQUE KEY uq_pb_slot (season_year, conference, position_id),
    CONSTRAINT fk_pb_position FOREIGN KEY (position_id)
        REFERENCES positions (position_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- 5. PLAYER_PRO_BOWL  — junction table (M:N)
--    A player can earn multiple Pro Bowl selections over career;
--    a Pro Bowl slot can have one player per season.
-- ============================================================
CREATE TABLE IF NOT EXISTS player_pro_bowl (
    player_id    INT UNSIGNED  NOT NULL,
    pro_bowl_id  INT UNSIGNED  NOT NULL,
    PRIMARY KEY (player_id, pro_bowl_id),
    CONSTRAINT fk_ppb_player   FOREIGN KEY (player_id)
        REFERENCES players  (player_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ppb_probowl  FOREIGN KEY (pro_bowl_id)
        REFERENCES pro_bowl (pro_bowl_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 6. SUPER BOWL
--    M:N with teams (winner + loser each season)
--    Resolved via super_bowl_teams junction
-- ============================================================
CREATE TABLE IF NOT EXISTS super_bowl (
    super_bowl_id  INT UNSIGNED      AUTO_INCREMENT PRIMARY KEY,
    season_year    YEAR              NOT NULL UNIQUE,
    sb_number      TINYINT UNSIGNED  NOT NULL UNIQUE,
    mvp_name       VARCHAR(100),
    location       VARCHAR(100),
    attendance     INT UNSIGNED,
    CONSTRAINT chk_sb_number CHECK (sb_number > 0)
);

-- ============================================================
-- 7. SUPER_BOWL_TEAMS  — junction table (M:N)
--    Tracks which teams played in each Super Bowl and the score.
-- ============================================================
CREATE TABLE IF NOT EXISTS super_bowl_teams (
    super_bowl_id  INT UNSIGNED      NOT NULL,
    team_id        INT UNSIGNED      NOT NULL,
    result         ENUM('Winner','Loser') NOT NULL,
    score          TINYINT UNSIGNED  NOT NULL DEFAULT 0,
    PRIMARY KEY (super_bowl_id, team_id),
    CONSTRAINT fk_sbt_sb   FOREIGN KEY (super_bowl_id)
        REFERENCES super_bowl (super_bowl_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sbt_team FOREIGN KEY (team_id)
        REFERENCES teams      (team_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

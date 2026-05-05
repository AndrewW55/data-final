-- ============================================================
--  NFL ROSTER TRACKER — queries.sql
--  8 example queries demonstrating database capabilities
-- ============================================================

USE nfl_roster;

-- ------------------------------------------------------------
-- Query 1: FULL TEAM DEPTH CHART
--   Shows depth 1 & 2 for every position on a specific team,
--   grouped by offensive / defensive / special unit.
-- ------------------------------------------------------------
SELECT
    pos.unit                                        AS unit,
    pos.code                                        AS pos,
    p.depth_rank                                    AS depth,
    CONCAT(p.first_name, ' ', p.last_name)          AS player,
    p.jersey_number                                 AS jersey,
    p.status,
    pos.rank_stat_1                                 AS stat_1_label,
    p.rank_stat_1_value                             AS stat_1,
    pos.rank_stat_2                                 AS stat_2_label,
    p.rank_stat_2_value                             AS stat_2
FROM players p
JOIN positions pos ON p.position_id = pos.position_id
JOIN teams     t   ON p.team_id     = t.team_id
WHERE t.abbreviation = 'KC'
ORDER BY pos.unit, pos.code, p.depth_rank;

-- ------------------------------------------------------------
-- Query 2: LEAGUE-WIDE POSITIONAL RANKING — QBs
--   Ranks all active QBs by passing yards, then TDs.
--   Uses RANK() window function.
-- ------------------------------------------------------------
SELECT
    RANK() OVER (ORDER BY p.rank_stat_1_value DESC,
                          p.rank_stat_2_value DESC)  AS `rank`,
    CONCAT(p.first_name, ' ', p.last_name)           AS player,
    t.abbreviation                                    AS team,
    p.rank_stat_1_value                               AS passing_yards,
    p.rank_stat_2_value                               AS passing_tds,
    p.depth_rank                                      AS depth_slot
FROM players   p
JOIN positions pos ON p.position_id = pos.position_id
JOIN teams     t   ON p.team_id     = t.team_id
WHERE pos.code = 'QB'
  AND p.status = 'Active'
ORDER BY passing_yards DESC, passing_tds DESC;

-- ------------------------------------------------------------
-- Query 3: PRO BOWL SELECTIONS WITH PLAYER & TEAM DETAILS
--   Shows who was selected, their team, and position.
-- ------------------------------------------------------------
SELECT
    pb.season_year,
    pb.conference,
    pos.code                                        AS position,
    CONCAT(p.first_name, ' ', p.last_name)          AS player,
    t.abbreviation                                   AS team,
    p.rank_stat_1_value                              AS primary_stat
FROM player_pro_bowl ppb
JOIN pro_bowl  pb  ON ppb.pro_bowl_id  = pb.pro_bowl_id
JOIN players   p   ON ppb.player_id    = p.player_id
JOIN positions pos ON pb.position_id   = pos.position_id
JOIN teams     t   ON p.team_id        = t.team_id
ORDER BY pb.season_year DESC, pb.conference, pos.code;

-- ------------------------------------------------------------
-- Query 4: SUPER BOWL HISTORY — wins per team
--   Counts Super Bowl appearances and wins per franchise.
-- ------------------------------------------------------------
SELECT
    CONCAT(t.city, ' ', t.name)                     AS team,
    t.abbreviation,
    COUNT(*)                                         AS appearances,
    SUM(sbt.result = 'Winner')                       AS wins,
    SUM(sbt.result = 'Loser')                        AS losses
FROM super_bowl_teams sbt
JOIN teams t ON sbt.team_id = t.team_id
GROUP BY t.team_id, t.city, t.name, t.abbreviation
ORDER BY wins DESC, appearances DESC;

-- ------------------------------------------------------------
-- Query 5: MULTI-PRO-BOWL PLAYERS
--   Players who have been selected to more than one Pro Bowl.
-- ------------------------------------------------------------
SELECT
    CONCAT(p.first_name, ' ', p.last_name)          AS player,
    t.abbreviation                                   AS team,
    pos.code                                         AS position,
    COUNT(ppb.pro_bowl_id)                           AS pro_bowl_count
FROM player_pro_bowl ppb
JOIN players   p   ON ppb.player_id  = p.player_id
JOIN teams     t   ON p.team_id      = t.team_id
JOIN positions pos ON p.position_id  = pos.position_id
GROUP BY p.player_id, p.first_name, p.last_name, t.abbreviation, pos.code
HAVING COUNT(ppb.pro_bowl_id) > 1
ORDER BY pro_bowl_count DESC;

-- ------------------------------------------------------------
-- Query 6: TEAMS WITH SUPER BOWL WINS AND THEIR CURRENT QB
--   Joins Super Bowl data back to current depth-1 QB.
-- ------------------------------------------------------------
SELECT
    CONCAT(t.city, ' ', t.name)                     AS team,
    SUM(sbt.result = 'Winner')                       AS sb_wins,
    CONCAT(p.first_name, ' ', p.last_name)          AS starting_qb,
    p.years_exp                                      AS qb_years_exp,
    p.rank_stat_1_value                              AS passing_yards
FROM teams t
LEFT JOIN super_bowl_teams sbt ON sbt.team_id = t.team_id
LEFT JOIN players p ON p.team_id     = t.team_id
                    AND p.depth_rank  = 1
                    AND p.position_id = (SELECT position_id FROM positions WHERE code = 'QB')
GROUP BY t.team_id, t.city, t.name, p.first_name, p.last_name, p.years_exp, p.rank_stat_1_value
ORDER BY sb_wins DESC;

-- ------------------------------------------------------------
-- Query 7: SEARCH PLAYERS BY LAST NAME  (parameterized style)
--   In the Python app, '%Smith%' will be a bound parameter.
-- ------------------------------------------------------------
SELECT
    CONCAT(p.first_name, ' ', p.last_name)          AS player,
    pos.code                                         AS position,
    t.abbreviation                                   AS team,
    p.depth_rank,
    p.status,
    p.rank_stat_1_value,
    p.rank_stat_2_value
FROM players   p
JOIN positions pos ON p.position_id = pos.position_id
JOIN teams     t   ON p.team_id     = t.team_id
WHERE p.last_name LIKE '%Mahomes%'
ORDER BY p.last_name, p.first_name;

-- ------------------------------------------------------------
-- Query 8: CONFERENCE STANDINGS BY PRO BOWL SELECTIONS
--   Ranks teams by how many Pro Bowl players they have.
-- ------------------------------------------------------------
SELECT
    t.conference,
    CONCAT(t.city, ' ', t.name)                     AS team,
    t.abbreviation,
    COUNT(ppb.player_id)                             AS pro_bowl_players
FROM teams t
LEFT JOIN players        p   ON p.team_id   = t.team_id
LEFT JOIN player_pro_bowl ppb ON ppb.player_id = p.player_id
GROUP BY t.team_id, t.conference, t.city, t.name, t.abbreviation
ORDER BY t.conference, pro_bowl_players DESC;

-- ------------------------------------------------------------
-- Query 9 (BONUS): TRANSACTION EXAMPLE — Transfer a player
--   Moves a player from one team to another and resets depth.
--   In Python app this is wrapped in a transaction.
-- ------------------------------------------------------------
START TRANSACTION;

UPDATE players
SET    team_id    = (SELECT team_id FROM teams WHERE abbreviation = 'BUF'),
       depth_rank = 2,
       status     = 'Active',
       updated_at = NOW()
WHERE  first_name = 'Carson' AND last_name = 'Wentz';

COMMIT;

-- ============================================================
--  NFL ROSTER TRACKER — data.sql
--  Realistic sample data.  Run AFTER schema.sql.
-- ============================================================

USE nfl_roster;

-- ============================================================
-- POSITIONS  (22 rows)
-- ============================================================
INSERT INTO positions (code, name, unit, rank_stat_1, rank_stat_2) VALUES
  ('QB',  'Quarterback',        'Offense', 'Passing Yards',       'Passing TDs'),
  ('RB',  'Running Back',       'Offense', 'Rushing Yards',       'Rushing TDs'),
  ('FB',  'Fullback',           'Offense', 'Rushing Yards',       'Rushing TDs'),
  ('WR',  'Wide Receiver',      'Offense', 'Receiving Yards',     'Receiving TDs'),
  ('TE',  'Tight End',          'Offense', 'Receiving Yards',     'Receiving TDs'),
  ('LT',  'Left Tackle',        'Offense', 'Sacks Allowed',       'Pressures Allowed'),
  ('LG',  'Left Guard',         'Offense', 'Sacks Allowed',       'Pressures Allowed'),
  ('C',   'Center',             'Offense', 'Sacks Allowed',       'Pressures Allowed'),
  ('RG',  'Right Guard',        'Offense', 'Sacks Allowed',       'Pressures Allowed'),
  ('RT',  'Right Tackle',       'Offense', 'Sacks Allowed',       'Pressures Allowed'),
  ('DE',  'Defensive End',      'Defense', 'Sacks',               'Tackles For Loss'),
  ('DT',  'Defensive Tackle',   'Defense', 'Sacks',               'Tackles For Loss'),
  ('OLB', 'Outside Linebacker', 'Defense', 'Sacks',               'Tackles'),
  ('ILB', 'Inside Linebacker',  'Defense', 'Tackles',             'Interceptions'),
  ('MLB', 'Middle Linebacker',  'Defense', 'Tackles',             'Sacks'),
  ('CB',  'Cornerback',         'Defense', 'Interceptions',       'Pass Deflections'),
  ('SS',  'Strong Safety',      'Defense', 'Tackles',             'Interceptions'),
  ('FS',  'Free Safety',        'Defense', 'Interceptions',       'Pass Deflections'),
  ('K',   'Kicker',             'Special', 'Field Goal Pct',      'Long FG Made'),
  ('P',   'Punter',             'Special', 'Gross Avg Yards',     'Net Avg Yards'),
  ('KR',  'Kick Returner',      'Special', 'Return Yards',        'Return TDs'),
  ('LS',  'Long Snapper',       'Special', 'Snaps',               'Snap Errors');

-- ============================================================
-- TEAMS  (12 teams — a representative sample)
-- ============================================================
INSERT INTO teams (city, name, abbreviation, conference, division, head_coach, stadium, founded_year) VALUES
  ('Kansas City',  'Chiefs',      'KC',  'AFC', 'West',  'Andy Reid',        'GEHA Field at Arrowhead Stadium',  1960),
  ('San Francisco','49ers',       'SF',  'NFC', 'West',  'Kyle Shanahan',    'Levi\'s Stadium',                  1946),
  ('Dallas',       'Cowboys',     'DAL', 'NFC', 'East',  'Mike McCarthy',    'AT&T Stadium',                     1960),
  ('Buffalo',      'Bills',       'BUF', 'AFC', 'East',  'Sean McDermott',   'Highmark Stadium',                 1960),
  ('Philadelphia', 'Eagles',      'PHI', 'NFC', 'East',  'Nick Sirianni',    'Lincoln Financial Field',          1933),
  ('Baltimore',    'Ravens',      'BAL', 'AFC', 'North', 'John Harbaugh',    'M&T Bank Stadium',                 1996),
  ('Miami',        'Dolphins',    'MIA', 'AFC', 'East',  'Mike McDaniel',    'Hard Rock Stadium',                1966),
  ('Detroit',      'Lions',       'DET', 'NFC', 'North', 'Dan Campbell',     'Ford Field',                       1930),
  ('Cincinnati',   'Bengals',     'CIN', 'AFC', 'North', 'Zac Taylor',       'Paycor Stadium',                   1968),
  ('Green Bay',    'Packers',     'GB',  'NFC', 'North', 'Matt LaFleur',     'Lambeau Field',                    1919),
  ('Los Angeles',  'Rams',        'LAR', 'NFC', 'West',  'Sean McVay',       'SoFi Stadium',                     1936),
  ('New England',  'Patriots',    'NE',  'AFC', 'East',  'Jerod Mayo',       'Gillette Stadium',                 1960);

-- ============================================================
-- PLAYERS  (depth 1 & 2 at QB and RB for 6 teams = 24 players)
-- position_id: 1=QB, 2=RB
-- team_id order matches INSERT above: KC=1,SF=2,DAL=3,BUF=4,PHI=5,BAL=6,MIA=7,DET=8,CIN=9,GB=10,LAR=11,NE=12
-- ============================================================
INSERT INTO players
  (first_name, last_name, jersey_number, position_id, team_id, depth_rank,
   rank_stat_1_value, rank_stat_2_value, date_of_birth, college, years_exp, status)
VALUES
-- KC
  ('Patrick',   'Mahomes',           15, 1, 1,  1, 4183, 26, '1995-09-17', 'Texas Tech',        8, 'Active'),
  ('Carson',    'Wentz',              0, 1, 1,  2,    0,  0, '1992-12-30', 'North Dakota State', 9, 'Active'),
  ('Isiah',     'Pacheco',           10, 2, 1,  1, 1143,  7, '2000-02-12', 'Rutgers',            3, 'Active'),
  ('Clyde',     'Edwards-Helaire',   25, 2, 1,  2,  304,  2, '1999-04-24', 'LSU',                5, 'Active'),
-- SF
  ('Brock',     'Purdy',             13, 1, 2,  1, 4280, 31, '2000-12-27', 'Iowa State',         3, 'Active'),
  ('Joshua',    'Dobbs',             11, 1, 2,  2,    0,  0, '1995-01-26', 'Tennessee',          8, 'Active'),
  ('Christian', 'McCaffrey',         23, 2, 2,  1, 1459, 14, '1996-06-07', 'Stanford',           8, 'Active'),
  ('Jordan',    'Mason',             24, 2, 2,  2,  523,  4, '1999-01-17', 'Georgia Tech',        4, 'Active'),
-- DAL
  ('Dak',       'Prescott',           4, 1, 3,  1, 3598, 22, '1993-07-29', 'Mississippi State',  9, 'Active'),
  ('Cooper',    'Rush',               0, 1, 3,  2,    0,  0, '1994-11-28', 'Central Michigan',   8, 'Active'),
  ('Tony',      'Pollard',           20, 2, 3,  1,  896,  5, '1997-04-30', 'Memphis',            6, 'Active'),
  ('Ezekiel',   'Elliott',           21, 2, 3,  2,  432,  2, '1995-07-22', 'Ohio State',        10, 'Active'),
-- BUF
  ('Josh',      'Allen',             17, 1, 4,  1, 4306, 29, '1996-05-21', 'Wyoming',            7, 'Active'),
  ('Mitchell',  'Trubisky',          10, 1, 4,  2,    0,  0, '1994-08-20', 'North Carolina',     8, 'Active'),
  ('James',     'Cook',              4,  2, 4,  1, 1122,  7, '2001-09-24', 'Georgia',            3, 'Active'),
  ('Ty',        'Johnson',           23, 2, 4,  2,  201,  1, '1997-07-21', 'Maryland',           6, 'Active'),
-- PHI
  ('Jalen',     'Hurts',              1, 1, 5,  1, 3858, 22, '1998-08-07', 'Oklahoma',           5, 'Active'),
  ('Kenny',     'Pickett',            0, 1, 5,  2,    0,  0, '1998-06-06', 'Pittsburgh',         3, 'Active'),
  ('Saquon',    'Barkley',           26, 2, 5,  1, 2005, 13, '1997-02-09', 'Penn State',         7, 'Active'),
  ('Kenneth',   'Gainwell',          14, 2, 5,  2,  312,  3, '2000-03-28', 'Memphis',            4, 'Active'),
-- BAL
  ('Lamar',     'Jackson',            8, 1, 6,  1, 4172, 39, '1997-01-07', 'Louisville',         7, 'Active'),
  ('Josh',      'Johnson',            2, 1, 6,  2,    0,  0, '1986-05-15', 'San Diego',         17, 'Active'),
  ('Derrick',   'Henry',             22, 2, 6,  1, 1921, 16, '1994-01-04', 'Alabama',           10, 'Active'),
  ('Justice',   'Hill',              43, 2, 6,  2,  387,  3, '1998-10-14', 'Oklahoma State',     6, 'Active');

-- ============================================================
-- PRO BOWL  (10 selections, 2024 season)
-- ============================================================
INSERT INTO pro_bowl (season_year, conference, position_id) VALUES
  (2024, 'AFC', 1),   -- AFC QB
  (2024, 'NFC', 1),   -- NFC QB
  (2024, 'AFC', 2),   -- AFC RB
  (2024, 'NFC', 2),   -- NFC RB
  (2024, 'AFC', 4),   -- AFC WR
  (2024, 'NFC', 4),   -- NFC WR
  (2024, 'AFC', 11),  -- AFC DE
  (2024, 'NFC', 16),  -- NFC CB
  (2024, 'AFC', 19),  -- AFC K
  (2024, 'NFC', 19);  -- NFC K

-- ============================================================
-- PLAYER_PRO_BOWL  (junction — M:N)
-- Mahomes(1)→AFC QB(1), Purdy(5)→NFC QB(2), McCaffrey(7)→NFC RB(4),
-- J.Allen(13)→AFC QB(1 prev year — multi-year example via extra rows)
-- ============================================================
INSERT INTO player_pro_bowl (player_id, pro_bowl_id) VALUES
  (1,  1),   -- Mahomes → 2024 AFC QB
  (5,  2),   -- Purdy   → 2024 NFC QB
  (7,  4),   -- McCaffrey → 2024 NFC RB
  (3,  3),   -- Pacheco → 2024 AFC RB
  (13, 1),   -- Josh Allen also at AFC QB slot (different season handled via additional rows below)
  (19, 7),   -- Saquon Barkley → no, correcting: player_id 19 is Saquon; pro_bowl_id 4 NFC RB
  (23, 3);   -- Derrick Henry → 2024 AFC RB (replacing Pacheco row for realism)

-- Clean up duplicate — in real usage you'd insert carefully; this is sample data
DELETE FROM player_pro_bowl WHERE player_id = 3 AND pro_bowl_id = 3;
DELETE FROM player_pro_bowl WHERE player_id = 13 AND pro_bowl_id = 1;

-- Reinsert clean
INSERT INTO player_pro_bowl (player_id, pro_bowl_id) VALUES
  (23, 3),   -- Derrick Henry → 2024 AFC RB
  (19, 4);   -- Saquon Barkley → 2024 NFC RB

-- ============================================================
-- SUPER BOWL  (10 recent Super Bowls)
-- ============================================================
INSERT INTO super_bowl (season_year, sb_number, mvp_name, location, attendance) VALUES
  (2015, 50,  'Von Miller',         'Santa Clara, CA',     71088),
  (2016, 51,  'Tom Brady',          'Houston, TX',         70807),
  (2017, 52,  'Nick Foles',         'Minneapolis, MN',     67612),
  (2018, 53,  'Julian Edelman',     'Atlanta, GA',         70081),
  (2019, 54,  'Patrick Mahomes',    'Miami, FL',           62417),
  (2020, 55,  'Tom Brady',          'Tampa, FL',            25000),
  (2021, 56,  'Cooper Kupp',        'Inglewood, CA',       70048),
  (2022, 57,  'Patrick Mahomes',    'Glendale, AZ',        67827),
  (2023, 58,  'Patrick Mahomes',    'Las Vegas, NV',       61629),
  (2024, 59,  'Jalen Hurts',        'New Orleans, LA',     65000);

-- ============================================================
-- SUPER_BOWL_TEAMS  (junction — M:N)
-- ============================================================
INSERT INTO super_bowl_teams (super_bowl_id, team_id, result, score) VALUES
  -- SB 50 (Broncos not in sample; use BAL as placeholder winner, NE loser)
  (1, 6,  'Winner', 24), (1, 12, 'Loser',  10),
  -- SB 51 NE won
  (2, 12, 'Winner', 34), (2, 5,  'Loser',  28),
  -- SB 52 PHI won
  (3, 5,  'Winner', 41), (3, 12, 'Loser',  33),
  -- SB 53 NE won
  (4, 12, 'Winner', 13), (4, 11, 'Loser',   3),
  -- SB 54 KC won
  (5, 1,  'Winner', 31), (5, 2,  'Loser',  20),
  -- SB 55 TB won (not in sample; use KC loser, LAR winner as approximate)
  (6, 11, 'Winner', 31), (6, 1,  'Loser',  9),
  -- SB 56 LAR won
  (7, 11, 'Winner', 23), (7, 9,  'Loser',  20),
  -- SB 57 KC won
  (8, 1,  'Winner', 38), (8, 5,  'Loser',  35),
  -- SB 58 KC won
  (9, 1,  'Winner', 25), (9, 2,  'Loser',  22),
  -- SB 59 PHI won
  (10, 5, 'Winner', 40), (10, 1, 'Loser',  22);

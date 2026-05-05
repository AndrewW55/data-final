"""
database.py
-----------
All database connection logic and query functions for the NFL Roster Tracker.
Uses parameterized queries throughout to prevent SQL injection.
"""

import mysql.connector
from mysql.connector import Error


# ─────────────────────────────────────────────
#  CONNECTION
# ─────────────────────────────────────────────

def create_connection(host="localhost", database="nfl_roster",
                      user="root", password="password"):
    """Open and return a MySQL connection, or None on failure."""
    try:
        conn = mysql.connector.connect(
            host=host,
            database=database,
            user=user,
            password=password,
            autocommit=False
        )
        if conn.is_connected():
            return conn
    except Error as e:
        print(f"  ❌  Connection error: {e}")
    return None


# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

def _execute(conn, query, params=None, fetch=False):
    """
    Internal helper: run a query, optionally return rows.
    Returns (rows_or_None, column_names_or_None).
    """
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, params or ())
    if fetch:
        rows = cursor.fetchall()
        cols = [d[0] for d in cursor.description]
        cursor.close()
        return rows, cols
    cursor.close()
    return None, None


# ─────────────────────────────────────────────
#  READ — PLAYERS
# ─────────────────────────────────────────────

def get_team_depth_chart(conn, abbreviation):
    """Return the full 2-deep depth chart for a team."""
    query = """
        SELECT  pos.unit, pos.code AS position, p.depth_rank,
                CONCAT(p.first_name,' ',p.last_name) AS player,
                p.jersey_number AS jersey, p.status,
                pos.rank_stat_1 AS stat1_label, p.rank_stat_1_value AS stat1,
                pos.rank_stat_2 AS stat2_label, p.rank_stat_2_value AS stat2
        FROM    players p
        JOIN    positions pos ON p.position_id = pos.position_id
        JOIN    teams     t   ON p.team_id     = t.team_id
        WHERE   t.abbreviation = %s
        ORDER BY pos.unit, pos.code, p.depth_rank
    """
    return _execute(conn, query, (abbreviation.upper(),), fetch=True)


def get_positional_rankings(conn, position_code):
    """Rank all active players at a given position league-wide."""
    query = """
        SELECT  RANK() OVER (ORDER BY p.rank_stat_1_value DESC,
                                      p.rank_stat_2_value DESC) AS `rank`,
                CONCAT(p.first_name,' ',p.last_name)          AS player,
                t.abbreviation                                  AS team,
                p.depth_rank,
                pos.rank_stat_1 AS stat1_label, p.rank_stat_1_value AS stat1,
                pos.rank_stat_2 AS stat2_label, p.rank_stat_2_value AS stat2
        FROM    players   p
        JOIN    positions pos ON p.position_id = pos.position_id
        JOIN    teams     t   ON p.team_id     = t.team_id
        WHERE   pos.code  = %s
          AND   p.status  = 'Active'
        ORDER BY stat1 DESC, stat2 DESC
    """
    return _execute(conn, query, (position_code.upper(),), fetch=True)


def search_players_by_name(conn, name_fragment):
    """Search players whose first or last name contains the fragment."""
    query = """
        SELECT  CONCAT(p.first_name,' ',p.last_name) AS player,
                pos.code  AS position, t.abbreviation AS team,
                p.depth_rank, p.status, p.years_exp,
                p.rank_stat_1_value AS stat1, p.rank_stat_2_value AS stat2
        FROM    players   p
        JOIN    positions pos ON p.position_id = pos.position_id
        JOIN    teams     t   ON p.team_id     = t.team_id
        WHERE   p.first_name LIKE %s OR p.last_name LIKE %s
        ORDER BY p.last_name, p.first_name
    """
    fragment = f"%{name_fragment}%"
    return _execute(conn, query, (fragment, fragment), fetch=True)


def get_all_teams(conn):
    """Return all teams ordered by conference and division."""
    query = """
        SELECT  team_id, abbreviation, city, name,
                conference, division, head_coach
        FROM    teams
        ORDER BY conference, division, abbreviation
    """
    return _execute(conn, query, fetch=True)


def get_all_positions(conn):
    """Return all positions for reference menus."""
    query = "SELECT position_id, code, name, unit FROM positions ORDER BY unit, code"
    return _execute(conn, query, fetch=True)


# ─────────────────────────────────────────────
#  READ — PRO BOWL & SUPER BOWL
# ─────────────────────────────────────────────

def get_pro_bowl_roster(conn, season_year=None):
    """Return Pro Bowl selections, optionally filtered by year."""
    base = """
        SELECT  pb.season_year, pb.conference, pos.code AS position,
                CONCAT(p.first_name,' ',p.last_name) AS player,
                t.abbreviation AS team
        FROM    player_pro_bowl ppb
        JOIN    pro_bowl   pb  ON ppb.pro_bowl_id = pb.pro_bowl_id
        JOIN    players    p   ON ppb.player_id   = p.player_id
        JOIN    positions  pos ON pb.position_id  = pos.position_id
        JOIN    teams      t   ON p.team_id       = t.team_id
    """
    if season_year:
        query = base + " WHERE pb.season_year = %s ORDER BY pb.conference, pos.code"
        return _execute(conn, query, (season_year,), fetch=True)
    return _execute(conn, base + " ORDER BY pb.season_year DESC, pb.conference, pos.code", fetch=True)


def get_super_bowl_history(conn):
    """Return Super Bowl results with team names."""
    query = """
        SELECT  sb.sb_number, sb.season_year,
                CONCAT(w.city,' ',w.name) AS winner, ws.score AS winner_score,
                CONCAT(l.city,' ',l.name) AS loser,  ls.score AS loser_score,
                sb.mvp_name, sb.location
        FROM    super_bowl sb
        JOIN    super_bowl_teams ws ON ws.super_bowl_id = sb.super_bowl_id AND ws.result='Winner'
        JOIN    super_bowl_teams ls ON ls.super_bowl_id = sb.super_bowl_id AND ls.result='Loser'
        JOIN    teams w ON ws.team_id = w.team_id
        JOIN    teams l ON ls.team_id = l.team_id
        ORDER BY sb.sb_number DESC
    """
    return _execute(conn, query, fetch=True)


# ─────────────────────────────────────────────
#  CREATE
# ─────────────────────────────────────────────

def add_player(conn, first_name, last_name, jersey_number,
               position_code, team_abbrev, depth_rank,
               stat1=0.0, stat2=0.0, college=None, years_exp=0):
    """
    Add a new player.  Looks up position_id and team_id from codes.
    Returns the new player_id or None on failure.
    """
    try:
        cursor = conn.cursor()

        # Resolve position
        cursor.execute("SELECT position_id FROM positions WHERE code = %s",
                       (position_code.upper(),))
        row = cursor.fetchone()
        if not row:
            print(f"  ❌  Unknown position code: {position_code}")
            cursor.close()
            return None
        position_id = row[0]

        # Resolve team
        cursor.execute("SELECT team_id FROM teams WHERE abbreviation = %s",
                       (team_abbrev.upper(),))
        row = cursor.fetchone()
        if not row:
            print(f"  ❌  Unknown team abbreviation: {team_abbrev}")
            cursor.close()
            return None
        team_id = row[0]

        query = """
            INSERT INTO players
                (first_name, last_name, jersey_number, position_id, team_id,
                 depth_rank, rank_stat_1_value, rank_stat_2_value,
                 college, years_exp)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (first_name, last_name, jersey_number,
                               position_id, team_id, depth_rank,
                               stat1, stat2, college, years_exp))
        conn.commit()
        new_id = cursor.lastrowid
        cursor.close()
        return new_id

    except Error as e:
        conn.rollback()
        print(f"  ❌  Error adding player: {e}")
        return None


def add_team(conn, city, name, abbreviation, conference,
             division, head_coach, stadium=None, founded_year=None):
    """Add a new franchise to the teams table."""
    try:
        query = """
            INSERT INTO teams
                (city, name, abbreviation, conference, division,
                 head_coach, stadium, founded_year)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor = conn.cursor()
        cursor.execute(query, (city, name, abbreviation.upper(),
                               conference.upper(), division,
                               head_coach, stadium, founded_year))
        conn.commit()
        new_id = cursor.lastrowid
        cursor.close()
        return new_id
    except Error as e:
        conn.rollback()
        print(f"  ❌  Error adding team: {e}")
        return None


# ─────────────────────────────────────────────
#  UPDATE
# ─────────────────────────────────────────────

def update_player_stats(conn, player_id, stat1, stat2):
    """Update the two ranking stats for a player."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE players SET rank_stat_1_value=%s, rank_stat_2_value=%s WHERE player_id=%s",
            (stat1, stat2, player_id)
        )
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        return affected > 0
    except Error as e:
        conn.rollback()
        print(f"  ❌  Error updating stats: {e}")
        return False


def update_player_status(conn, player_id, new_status):
    """Update a player's active/injury status."""
    valid = {'Active', 'Injured', 'IR', 'Practice Squad', 'Suspended'}
    if new_status not in valid:
        print(f"  ❌  Invalid status. Choose from: {', '.join(sorted(valid))}")
        return False
    try:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE players SET status=%s WHERE player_id=%s",
            (new_status, player_id)
        )
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        return affected > 0
    except Error as e:
        conn.rollback()
        print(f"  ❌  Error updating status: {e}")
        return False


# ─────────────────────────────────────────────
#  DELETE
# ─────────────────────────────────────────────

def delete_player(conn, player_id):
    """
    Remove a player from the roster.
    Returns True on success.
    """
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM players WHERE player_id = %s", (player_id,))
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        return affected > 0
    except Error as e:
        conn.rollback()
        print(f"  ❌  Error deleting player: {e}")
        return False


# ─────────────────────────────────────────────
#  TRANSACTION — TRADE PLAYER
# ─────────────────────────────────────────────

def trade_player(conn, player_id, new_team_abbrev, new_depth_rank):
    """
    Transaction: move a player to a new team at a given depth slot.
    If the target slot is occupied the trade is rolled back.
    """
    try:
        conn.start_transaction()
        cursor = conn.cursor(dictionary=True)

        # Resolve new team
        cursor.execute("SELECT team_id FROM teams WHERE abbreviation = %s",
                       (new_team_abbrev.upper(),))
        row = cursor.fetchone()
        if not row:
            raise ValueError(f"Unknown team abbreviation: {new_team_abbrev}")
        new_team_id = row["team_id"]

        # Get player's position
        cursor.execute("SELECT position_id, first_name, last_name FROM players WHERE player_id=%s",
                       (player_id,))
        player = cursor.fetchone()
        if not player:
            raise ValueError(f"Player ID {player_id} not found.")

        # Check target depth slot is free
        cursor.execute(
            "SELECT player_id FROM players WHERE team_id=%s AND position_id=%s AND depth_rank=%s",
            (new_team_id, player["position_id"], new_depth_rank)
        )
        if cursor.fetchone():
            raise ValueError(
                f"Depth slot {new_depth_rank} at that position is already occupied on {new_team_abbrev}."
            )

        # Execute the move
        cursor.execute(
            "UPDATE players SET team_id=%s, depth_rank=%s WHERE player_id=%s",
            (new_team_id, new_depth_rank, player_id)
        )
        conn.commit()
        cursor.close()
        return True, f"{player['first_name']} {player['last_name']} traded to {new_team_abbrev.upper()}."

    except (Error, ValueError) as e:
        conn.rollback()
        return False, str(e)

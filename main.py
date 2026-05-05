"""
main.py
-------
NFL Roster Tracker — command-line application.
Run:  python main.py
"""

"""
# 1. Start the container
docker run --name nfl-mysql \
  -e MYSQL_ROOT_PASSWORD=nflpassword \
  -e MYSQL_DATABASE=nfl_roster \
  -p 3306:3306 \
  -d mysql:8.0

# 2. Wait ~15 seconds, then load the SQL
docker exec -i nfl-mysql mysql -u root -pnflpassword nfl_roster < sql/schema.sql
docker exec -i nfl-mysql mysql -u root -pnflpassword nfl_roster < sql/data.sql

# 3. Run the app — just hit Enter at every prompt to use Docker defaults
python main.py
"""

import sys
from database import (
    create_connection,
    get_team_depth_chart, get_positional_rankings, search_players_by_name,
    get_all_teams, get_all_positions,
    get_pro_bowl_roster, get_super_bowl_history,
    add_player, add_team,
    update_player_stats, update_player_status,
    delete_player, trade_player,
)

# ─────────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────────

BOLD   = "\033[1m"
CYAN   = "\033[96m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
RESET  = "\033[0m"

BANNER = f"""{CYAN}{BOLD}
╔══════════════════════════════════════════════════╗
║          🏈  NFL ROSTER TRACKER  🏈              ║
║          MySQL Database Manager                  ║
╚══════════════════════════════════════════════════╝{RESET}"""


def print_table(rows, cols, title=""):
    """Pretty-print a list of dicts as a fixed-width table."""
    if not rows:
        print(f"  {YELLOW}No results found.{RESET}")
        return

    # Calculate column widths
    widths = {c: len(c) for c in cols}
    for row in rows:
        for c in cols:
            widths[c] = max(widths[c], len(str(row.get(c, "") or "")))

    sep   = "+" + "+".join("-" * (widths[c] + 2) for c in cols) + "+"
    header = "|" + "|".join(f" {BOLD}{c.upper():^{widths[c]}}{RESET} " for c in cols) + "|"

    if title:
        print(f"\n{CYAN}{BOLD}  {title}{RESET}")
    print(sep)
    print(header)
    print(sep)
    for row in rows:
        line = "|"
        for c in cols:
            val = str(row.get(c, "") or "")
            line += f" {val:<{widths[c]}} |"
        print(line)
    print(sep)
    print(f"  {len(rows)} row(s)\n")


def input_int(prompt, min_val=None, max_val=None):
    """Prompt for an integer with optional range validation."""
    while True:
        raw = input(prompt).strip()
        if not raw.lstrip("-").isdigit():
            print(f"  {RED}Please enter a whole number.{RESET}")
            continue
        val = int(raw)
        if min_val is not None and val < min_val:
            print(f"  {RED}Value must be ≥ {min_val}.{RESET}")
            continue
        if max_val is not None and val > max_val:
            print(f"  {RED}Value must be ≤ {max_val}.{RESET}")
            continue
        return val


def input_float(prompt):
    """Prompt for a decimal number."""
    while True:
        raw = input(prompt).strip()
        try:
            return float(raw)
        except ValueError:
            print(f"  {RED}Please enter a number (e.g. 4183 or 91.5).{RESET}")


def confirm(prompt="  Are you sure? (yes/no): "):
    """Ask for explicit yes/no confirmation."""
    return input(prompt).strip().lower() in ("yes", "y")


# ─────────────────────────────────────────────
#  MENU SECTIONS
# ─────────────────────────────────────────────

def menu_read(conn):
    """Sub-menu: all read / search options."""
    options = {
        "1": "View team depth chart",
        "2": "League positional rankings",
        "3": "Search players by name",
        "4": "Pro Bowl roster",
        "5": "Super Bowl history",
        "6": "List all teams",
        "0": "← Back",
    }
    while True:
        print(f"\n{BOLD}── READ / SEARCH ──────────────────────────{RESET}")
        for k, v in options.items():
            print(f"  {CYAN}{k}{RESET}  {v}")
        choice = input("\n  Choice: ").strip()

        if choice == "1":
            teams, _ = get_all_teams(conn)
            abbrevs = [t["abbreviation"] for t in teams] if teams else []
            team = input("  Team abbreviation (e.g. KC, SF): ").strip().upper()
            if team not in abbrevs:
                print(f"  {RED}Unknown abbreviation. Valid: {', '.join(abbrevs)}{RESET}")
                continue
            rows, cols = get_team_depth_chart(conn, team)
            print_table(rows, cols, title=f"{team} Depth Chart")

        elif choice == "2":
            positions, _ = get_all_positions(conn)
            codes = [p["code"] for p in positions] if positions else []
            print("  Valid codes: " + ", ".join(codes))
            pos = input("  Position code: ").strip().upper()
            if pos not in codes:
                print(f"  {RED}Unknown position code.{RESET}")
                continue
            rows, cols = get_positional_rankings(conn, pos)
            print_table(rows, cols, title=f"{pos} — League Rankings")

        elif choice == "3":
            fragment = input("  Enter name (or partial name): ").strip()
            if not fragment:
                print(f"  {RED}Name cannot be empty.{RESET}")
                continue
            rows, cols = search_players_by_name(conn, fragment)
            print_table(rows, cols, title=f'Search Results: "{fragment}"')

        elif choice == "4":
            year_raw = input("  Season year (leave blank for all): ").strip()
            year = int(year_raw) if year_raw.isdigit() else None
            rows, cols = get_pro_bowl_roster(conn, season_year=year)
            print_table(rows, cols, title="Pro Bowl Roster")

        elif choice == "5":
            rows, cols = get_super_bowl_history(conn)
            print_table(rows, cols, title="Super Bowl History")

        elif choice == "6":
            rows, cols = get_all_teams(conn)
            print_table(rows, cols, title="All Teams")

        elif choice == "0":
            break
        else:
            print(f"  {RED}Invalid option.{RESET}")


def menu_create(conn):
    """Sub-menu: add a player or team."""
    options = {
        "1": "Add a new player",
        "2": "Add a new team",
        "0": "← Back",
    }
    while True:
        print(f"\n{BOLD}── CREATE ──────────────────────────────────{RESET}")
        for k, v in options.items():
            print(f"  {CYAN}{k}{RESET}  {v}")
        choice = input("\n  Choice: ").strip()

        if choice == "1":
            print(f"\n  {BOLD}Add New Player{RESET}")
            first    = input("  First name: ").strip()
            last     = input("  Last name: ").strip()
            if not first or not last:
                print(f"  {RED}Name fields required.{RESET}")
                continue
            jersey   = input_int("  Jersey number (0-99): ", 0, 99)
            positions, _ = get_all_positions(conn)
            codes    = [p["code"] for p in positions] if positions else []
            print("  Valid position codes: " + ", ".join(codes))
            pos_code = input("  Position code: ").strip().upper()
            if pos_code not in codes:
                print(f"  {RED}Invalid position code.{RESET}")
                continue
            teams, _ = get_all_teams(conn)
            abbrevs  = [t["abbreviation"] for t in teams] if teams else []
            team_ab  = input("  Team abbreviation: ").strip().upper()
            if team_ab not in abbrevs:
                print(f"  {RED}Invalid team abbreviation.{RESET}")
                continue
            depth    = input_int("  Depth rank (1 or 2): ", 1, 2)
            stat1    = input_float("  Primary stat value (e.g. 4183.0): ")
            stat2    = input_float("  Secondary stat value (e.g. 26.0): ")
            college  = input("  College (optional): ").strip() or None
            years    = input_int("  Years of experience: ", 0, 30)

            new_id = add_player(conn, first, last, jersey, pos_code,
                                team_ab, depth, stat1, stat2, college, years)
            if new_id:
                print(f"  {GREEN}✅  Player added with ID {new_id}.{RESET}")

        elif choice == "2":
            print(f"\n  {BOLD}Add New Team{RESET}")
            city      = input("  City: ").strip()
            name      = input("  Team name: ").strip()
            abbrev    = input("  Abbreviation (2-3 chars): ").strip()
            conf      = input("  Conference (AFC/NFC): ").strip().upper()
            div       = input("  Division (North/South/East/West): ").strip().title()
            coach     = input("  Head coach: ").strip()
            stadium   = input("  Stadium (optional): ").strip() or None
            yr_raw    = input("  Founded year (optional): ").strip()
            founded   = int(yr_raw) if yr_raw.isdigit() else None

            if conf not in ("AFC", "NFC"):
                print(f"  {RED}Conference must be AFC or NFC.{RESET}")
                continue
            if div not in ("North", "South", "East", "West"):
                print(f"  {RED}Division must be North/South/East/West.{RESET}")
                continue

            new_id = add_team(conn, city, name, abbrev, conf, div,
                              coach, stadium, founded)
            if new_id:
                print(f"  {GREEN}✅  Team added with ID {new_id}.{RESET}")

        elif choice == "0":
            break
        else:
            print(f"  {RED}Invalid option.{RESET}")


def menu_update(conn):
    """Sub-menu: update stats or status."""
    options = {
        "1": "Update player stats",
        "2": "Update player status",
        "0": "← Back",
    }
    while True:
        print(f"\n{BOLD}── UPDATE ──────────────────────────────────{RESET}")
        for k, v in options.items():
            print(f"  {CYAN}{k}{RESET}  {v}")
        choice = input("\n  Choice: ").strip()

        if choice in ("1", "2"):
            fragment = input("  Search player by name: ").strip()
            rows, cols = search_players_by_name(conn, fragment)
            if not rows:
                print(f"  {YELLOW}No players found.{RESET}")
                continue
            # Show abbreviated list with IDs
            print()
            for r in rows:
                print(f"    ID ? — use query to find ID | {r['player']} ({r['position']}, {r['team']})")
            print(f"  {YELLOW}Tip: run a search query to confirm the player_id.{RESET}")
            pid = input_int("  Enter player_id to update: ", 1)

            if choice == "1":
                stat1 = input_float("  New primary stat value: ")
                stat2 = input_float("  New secondary stat value: ")
                if update_player_stats(conn, pid, stat1, stat2):
                    print(f"  {GREEN}✅  Stats updated.{RESET}")
                else:
                    print(f"  {RED}No rows affected. Check the player ID.{RESET}")

            elif choice == "2":
                statuses = ['Active', 'Injured', 'IR', 'Practice Squad', 'Suspended']
                for i, s in enumerate(statuses, 1):
                    print(f"    {i}. {s}")
                idx = input_int("  Choose status number: ", 1, len(statuses))
                new_status = statuses[idx - 1]
                if update_player_status(conn, pid, new_status):
                    print(f"  {GREEN}✅  Status updated to {new_status}.{RESET}")
                else:
                    print(f"  {RED}Update failed.{RESET}")

        elif choice == "0":
            break
        else:
            print(f"  {RED}Invalid option.{RESET}")


def menu_delete(conn):
    """Sub-menu: delete a player (with confirmation)."""
    print(f"\n{BOLD}── DELETE ──────────────────────────────────{RESET}")
    fragment = input("  Search player to delete: ").strip()
    rows, _ = search_players_by_name(conn, fragment)
    if not rows:
        print(f"  {YELLOW}No players found.{RESET}")
        return

    for r in rows:
        print(f"    {r['player']} — {r['position']} — {r['team']}")

    pid = input_int("  Enter player_id to DELETE: ", 1)
    print(f"  {RED}{BOLD}⚠  This will permanently remove the player from the database.{RESET}")
    if not confirm():
        print("  Cancelled.")
        return

    if delete_player(conn, pid):
        print(f"  {GREEN}✅  Player deleted.{RESET}")
    else:
        print(f"  {RED}Delete failed. Check the player ID.{RESET}")


def menu_transaction(conn):
    """Execute a trade transaction (multi-step, atomic)."""
    print(f"\n{BOLD}── TRADE PLAYER (Transaction) ───────────────{RESET}")
    fragment = input("  Search player to trade: ").strip()
    rows, _ = search_players_by_name(conn, fragment)
    if not rows:
        print(f"  {YELLOW}No players found.{RESET}")
        return

    for r in rows:
        print(f"    {r['player']} — {r['position']} — {r['team']} (depth {r['depth_rank']})")

    pid        = input_int("  Enter player_id to trade: ", 1)
    teams, _   = get_all_teams(conn)
    abbrevs    = [t["abbreviation"] for t in teams] if teams else []
    new_team   = input("  New team abbreviation: ").strip().upper()
    if new_team not in abbrevs:
        print(f"  {RED}Invalid team abbreviation.{RESET}")
        return
    new_depth  = input_int("  New depth rank (1 or 2): ", 1, 2)

    print(f"\n  Trading player {pid} → {new_team} at depth {new_depth}.")
    if not confirm():
        print("  Trade cancelled.")
        return

    ok, msg = trade_player(conn, pid, new_team, new_depth)
    if ok:
        print(f"  {GREEN}✅  {msg}{RESET}")
    else:
        print(f"  {RED}❌  Trade failed: {msg}{RESET}")


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────

def main():
    print(BANNER)

    # ── Connection setup ──
    print(f"\n{BOLD}Database Connection{RESET}")
    print(f"  {YELLOW}Docker defaults shown — press Enter to accept{RESET}")
    host     = input("  Host     [127.0.0.1]: ").strip() or "127.0.0.1"
    port_raw = input("  Port     [3306]: ").strip()
    port     = int(port_raw) if port_raw.isdigit() else 3306
    database = input("  Database [nfl_roster]: ").strip() or "nfl_roster"
    user     = input("  User     [root]: ").strip() or "root"
    password = input("  Password [nflpassword]: ").strip() or "nflpassword"

    conn = create_connection(host, database, user, password, port)
    if not conn:
        print(f"\n  {RED}Could not connect to MySQL. Check your credentials and try again.{RESET}")
        sys.exit(1)

    print(f"\n  {GREEN}✅  Connected to {BOLD}{database}{RESET}{GREEN} on {host}.{RESET}")

    # ── Main menu ──
    main_options = {
        "1": "📋  Read / Search",
        "2": "➕  Create",
        "3": "✏️   Update",
        "4": "🗑️   Delete",
        "5": "🔄  Trade Player (Transaction)",
        "0": "🚪  Exit",
    }

    while True:
        print(f"\n{CYAN}{BOLD}{'─'*50}{RESET}")
        print(f"{BOLD}  MAIN MENU{RESET}")
        print(f"{CYAN}{BOLD}{'─'*50}{RESET}")
        for k, v in main_options.items():
            print(f"  {CYAN}{k}{RESET}  {v}")

        choice = input(f"\n  {BOLD}Choice: {RESET}").strip()

        if   choice == "1": menu_read(conn)
        elif choice == "2": menu_create(conn)
        elif choice == "3": menu_update(conn)
        elif choice == "4": menu_delete(conn)
        elif choice == "5": menu_transaction(conn)
        elif choice == "0":
            print(f"\n  {GREEN}Goodbye! 🏈{RESET}\n")
            break
        else:
            print(f"  {RED}Invalid option — enter a number from the menu.{RESET}")

    conn.close()


if __name__ == "__main__":
    main()

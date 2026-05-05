# 🏈 NFL Roster Tracker

A MySQL-backed database and Python CLI application for tracking NFL team rosters (top-2 depth chart per position), ranking players by position-specific stats, and recording Pro Bowl and Super Bowl history.

---

## ERD (Entity Relationship Diagram)

> See `erd.png` in the repo root — generated from the Crow's Foot ERD above.

```
teams ──< players >── positions
  │                        │
  │                    pro_bowl
  │                        │
  └── super_bowl_teams  player_pro_bowl
           │
       super_bowl
```

**Relationships:**
- `teams` → `players` — **1:M** (one team has many players)
- `positions` → `players` — **1:M** (one position classifies many players)
- `players` ↔ `pro_bowl` — **M:N** via `player_pro_bowl` (a player earns many Pro Bowl selections; each selection has one player)
- `teams` ↔ `super_bowl` — **M:N** via `super_bowl_teams` (a team appears in many Super Bowls; each Super Bowl has 2 teams)

---

## Table Descriptions

| Table | Purpose |
|---|---|
| `teams` | All 32 NFL franchises — city, name, abbreviation, conference, division, coach, stadium |
| `positions` | 22 standard positions with two ranking-stat labels per position (e.g. QB → Passing Yards + Passing TDs) |
| `players` | Roster entries locked to depth 1 or 2 per team/position slot. Stores two generic stat columns whose labels come from `positions`. |
| `pro_bowl` | One row per Pro Bowl selection slot (season + conference + position). |
| `player_pro_bowl` | **Junction table** — resolves the M:N between players and pro_bowl entries. |
| `super_bowl` | One row per Super Bowl game (number, year, MVP, location, attendance). |
| `super_bowl_teams` | **Junction table** — resolves the M:N between teams and super_bowl. Stores result (Winner/Loser) and score per team. |

---

## Setup Instructions

### 1. Prerequisites

- MySQL 8.0+
- Python 3.9+

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Create the database

Log into MySQL and run the SQL files in order:

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p < sql/data.sql
```

Or from inside the MySQL shell:

```sql
SOURCE sql/schema.sql;
SOURCE sql/data.sql;
```

### 4. Run the application

```bash
cd python
python main.py
```

You'll be prompted for your MySQL host, database name, username, and password.

---

## Features

### Read / Search
- View any team's full 2-deep depth chart by position
- League-wide positional rankings (all QBs ranked by passing yards + TDs, etc.)
- Search players by partial first or last name
- View Pro Bowl rosters by season
- View Super Bowl history with scores and MVPs

### Create
- Add a new player to a team's depth chart
- Add a new NFL franchise

### Update
- Update a player's season stats (both ranking stat columns)
- Update a player's status (Active / Injured / IR / Practice Squad / Suspended)

### Delete
- Remove a player from the roster (requires typed confirmation)

### Transaction — Trade Player
- Atomically move a player to a new team at a specified depth rank
- Rolls back automatically if the target depth slot is already occupied

---

## File Structure

```
nfl_roster/
├── sql/
│   ├── schema.sql       # CREATE TABLE statements with all constraints
│   ├── data.sql         # Realistic sample data (10+ rows per table)
│   └── queries.sql      # 9 example queries
├── python/
│   ├── main.py          # CLI application entry point
│   └── database.py      # All DB connection and query functions
├── requirements.txt
└── README.md
```

---

## Example Usage

```
╔══════════════════════════════════════════════════╗
║          🏈  NFL ROSTER TRACKER  🏈              ║
║          MySQL Database Manager                  ║
╚══════════════════════════════════════════════════╝

Database Connection
  Host     [localhost]:
  Database [nfl_roster]:
  User     [root]:
  Password:

  ✅  Connected to nfl_roster on localhost.

──────────────────────────────────────────────────
  MAIN MENU
──────────────────────────────────────────────────
  1  📋  Read / Search
  2  ➕  Create
  3  ✏️   Update
  4  🗑️   Delete
  5  🔄  Trade Player (Transaction)
  0  🚪  Exit
```

---

## Known Limitations

- The depth chart only holds 2 players per position per team — a `UNIQUE` constraint enforces this. Inserting a 3rd will raise a MySQL error (caught and displayed gracefully).
- The `player_pro_bowl` junction allows a player to be linked to multiple Pro Bowl entries across seasons, but the app's create menu does not yet include a Pro Bowl assignment workflow — those entries must be added directly via SQL.
- `founded_year` uses MySQL's `YEAR` type, which only stores 4-digit years from 1901–2155.
- The sample data covers 12 of the 32 NFL teams and only the QB and RB positions. Adding all 32 teams and all 22 positions is straightforward with additional `INSERT` statements.

---

## Reflection

Building this project reinforced how much schema design decisions ripple outward into everything else. The choice to store `rank_stat_1` and `rank_stat_2` as generic column labels in the `positions` table — rather than creating separate stat tables per position — made the Python query layer dramatically simpler. Every position can be ranked with the same SQL window function, and the label displayed to the user is always correct without any application-level branching.

The trickiest constraint to implement correctly was the top-2 depth chart. A simple `CHECK (depth_rank IN (1, 2))` prevents bad values, but the real enforcement comes from the composite `UNIQUE KEY (team_id, position_id, depth_rank)` — which means the database itself will reject a third player at any given slot, regardless of what the application layer does. Pushing data integrity into the schema rather than relying on application code is a lesson that generalises well.

The transaction for the trade feature was a good reminder that multi-step operations need to be atomic. Without wrapping the "check slot is free → update player" sequence in a single transaction, a race condition could theoretically allow two concurrent operations to both pass the check and then collide on the unique key. Even for a single-user CLI tool, writing the transaction correctly from the start is the right habit.

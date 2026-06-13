# Campus Maintenance & Complaint Management System

A database-driven system for managing student maintenance complaints, worker assignments, SLA tracking, and monthly reporting. Built as a Database Systems lab project using Oracle SQL/PL/SQL with a web frontend.

## Project Overview

Students submit complaints (category + priority) tied to specific campus locations. Supervisors assign workers, track status through resolution, and collect feedback. The database enforces SLA deadlines, auto-escalation, chronic-issue detection, and worker performance scoring via triggers, procedures, and functions.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Database | Oracle Database (SQL, PL/SQL) |
| Backend | Node.js + Express + `oracledb` |
| Frontend | HTML, CSS, JavaScript |
| Diagrams | dbdiagram.io / draw.io |

## Features

### Core
- Student complaint submission with category and priority
- Worker assignment and status tracking
- Feedback and rating after completion
- Monthly maintenance reports

### Enhanced
- **SLA tracking** — urgent = 4 hrs, medium = 24 hrs, low = 72 hrs (auto-set via trigger)
- **Auto-escalation** — overdue assigned complaints upgrade priority and flag supervisor
- **Worker performance score** — from avg resolution time + feedback rating (PL/SQL function)
- **Complaint audit log** — every status change recorded (trigger-based)
- **Room/location registry** — building → floor → room
- **Recurring complaint detection** — 3+ same category at same location → chronic issue flag
- **Admin dashboard views** — top categories, slowest/overloaded workers
- **Budget tracking** — repair cost logged per resolved assignment

## Project Structure

```
dB proj/
├── sql/
│   ├── ddl/          # Table and sequence creation scripts
│   ├── dml/          # Seed and sample data
│   ├── plsql/        # Triggers, procedures, functions, views
│   └── queries/      # Advanced analytical queries
├── frontend/         # Web UI (HTML/CSS/JS + Node.js API)
├── docs/             # Schema design, data dictionary, ERD
├── assets/           # Screenshots and diagram exports
└── README.md
```

## ERD

| Resource | Path |
|----------|------|
| dbdiagram.io source | [`docs/erd.dbml`](docs/erd.dbml) |
| Schema design (3NF, relationships) | [`docs/schema_design.md`](docs/schema_design.md) |
| Column definitions | [`docs/data_dictionary.md`](docs/data_dictionary.md) |
| PNG export (optional) | Import `erd.dbml` at [dbdiagram.io](https://dbdiagram.io) → Export → `assets/erd.png` |

## Development Plan (14 Pushes)

| Push | Deliverable |
|------|-------------|
| 1 | Project setup & README *(this push)* |
| 2 | ERD & schema design document *(this push)* |
| 3 | DDL: core tables (USERS, LOCATIONS, COMPLAINTS) *(this push)* |
| 4 | DDL: supporting tables + sequences *(this push)* |
| 5 | DML: seed data *(this push)* |
| 6 | Triggers (Part 1): SLA, status log, worker availability *(this push)* |
| 7 | Triggers (Part 2): feedback score, chronic issue detection *(this push)* |
| 8 | Stored procedures *(this push)* |
| 9 | Functions *(this push)* |
| 10 | Views |
| 11 | Advanced queries |
| 12 | Frontend (HTML/CSS/JS) |
| 13 | Transaction management & exception handling |
| 14 | Final polish, demo queries, screenshots |

## Setup (after all pushes)

1. Run DDL scripts in order: `sql/ddl/01_create_tables.sql` → `03_sequences.sql`
2. Run DML: `sql/dml/01_seed_data.sql`
3. Run PL/SQL: `sql/plsql/01_triggers.sql`, `02_triggers_part2.sql` through `05_transactions.sql`
4. Configure Oracle connection in `frontend/.env`
5. Start API: `cd frontend && npm install && npm start`
6. Open `http://localhost:3000`

## Team / Course

Database Systems Lab Project — Campus Maintenance Complaint Management System.

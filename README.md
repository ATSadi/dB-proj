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

## Role Chain of Command

| Role | Portal | Responsibilities |
|------|--------|------------------|
| **Student** | `/student.html` | Submit complaints, track SLA, rate resolved work |
| **Worker** | `/worker.html` | Start/resolve assigned jobs, toggle availability |
| **Supervisor** | `/admin.html` | Assign workers, watch overdue & chronic issues |
| **Admin** | `/admin.html` | Full dashboard, performance views, monthly reports |

Workflow: **Student submits → Supervisor assigns → Worker resolves → Student rates → Admin reports**

## Demo Accounts (seed data)

Sign in with the account email and the default demo password: `Password123`.

| Role | Email |
|------|-------|
| Student | `hassan.r@stu.edu` |
| Worker | `rashid.i@campus.edu` |
| Supervisor | `omar.s@campus.edu` |
| Admin | `admin@campus.edu` |

Other students: `sana.m@stu.edu`, `bilal.a@stu.edu`, `zainab.h@stu.edu`  
Other workers: `kamran.s@campus.edu`, `nadia.f@campus.edu`, `imran.b@campus.edu`

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
- **Admin dashboard** — tabs for assign, queue, overdue, workers, chronic, reports
- **Role-based portals** — session guards, demo quick-login, mobile-responsive UI
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

## Run the Project Locally

**Full step-by-step guide:** [`docs/ORACLE_SETUP_GUIDE.md`](docs/ORACLE_SETUP_GUIDE.md)

### Database
1. Connect to Oracle (SQL Developer)
2. Run `sql/run_all.sql` (from the `sql/` folder)
3. Optionally run `sql/DEMO_QUERIES.sql` for viva demos

### Frontend + API
```bash
cd frontend
copy .env.example .env    # edit with Oracle credentials
npm install
npm start
# Open http://localhost:3000
```

| Page | Role | Features |
|------|------|----------|
| `/` | All | Login / demo accounts / role chain |
| `/student.html` | Student | Submit, filter, search, rate via modal |
| `/worker.html` | Worker | Active/done filters, SLA urgency, availability |
| `/admin.html` | Admin/Supervisor | Assign preview, queue, overdue, reports |

## Team / Course

Database Systems Lab Project — Campus Maintenance Complaint Management System.

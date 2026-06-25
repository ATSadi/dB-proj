# Oracle Setup & Demo Guide (Tomorrow's Lab)

**Read this first.** Your project code is complete, but nothing has been executed on Oracle yet. Follow this guide tonight or before class.

---

## Current Status (Honest)

| Component | Status |
|-----------|--------|
| SQL tables (DDL) | ✅ Written — not run yet |
| PL/SQL triggers (7) | ✅ Written — not run yet |
| PL/SQL procedures (6) | ✅ Written — not run yet |
| PL/SQL functions (4) | ✅ Written — not run yet |
| PL/SQL views (5) | ✅ Written — not run yet |
| Seed data | ✅ Written — not run yet |
| Web frontend | ✅ Written — needs Oracle + fixed npm |
| Oracle Database on your PC | ❌ **Not installed** |
| npm on your PC | ❌ **Broken** (Node works, npm missing) |

**Bottom line:** The project is a complete **Oracle PL/SQL** project. You must run it in **Oracle SQL Developer** tomorrow. The website is optional bonus if you have time.

---

## Yes — We Use PL/SQL (What Teacher Means)

Your teacher almost certainly means **Oracle PL/SQL** in **Oracle Database** (via SQL Developer or SQL*Plus). This project uses PL/SQL heavily:

| PL/SQL Feature | Count | Files |
|----------------|-------|-------|
| **Triggers** | 7 | `01_triggers.sql`, `02_triggers_part2.sql` |
| **Procedures** | 6 | `03_procedures.sql`, `06_transactions.sql` |
| **Functions** | 4 | `04_functions.sql` |
| **Views** | 5 | `05_views.sql` |
| **Package** | 1 | `complaint_exceptions` in `06_transactions.sql` |
| **Roles/Grants** | 4 roles | `06_transactions.sql` |

Tell your teacher: *"We built the full system in Oracle PL/SQL — triggers for SLA and audit, stored procedures for assignment and escalation, functions for performance scoring, and analytical views."*

---

## Option A — Best Demo: Oracle SQL Developer (Recommended)

### Step 1: Get Oracle Database

**If your university gives you a server account** → use that (ask lab instructor for host, port, username, password).

**If you need it on your laptop tonight:**

1. Download **Oracle Database 21c XE** (free):  
   [https://www.oracle.com/database/technologies/xe-downloads.html](https://www.oracle.com/database/technologies/xe-downloads.html)
2. Install (takes 20–40 min, needs ~10 GB disk)
3. Default connect string after install: `localhost:1521/XEPDB1`
4. Set a password for user `SYSTEM` or create your own user during setup

**Create your project user (run as SYSTEM):**
```sql
CREATE USER campus_user IDENTIFIED BY YourPassword123;
GRANT CONNECT, RESOURCE TO campus_user;
GRANT UNLIMITED TABLESPACE TO campus_user;
-- For roles in Push 13 (optional):
GRANT CREATE ROLE TO campus_user;
```

Connect as `campus_user` for all project scripts.

### Step 2: Install SQL Developer (free)

Download: [https://www.oracle.com/database/sqldeveloper/](https://www.oracle.com/database/sqldeveloper/)

1. Open SQL Developer
2. Click **+** (New Connection)
3. Fill in:
   - **Name:** Campus Project
   - **Username:** `campus_user` (or your uni account)
   - **Password:** your password
   - **Hostname:** `localhost` (or uni server IP)
   - **Port:** `1521`
   - **Service name:** `XEPDB1` (or what your uni gives)
4. Click **Test** → **Connect**

### Step 3: Run all SQL (one shot)

1. In SQL Developer menu: **Tools → Preferences → Database → Worksheet**  
   Note your default script path
2. Open file: `sql/run_all.sql` from this project
3. **Important:** In the worksheet, the `@` paths assume you run from the `sql/` folder.  
   Either:
   - Open `run_all.sql` and run it while SQL Developer's working directory is `sql/`, **OR**
   - Run each file manually in order (see list below)
4. Click **Run Script** (F5) — not Run Statement (Ctrl+Enter)

**Manual order if `@` paths fail:**
```
sql/ddl/01_create_tables.sql
sql/ddl/02_create_supporting_tables.sql
sql/ddl/03_sequences.sql
sql/dml/01_seed_data.sql
sql/plsql/01_triggers.sql
sql/plsql/02_triggers_part2.sql
sql/plsql/03_procedures.sql
sql/plsql/04_functions.sql
sql/plsql/05_views.sql
sql/plsql/06_transactions.sql
```

### Step 4: Run demo for teacher

Open `sql/DEMO_QUERIES.sql` → **Run Script (F5)**

Enable output panel: **View → Dbms Output** → click green **+** → select your connection.

**What to show teacher live:**
1. Table counts (38 complaints, 14 users)
2. Insert complaint → SLA auto-set (trigger)
3. `EXEC assign_worker(...)` — procedure
4. `SELECT * FROM overdue_complaints_view` — view
5. `SELECT get_worker_performance(1) FROM dual` — function
6. `SELECT * FROM status_log` — audit trigger
7. ER diagram PNG from dbdiagram.io

---

## Option B — University Lab Computer

Often lab PCs already have Oracle + SQL Developer:

1. Log in with your **university Oracle account**
2. Open SQL Developer (usually installed)
3. Copy project folder to USB or pull from GitHub
4. Run `run_all.sql` then `DEMO_QUERIES.sql`
5. Show ER diagram + SQL files on screen

**Ask teacher/lab assistant tonight:** *"What is the Oracle connection string and username for the lab?"*

---

## Option C — Web App Demo (Optional, Needs Extra Setup)

The website (`frontend/`) connects to Oracle via Node.js. **Not required** for a DB lab if PL/SQL demo works.

**Problems on your PC right now:**
- npm is broken → reinstall Node.js from [https://nodejs.org](https://nodejs.org) (LTS version, include npm)
- Oracle must be running first

**After Oracle + npm work:**
```powershell
cd "C:\Users\User\Desktop\dB proj\frontend"
copy .env.example .env
# Edit .env:
#   DB_USER=campus_user
#   DB_PASSWORD=YourPassword123
#   DB_CONNECT_STRING=localhost:1521/XEPDB1

npm install
npm start
# Open http://localhost:3000
# Login: hassan.r@stu.edu (student)
#        omar.s@campus.edu (supervisor)
#        rashid.i@campus.edu (worker)
#        admin@campus.edu (admin)
```

---

## ER Diagram (5 minutes — do tonight)

1. Open [https://dbdiagram.io/d](https://dbdiagram.io/d)
2. Copy all content from `docs/erd.dbml` → paste
3. Export **PNG**
4. Save as `assets/erd.png`
5. Insert in your lab report / show on screen

---

## What to Tell Teacher (30-second pitch)

> "We built a Campus Maintenance Complaint Management System in **Oracle PL/SQL**. The schema has 9 normalized tables. **Seven triggers** auto-set SLA deadlines, log status changes, manage worker availability, detect chronic issues, and score worker performance. **Six stored procedures** handle worker assignment, monthly reports, SLA escalation, and safe transactions with SAVEPOINT. **Four functions** and **five views** support analytics. I'll run the demo script to show triggers and procedures working live."

---

## Tomorrow Checklist

### Minimum (DB lab — enough to pass)
- [ ] Oracle connected in SQL Developer
- [ ] Run all SQL scripts successfully
- [ ] Run `DEMO_QUERIES.sql` with output visible
- [ ] ER diagram PNG ready
- [ ] Explain one trigger + one procedure verbally

### Ideal
- [ ] Screenshots of views and demo output in lab report
- [ ] GitHub repo link ready
- [ ] Web app running (if time allows)

### If Oracle fails in class
- Show SQL source files + ER diagram
- Say: *"Scripts tested on [home/uni machine]; connection issue here"*
- Show `DEMO_QUERIES.sql` and walk through what each block does

---

## Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `ORA-01017 invalid username/password` | Check connection details with lab admin |
| `ORA-00942 table or view does not exist` | Run DDL scripts first (`01`, `02`, `03`) |
| `ORA-02291 integrity constraint` | Run seed data after tables exist |
| `@file not found` | Use full path or run files one by one |
| Trigger compilation error | Run scripts in order; Push 6 before 7 |
| `CREATE ROLE insufficient privileges` | Connect as user with DBA or skip role section in `06_transactions.sql` |
| npm not found | Reinstall Node.js LTS from nodejs.org |

---

## Files Quick Reference

| File | Purpose |
|------|---------|
| `sql/run_all.sql` | Run everything in order |
| `sql/DEMO_QUERIES.sql` | Live demo for teacher |
| `docs/erd.dbml` | ER diagram source |
| `docs/schema_design.md` | Schema + 3NF explanation |
| `docs/data_dictionary.md` | All columns documented |

---

## Do You Need to Give Me Anything?

For **SQL Developer demo only:** No — just Oracle username/password you create locally or get from university.

For **web app:** Oracle credentials in `frontend/.env` (never commit to git).

If you get stuck tonight, tell me:
1. Do you have university Oracle access? (yes/no)
2. Can you install Oracle XE tonight? (yes/no)
3. Any error message when running scripts

I can help fix specific errors before tomorrow.

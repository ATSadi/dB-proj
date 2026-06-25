# Data Dictionary

**Project:** Campus Maintenance & Complaint Management System  
**Last updated:** Push 2

Column-level definitions for all tables. Types reflect Oracle DDL conventions used in later pushes.

---

## USERS

Stores every person who interacts with the system.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `user_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_user_id` |
| `name` | `VARCHAR2(100)` | NOT NULL | Full name of the user |
| `roll_no` | `VARCHAR2(20)` | UNIQUE | Student/worker roll or ID number; NULL allowed for admin |
| `email` | `VARCHAR2(100)` | UNIQUE, NOT NULL | Login/contact email |
| `role` | `VARCHAR2(20)` | NOT NULL, CHECK | System role: `student`, `worker`, `supervisor`, `admin` |

---

## LOCATIONS

Physical campus places where complaints occur.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `location_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_location_id` |
| `building` | `VARCHAR2(50)` | NOT NULL | Building name or code (e.g., `Block A`, `Science Wing`) |
| `floor` | `VARCHAR2(10)` | NOT NULL | Floor label (e.g., `G`, `1`, `2`) |
| `room_no` | `VARCHAR2(20)` | NOT NULL | Room or area number (e.g., `101`, `Lab-3`) |
| `location_type` | `VARCHAR2(30)` | NOT NULL, CHECK | Type: `classroom`, `lab`, `hostel`, `office`, `washroom`, `corridor` |

**Unique business key:** (`building`, `floor`, `room_no`) — same room cannot be registered twice.

---

## COMPLAINTS

Central entity for maintenance requests.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `complaint_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_complaint_id` |
| `student_id` | `NUMBER` | FK → `USERS`, NOT NULL | Student who filed the complaint |
| `location_id` | `NUMBER` | FK → `LOCATIONS`, NOT NULL | Where the issue occurred |
| `category` | `VARCHAR2(50)` | NOT NULL, CHECK | Issue type: `electrical`, `plumbing`, `furniture`, `it`, `cleaning`, `other` |
| `priority` | `VARCHAR2(10)` | NOT NULL, CHECK | Urgency: `urgent` (4h), `medium` (24h), `low` (72h) |
| `description` | `VARCHAR2(500)` | NOT NULL | Free-text problem description |
| `status` | `VARCHAR2(20)` | NOT NULL, CHECK, DEFAULT `'submitted'` | Lifecycle: `submitted`, `assigned`, `in_progress`, `resolved`, `closed` |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When the complaint was filed |
| `sla_deadline` | `TIMESTAMP` | NULL allowed | Auto-calculated deadline; set by trigger on INSERT |
| `resolved_at` | `TIMESTAMP` | NULL allowed | When complaint reached `resolved` or `closed`; set on status update |

---

## WORKERS

Extended profile for users with role `worker`.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `worker_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_worker_id` |
| `user_id` | `NUMBER` | FK → `USERS`, UNIQUE, NOT NULL | Links worker profile to user account (1:1) |
| `specialization` | `VARCHAR2(50)` | NOT NULL | Trade/category handled: matches complaint categories |
| `performance_score` | `NUMBER(5,2)` | DEFAULT `0` | Cached score 0–100; recalculated via PL/SQL after feedback |
| `is_available` | `CHAR(1)` | DEFAULT `'Y'`, CHECK | `Y` = available for new assignments, `N` = busy |

---

## ASSIGNMENTS

Records which worker is handling a complaint and associated costs.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `assignment_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_assignment_id` |
| `complaint_id` | `NUMBER` | FK → `COMPLAINTS`, NOT NULL | Complaint being worked on |
| `worker_id` | `NUMBER` | FK → `WORKERS`, NOT NULL | Assigned worker |
| `assigned_by` | `NUMBER` | FK → `USERS`, NOT NULL | Supervisor who made the assignment |
| `assigned_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When assignment was created |
| `started_at` | `TIMESTAMP` | NULL allowed | When worker began work (`in_progress`) |
| `completed_at` | `TIMESTAMP` | NULL allowed | When work was finished |
| `repair_cost` | `NUMBER(10,2)` | DEFAULT `0` | Estimated/actual repair cost for budget tracking |

---

## STATUS_LOG

Immutable audit trail for complaint status changes.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `log_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_log_id` |
| `complaint_id` | `NUMBER` | FK → `COMPLAINTS`, NOT NULL | Complaint whose status changed |
| `old_status` | `VARCHAR2(20)` | NULL allowed | Previous status; NULL on first log entry |
| `new_status` | `VARCHAR2(20)` | NOT NULL | Status after the change |
| `changed_by` | `NUMBER` | FK → `USERS` | User who triggered the change; NULL for system triggers |
| `changed_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When the change occurred |
| `note` | `VARCHAR2(200)` | NULL allowed | Optional reason (e.g., `SLA escalation`, `Auto-assigned`) |

---

## FEEDBACK

Student satisfaction after complaint resolution.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `feedback_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_feedback_id` |
| `complaint_id` | `NUMBER` | FK → `COMPLAINTS`, UNIQUE, NOT NULL | One feedback record per complaint |
| `student_id` | `NUMBER` | FK → `USERS`, NOT NULL | Student submitting feedback (must match complaint owner) |
| `rating` | `NUMBER(1)` | NOT NULL, CHECK (1–5) | Star rating from 1 (poor) to 5 (excellent) |
| `feedback_comment` | `VARCHAR2(300)` | NULL allowed | Optional written feedback |
| `submitted_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When feedback was submitted |

---

## CHRONIC_FLAGS

Alerts for recurring problems at the same location.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `flag_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_flag_id` |
| `location_id` | `NUMBER` | FK → `LOCATIONS`, NOT NULL | Location with recurring issues |
| `category` | `VARCHAR2(50)` | NOT NULL | Complaint category that keeps repeating |
| `complaint_count` | `NUMBER` | NOT NULL | Number of complaints that triggered the flag (≥ 3) |
| `flagged_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When the chronic issue was detected |

**Unique business key:** (`location_id`, `category`) — one active flag per location/category pair.

---

## MAINTENANCE_REPORTS

Monthly snapshot reports generated by stored procedure.

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| `report_id` | `NUMBER` | PK, NOT NULL | Surrogate primary key; populated via `seq_report_id` |
| `month` | `NUMBER(2)` | NOT NULL, CHECK (1–12) | Report month |
| `year` | `NUMBER(4)` | NOT NULL | Report year |
| `generated_at` | `TIMESTAMP` | NOT NULL, DEFAULT `SYSTIMESTAMP` | When the report was generated |
| `total_complaints` | `NUMBER` | NOT NULL | Complaints filed in that month |
| `resolved_count` | `NUMBER` | NOT NULL | Complaints resolved in that month |
| `avg_resolution_hrs` | `NUMBER(8,2)` | NULL allowed | Average hours from `created_at` to `resolved_at` |
| `total_cost` | `NUMBER(12,2)` | DEFAULT `0` | Sum of `repair_cost` for assignments completed that month |

**Unique business key:** (`month`, `year`) — one report per calendar month.

---

## Enumerated Values Reference

### `USERS.role`
| Value | Meaning |
|-------|---------|
| `student` | Submits complaints and feedback |
| `worker` | Resolves assigned complaints |
| `supervisor` | Assigns workers, monitors SLA |
| `admin` | Full system access and reporting |

### `COMPLAINTS.priority` → SLA
| Priority | SLA Deadline |
|----------|--------------|
| `urgent` | +4 hours from `created_at` |
| `medium` | +24 hours from `created_at` |
| `low` | +72 hours from `created_at` |

### `COMPLAINTS.status` (lifecycle)
| Status | Meaning |
|--------|---------|
| `submitted` | Newly filed, awaiting assignment |
| `assigned` | Worker assigned, not yet started |
| `in_progress` | Worker actively working |
| `resolved` | Work completed, awaiting feedback/close |
| `closed` | Fully closed |

### `LOCATIONS.location_type`
`classroom`, `lab`, `hostel`, `office`, `washroom`, `corridor`

### `COMPLAINTS.category` / `WORKERS.specialization`
`electrical`, `plumbing`, `furniture`, `it`, `cleaning`, `other`

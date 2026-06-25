-- ============================================================================
-- Push 4: DDL — Supporting Tables
-- Campus Maintenance & Complaint Management System
-- Tables: WORKERS, ASSIGNMENTS, STATUS_LOG, FEEDBACK,
--         CHRONIC_FLAGS, MAINTENANCE_REPORTS
-- Prerequisite: @sql/ddl/01_create_tables.sql
-- Run as: @sql/ddl/02_create_supporting_tables.sql
-- ============================================================================

-- Drop in reverse dependency order (safe re-run)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE maintenance_reports CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE chronic_flags CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE feedback CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE status_log CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE assignments CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE workers CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- WORKERS
-- ----------------------------------------------------------------------------
CREATE TABLE workers (
    worker_id          NUMBER(10)      NOT NULL,
    user_id            NUMBER          NOT NULL,
    specialization     VARCHAR2(50)    NOT NULL,
    performance_score  NUMBER(5,2)     DEFAULT 0 NOT NULL,
    is_available       CHAR(1)         DEFAULT 'Y' NOT NULL,

    CONSTRAINT pk_workers PRIMARY KEY (worker_id),
    CONSTRAINT uq_workers_user_id UNIQUE (user_id),

    CONSTRAINT fk_workers_user FOREIGN KEY (user_id)
        REFERENCES users (user_id),

    CONSTRAINT chk_workers_specialization CHECK (
        specialization IN ('electrical', 'plumbing', 'furniture', 'it', 'cleaning', 'other')
    ),

    CONSTRAINT chk_workers_available CHECK (
        is_available IN ('Y', 'N')
    ),

    CONSTRAINT chk_workers_performance CHECK (
        performance_score BETWEEN 0 AND 100
    )
);

COMMENT ON TABLE workers IS 'Worker profiles linked 1:1 to user accounts';
COMMENT ON COLUMN workers.performance_score IS 'Cached score 0-100; refreshed by trigger after feedback';

-- ----------------------------------------------------------------------------
-- ASSIGNMENTS
-- ----------------------------------------------------------------------------
CREATE TABLE assignments (
    assignment_id  NUMBER(10)      NOT NULL,
    complaint_id   NUMBER          NOT NULL,
    worker_id      NUMBER(10)      NOT NULL,
    assigned_by    NUMBER          NOT NULL,
    assigned_at    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    started_at     TIMESTAMP,
    completed_at   TIMESTAMP,
    repair_cost    NUMBER(10,2)    DEFAULT 0 NOT NULL,

    CONSTRAINT pk_assignments PRIMARY KEY (assignment_id),

    CONSTRAINT fk_assignments_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id),

    CONSTRAINT fk_assignments_worker FOREIGN KEY (worker_id)
        REFERENCES workers (worker_id),

    CONSTRAINT fk_assignments_supervisor FOREIGN KEY (assigned_by)
        REFERENCES users (user_id),

    CONSTRAINT chk_assignments_repair_cost CHECK (
        repair_cost >= 0
    )
);

COMMENT ON TABLE assignments IS 'Worker-to-complaint assignments with timing and repair cost';
COMMENT ON COLUMN assignments.repair_cost IS 'Estimated/actual repair cost for budget tracking';

CREATE INDEX idx_assignments_worker
    ON assignments (worker_id);

CREATE INDEX idx_assignments_complaint
    ON assignments (complaint_id);

-- ----------------------------------------------------------------------------
-- STATUS_LOG
-- ----------------------------------------------------------------------------
CREATE TABLE status_log (
    log_id        NUMBER(10)      NOT NULL,
    complaint_id  NUMBER          NOT NULL,
    old_status    VARCHAR2(20),
    new_status    VARCHAR2(20)    NOT NULL,
    changed_by    NUMBER,
    changed_at    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    note          VARCHAR2(200),

    CONSTRAINT pk_status_log PRIMARY KEY (log_id),

    CONSTRAINT fk_status_log_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id),

    CONSTRAINT fk_status_log_user FOREIGN KEY (changed_by)
        REFERENCES users (user_id),

    CONSTRAINT chk_status_log_new_status CHECK (
        new_status IN ('submitted', 'assigned', 'in_progress', 'resolved', 'closed')
    ),

    CONSTRAINT chk_status_log_old_status CHECK (
        old_status IS NULL
        OR old_status IN ('submitted', 'assigned', 'in_progress', 'resolved', 'closed')
    )
);

COMMENT ON TABLE status_log IS 'Audit trail for every complaint status change';

CREATE INDEX idx_status_log_complaint
    ON status_log (complaint_id);

-- ----------------------------------------------------------------------------
-- FEEDBACK
-- ----------------------------------------------------------------------------
CREATE TABLE feedback (
    feedback_id   NUMBER(10)      NOT NULL,
    complaint_id  NUMBER          NOT NULL,
    student_id    NUMBER          NOT NULL,
    rating            NUMBER(1)       NOT NULL,
    feedback_comment  VARCHAR2(300),
    submitted_at      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT pk_feedback PRIMARY KEY (feedback_id),
    CONSTRAINT uq_feedback_complaint UNIQUE (complaint_id),

    CONSTRAINT fk_feedback_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id),

    CONSTRAINT fk_feedback_student FOREIGN KEY (student_id)
        REFERENCES users (user_id),

    CONSTRAINT chk_feedback_rating CHECK (
        rating BETWEEN 1 AND 5
    )
);

COMMENT ON TABLE feedback IS 'Student rating and comment after complaint resolution';

-- ----------------------------------------------------------------------------
-- CHRONIC_FLAGS
-- ----------------------------------------------------------------------------
CREATE TABLE chronic_flags (
    flag_id         NUMBER(10)      NOT NULL,
    location_id     NUMBER          NOT NULL,
    category        VARCHAR2(50)    NOT NULL,
    complaint_count NUMBER          NOT NULL,
    flagged_at      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT pk_chronic_flags PRIMARY KEY (flag_id),
    CONSTRAINT uq_chronic_flags_location_category UNIQUE (location_id, category),

    CONSTRAINT fk_chronic_flags_location FOREIGN KEY (location_id)
        REFERENCES locations (location_id),

    CONSTRAINT chk_chronic_flags_category CHECK (
        category IN ('electrical', 'plumbing', 'furniture', 'it', 'cleaning', 'other')
    ),

    CONSTRAINT chk_chronic_flags_count CHECK (
        complaint_count >= 3
    )
);

COMMENT ON TABLE chronic_flags IS 'Recurring issue alerts when 3+ complaints share location and category';

-- ----------------------------------------------------------------------------
-- MAINTENANCE_REPORTS
-- ----------------------------------------------------------------------------
CREATE TABLE maintenance_reports (
    report_id           NUMBER(10)      NOT NULL,
    month               NUMBER(2)       NOT NULL,
    year                NUMBER(4)       NOT NULL,
    generated_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    total_complaints    NUMBER          NOT NULL,
    resolved_count      NUMBER          NOT NULL,
    avg_resolution_hrs  NUMBER(8,2),
    total_cost          NUMBER(12,2)    DEFAULT 0 NOT NULL,

    CONSTRAINT pk_maintenance_reports PRIMARY KEY (report_id),
    CONSTRAINT uq_maintenance_reports_month_year UNIQUE (month, year),

    CONSTRAINT chk_maintenance_reports_month CHECK (
        month BETWEEN 1 AND 12
    ),

    CONSTRAINT chk_maintenance_reports_year CHECK (
        year BETWEEN 2000 AND 2100
    ),

    CONSTRAINT chk_maintenance_reports_counts CHECK (
        total_complaints >= 0 AND resolved_count >= 0 AND resolved_count <= total_complaints
    ),

    CONSTRAINT chk_maintenance_reports_cost CHECK (
        total_cost >= 0
    )
);

COMMENT ON TABLE maintenance_reports IS 'Monthly aggregated maintenance statistics';

-- ----------------------------------------------------------------------------
PROMPT Supporting tables created: WORKERS, ASSIGNMENTS, STATUS_LOG, FEEDBACK, CHRONIC_FLAGS, MAINTENANCE_REPORTS

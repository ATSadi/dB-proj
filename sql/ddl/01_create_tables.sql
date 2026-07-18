-- ============================================================================
-- Push 3: DDL — Core Tables
-- Campus Maintenance & Complaint Management System
-- Tables: USERS, LOCATIONS, COMPLAINTS
-- Run as: @sql/ddl/01_create_tables.sql
-- ============================================================================

-- Drop in reverse dependency order (safe re-run)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE complaints CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE locations CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ----------------------------------------------------------------------------
-- USERS
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    user_id   NUMBER          NOT NULL,
    name      VARCHAR2(100)   NOT NULL,
    roll_no   VARCHAR2(20),
    email     VARCHAR2(100)   NOT NULL,
    role      VARCHAR2(20)    NOT NULL,
    password_hash          VARCHAR2(255),
    reset_token_hash       VARCHAR2(64),
    reset_token_expires    TIMESTAMP,
    password_changed_at    TIMESTAMP DEFAULT SYSTIMESTAMP,

    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_roll_no UNIQUE (roll_no),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_role CHECK (
        role IN ('student', 'worker', 'supervisor', 'admin')
    )
);

COMMENT ON TABLE users IS 'All system actors: students, workers, supervisors, and admins';
COMMENT ON COLUMN users.user_id  IS 'Surrogate PK; populated via seq_user_id (Push 4)';
COMMENT ON COLUMN users.roll_no  IS 'Student/worker roll number; NULL allowed for admin';
COMMENT ON COLUMN users.role     IS 'Access role: student | worker | supervisor | admin';
COMMENT ON COLUMN users.password_hash IS 'Scrypt password hash; plaintext passwords are never stored';

-- ----------------------------------------------------------------------------
-- LOCATIONS
-- ----------------------------------------------------------------------------
CREATE TABLE locations (
    location_id   NUMBER          NOT NULL,
    building      VARCHAR2(50)    NOT NULL,
    floor         VARCHAR2(10)    NOT NULL,
    room_no       VARCHAR2(20)    NOT NULL,
    location_type VARCHAR2(30)    NOT NULL,

    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_locations_building_floor_room UNIQUE (building, floor, room_no),
    CONSTRAINT chk_locations_type CHECK (
        location_type IN ('classroom', 'lab', 'hostel', 'office', 'washroom', 'corridor')
    )
);

COMMENT ON TABLE locations IS 'Campus buildings, floors, and rooms where complaints occur';
COMMENT ON COLUMN locations.location_type IS 'classroom | lab | hostel | office | washroom | corridor';

-- ----------------------------------------------------------------------------
-- COMPLAINTS
-- ----------------------------------------------------------------------------
CREATE TABLE complaints (
    complaint_id  NUMBER          NOT NULL,
    student_id    NUMBER          NOT NULL,
    location_id   NUMBER          NOT NULL,
    category      VARCHAR2(50)    NOT NULL,
    priority      VARCHAR2(10)    NOT NULL,
    description   VARCHAR2(500)   NOT NULL,
    status        VARCHAR2(20)    DEFAULT 'submitted' NOT NULL,
    created_at    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    sla_deadline  TIMESTAMP,
    resolved_at   TIMESTAMP,

    CONSTRAINT pk_complaints PRIMARY KEY (complaint_id),

    CONSTRAINT fk_complaints_student FOREIGN KEY (student_id)
        REFERENCES users (user_id),

    CONSTRAINT fk_complaints_location FOREIGN KEY (location_id)
        REFERENCES locations (location_id),

    CONSTRAINT chk_complaints_category CHECK (
        category IN ('electrical', 'plumbing', 'furniture', 'it', 'cleaning', 'other')
    ),

    CONSTRAINT chk_complaints_priority CHECK (
        priority IN ('urgent', 'medium', 'low')
    ),

    CONSTRAINT chk_complaints_status CHECK (
        status IN ('submitted', 'assigned', 'in_progress', 'resolved', 'closed')
    )
);

COMMENT ON TABLE complaints IS 'Maintenance complaints filed by students';
COMMENT ON COLUMN complaints.sla_deadline IS 'Auto-set by trigger: urgent=4h, medium=24h, low=72h';
COMMENT ON COLUMN complaints.resolved_at   IS 'Set when status becomes resolved or closed';

-- ----------------------------------------------------------------------------
-- Indexes on COMPLAINTS (support SLA and dashboard queries)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_complaints_status
    ON complaints (status);

CREATE INDEX idx_complaints_sla
    ON complaints (sla_deadline);

CREATE INDEX idx_complaints_location_cat
    ON complaints (location_id, category);

CREATE INDEX idx_complaints_student
    ON complaints (student_id);

-- ----------------------------------------------------------------------------
PROMPT Core tables created: USERS, LOCATIONS, COMPLAINTS

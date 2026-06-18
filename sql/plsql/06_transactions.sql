-- ============================================================================
-- Push 13: Transaction Management & Exception Handling
-- Campus Maintenance & Complaint Management System
--   - Transactional procedures with COMMIT / ROLLBACK / SAVEPOINT
--   - Exception blocks (NO_DATA_FOUND, TOO_MANY_ROWS, custom errors)
--   - Role-based GRANT / REVOKE (student, worker, supervisor, admin)
-- Prerequisite: Pushes 3–10
-- Run as: @sql/plsql/06_transactions.sql
-- Note: CREATE ROLE may require DBA privileges; run as schema owner or SYS.
-- ============================================================================

SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------------
-- Custom exceptions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE complaint_exceptions AS
    e_invalid_rating    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_rating,    -20100);
    e_invalid_cost      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_cost,      -20101);
    e_not_owner         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_owner,         -20102);
    e_invalid_status    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_status,    -20103);
END complaint_exceptions;
/

-- ---------------------------------------------------------------------------
-- Procedure: submit_complaint_safe
-- Inserts complaint in a single transaction with validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE submit_complaint_safe (
    p_student_id   IN NUMBER,
    p_location_id  IN NUMBER,
    p_category     IN VARCHAR2,
    p_priority     IN VARCHAR2,
    p_description  IN VARCHAR2,
    p_complaint_id OUT NUMBER
) IS
    v_role users.role%TYPE;
BEGIN
    SELECT role INTO v_role FROM users WHERE user_id = p_student_id;

    IF v_role <> 'student' THEN
        RAISE_APPLICATION_ERROR(-20104, 'Only students can submit complaints.');
    END IF;

    INSERT INTO complaints (
        complaint_id, student_id, location_id, category, priority, description
    ) VALUES (
        seq_complaint_id.NEXTVAL, p_student_id, p_location_id,
        p_category, p_priority, p_description
    ) RETURNING complaint_id INTO p_complaint_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20105, 'Student or location not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END submit_complaint_safe;
/

-- ---------------------------------------------------------------------------
-- Procedure: resolve_with_repair_cost
-- Demonstrates SAVEPOINT — cost update rolls back independently on error
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE resolve_with_repair_cost (
    p_complaint_id  IN NUMBER,
    p_worker_id     IN NUMBER,
    p_repair_cost   IN NUMBER
) IS
    v_status   complaints.status%TYPE;
    v_assign   NUMBER;
BEGIN
    IF p_repair_cost < 0 THEN
        RAISE complaint_exceptions.e_invalid_cost;
    END IF;

    SELECT status INTO v_status
    FROM complaints WHERE complaint_id = p_complaint_id;

    IF v_status <> 'in_progress' THEN
        RAISE complaint_exceptions.e_invalid_status;
    END IF;

    SELECT assignment_id INTO v_assign
    FROM assignments
    WHERE complaint_id = p_complaint_id
      AND worker_id = p_worker_id
      AND completed_at IS NULL;

    SAVEPOINT before_cost;

    BEGIN
        UPDATE assignments
        SET repair_cost = p_repair_cost
        WHERE assignment_id = v_assign;

        IF p_repair_cost > 100000 THEN
            RAISE complaint_exceptions.e_invalid_cost;
        END IF;

    EXCEPTION
        WHEN complaint_exceptions.e_invalid_cost THEN
            ROLLBACK TO SAVEPOINT before_cost;
            RAISE_APPLICATION_ERROR(-20101, 'Repair cost exceeds maximum allowed (100000).');
    END;

    UPDATE assignments
    SET completed_at = SYSTIMESTAMP
    WHERE assignment_id = v_assign;

    UPDATE complaints
    SET status = 'resolved'
    WHERE complaint_id = p_complaint_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20106, 'Complaint or assignment not found for this worker.');
    WHEN TOO_MANY_ROWS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20107, 'Multiple open assignments found for this complaint.');
    WHEN complaint_exceptions.e_invalid_status THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20103, 'Complaint must be in_progress to resolve.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END resolve_with_repair_cost;
/

-- ---------------------------------------------------------------------------
-- Procedure: submit_feedback_safe
-- Validates rating and ownership; full transaction with exception handling
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE submit_feedback_safe (
    p_complaint_id IN NUMBER,
    p_student_id   IN NUMBER,
    p_rating       IN NUMBER,
    p_comment      IN VARCHAR2 DEFAULT NULL
) IS
    v_owner   complaints.student_id%TYPE;
    v_status  complaints.status%TYPE;
    v_exists  NUMBER;
BEGIN
    IF p_rating < 1 OR p_rating > 5 THEN
        RAISE complaint_exceptions.e_invalid_rating;
    END IF;

    SELECT student_id, status
    INTO v_owner, v_status
    FROM complaints
    WHERE complaint_id = p_complaint_id;

    IF v_owner <> p_student_id THEN
        RAISE complaint_exceptions.e_not_owner;
    END IF;

    IF v_status <> 'resolved' THEN
        RAISE complaint_exceptions.e_invalid_status;
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM feedback WHERE complaint_id = p_complaint_id;

    IF v_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20108, 'Feedback already submitted for this complaint.');
    END IF;

    INSERT INTO feedback (
        feedback_id, complaint_id, student_id, rating, comment
    ) VALUES (
        seq_feedback_id.NEXTVAL, p_complaint_id, p_student_id, p_rating, p_comment
    );

    UPDATE complaints SET status = 'closed' WHERE complaint_id = p_complaint_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20109, 'Complaint not found.');
    WHEN complaint_exceptions.e_invalid_rating THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20100, 'Rating must be between 1 and 5.');
    WHEN complaint_exceptions.e_not_owner THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20102, 'Only the complaint owner can submit feedback.');
    WHEN complaint_exceptions.e_invalid_status THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20103, 'Feedback allowed only for resolved complaints.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END submit_feedback_safe;
/

-- ---------------------------------------------------------------------------
-- Roles (skip errors if roles already exist)
-- ---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE student_role';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE worker_role';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE supervisor_role'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE admin_role';      EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ---------------------------------------------------------------------------
-- REVOKE broad access from PUBLIC (safe default)
-- ---------------------------------------------------------------------------
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN (
            'USERS','LOCATIONS','COMPLAINTS','WORKERS','ASSIGNMENTS',
            'STATUS_LOG','FEEDBACK','CHRONIC_FLAGS','MAINTENANCE_REPORTS'
        )
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'REVOKE ALL ON ' || t.table_name || ' FROM PUBLIC';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- ---------------------------------------------------------------------------
-- GRANT: student_role
-- ---------------------------------------------------------------------------
GRANT SELECT ON users TO student_role;
GRANT SELECT ON locations TO student_role;
GRANT SELECT, INSERT ON complaints TO student_role;
GRANT SELECT, INSERT ON feedback TO student_role;
GRANT SELECT ON seq_complaint_id TO student_role;
GRANT SELECT ON seq_feedback_id TO student_role;
GRANT EXECUTE ON submit_complaint_safe TO student_role;
GRANT EXECUTE ON submit_feedback_safe TO student_role;
GRANT EXECUTE ON get_complaint_summary TO student_role;

-- ---------------------------------------------------------------------------
-- GRANT: worker_role
-- ---------------------------------------------------------------------------
GRANT SELECT ON complaints TO worker_role;
GRANT SELECT ON assignments TO worker_role;
GRANT UPDATE (started_at, completed_at) ON assignments TO worker_role;
GRANT SELECT ON workers TO worker_role;
GRANT SELECT ON locations TO worker_role;
GRANT SELECT ON active_complaints_view TO worker_role;
GRANT EXECUTE ON get_resolution_time TO worker_role;
GRANT EXECUTE ON resolve_with_repair_cost TO worker_role;

-- ---------------------------------------------------------------------------
-- GRANT: supervisor_role
-- ---------------------------------------------------------------------------
GRANT SELECT ON users TO supervisor_role;
GRANT SELECT ON locations TO supervisor_role;
GRANT SELECT ON complaints TO supervisor_role;
GRANT SELECT ON workers TO supervisor_role;
GRANT SELECT, INSERT ON assignments TO supervisor_role;
GRANT SELECT ON status_log TO supervisor_role;
GRANT SELECT ON seq_assignment_id TO supervisor_role;
GRANT SELECT ON active_complaints_view TO supervisor_role;
GRANT SELECT ON overdue_complaints_view TO supervisor_role;
GRANT SELECT ON worker_performance_view TO supervisor_role;
GRANT EXECUTE ON assign_worker TO supervisor_role;
GRANT EXECUTE ON escalate_overdue_complaints TO supervisor_role;

-- ---------------------------------------------------------------------------
-- GRANT: admin_role (full access)
-- ---------------------------------------------------------------------------
GRANT SELECT ON users TO admin_role;
GRANT SELECT ON locations TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON complaints TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON workers TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON assignments TO admin_role;
GRANT SELECT ON status_log TO admin_role;
GRANT SELECT ON feedback TO admin_role;
GRANT SELECT ON chronic_flags TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON maintenance_reports TO admin_role;
GRANT SELECT ON active_complaints_view TO admin_role;
GRANT SELECT ON worker_performance_view TO admin_role;
GRANT SELECT ON overdue_complaints_view TO admin_role;
GRANT SELECT ON monthly_summary_view TO admin_role;
GRANT SELECT ON chronic_issues_view TO admin_role;
GRANT SELECT ON seq_complaint_id TO admin_role;
GRANT SELECT ON seq_assignment_id TO admin_role;
GRANT SELECT ON seq_feedback_id TO admin_role;
GRANT SELECT ON seq_report_id TO admin_role;
GRANT EXECUTE ON assign_worker TO admin_role;
GRANT EXECUTE ON generate_monthly_report TO admin_role;
GRANT EXECUTE ON escalate_overdue_complaints TO admin_role;
GRANT EXECUTE ON submit_complaint_safe TO admin_role;
GRANT EXECUTE ON submit_feedback_safe TO admin_role;
GRANT EXECUTE ON resolve_with_repair_cost TO admin_role;
GRANT EXECUTE ON get_worker_performance TO admin_role;
GRANT EXECUTE ON get_complaint_summary TO admin_role;
GRANT EXECUTE ON get_resolution_time TO admin_role;
GRANT EXECUTE ON calculate_sla_deadline TO admin_role;

-- ---------------------------------------------------------------------------
-- Example: assign role to a database user (uncomment and edit username)
-- ---------------------------------------------------------------------------
-- GRANT student_role TO campus_student;
-- GRANT worker_role TO campus_worker;
-- GRANT supervisor_role TO campus_supervisor;
-- GRANT admin_role TO campus_admin;

PROMPT Push 13 complete: transactional procedures, exception package, roles and grants

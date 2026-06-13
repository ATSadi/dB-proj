-- ============================================================================
-- Push 8: Stored Procedures
-- Campus Maintenance & Complaint Management System
--   1. assign_worker        — validate specialization, assign, set status
--   2. generate_monthly_report — aggregate stats into MAINTENANCE_REPORTS
--   3. escalate_overdue_complaints — cursor-based SLA escalation
-- Prerequisite: DDL, DML, and trigger scripts (Pushes 3–7)
-- Run as: @sql/plsql/03_procedures.sql
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- Procedure 1: assign_worker
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE assign_worker (
    p_complaint_id   IN NUMBER,
    p_worker_id      IN NUMBER,
    p_supervisor_id  IN NUMBER
) IS
    v_category       complaints.category%TYPE;
    v_status         complaints.status%TYPE;
    v_specialization workers.specialization%TYPE;
    v_sup_role       users.role%TYPE;
BEGIN
    SELECT role
    INTO v_sup_role
    FROM users
    WHERE user_id = p_supervisor_id;

    IF v_sup_role NOT IN ('supervisor', 'admin') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Only supervisors or admins can assign workers.');
    END IF;

    SELECT category, status
    INTO v_category, v_status
    FROM complaints
    WHERE complaint_id = p_complaint_id;

    IF v_status NOT IN ('submitted', 'assigned') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Complaint cannot be assigned in its current status.');
    END IF;

    SELECT specialization
    INTO v_specialization
    FROM workers
    WHERE worker_id = p_worker_id;

    IF v_specialization <> v_category THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Worker specialization (' || v_specialization ||
            ') does not match complaint category (' || v_category || ').'
        );
    END IF;

    INSERT INTO assignments (
        assignment_id,
        complaint_id,
        worker_id,
        assigned_by
    ) VALUES (
        seq_assignment_id.NEXTVAL,
        p_complaint_id,
        p_worker_id,
        p_supervisor_id
    );

    UPDATE complaints
    SET status = 'assigned'
    WHERE complaint_id = p_complaint_id
      AND status = 'submitted';

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Complaint, worker, or supervisor not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END assign_worker;
/

-- ----------------------------------------------------------------------------
-- Procedure 2: generate_monthly_report
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE generate_monthly_report (
    p_month IN NUMBER,
    p_year  IN NUMBER
) IS
    v_total_complaints   NUMBER;
    v_resolved_count     NUMBER;
    v_avg_resolution_hrs NUMBER(8,2);
    v_total_cost         NUMBER(12,2);
    v_exists             NUMBER;
BEGIN
    IF p_month < 1 OR p_month > 12 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Month must be between 1 and 12.');
    END IF;

    SELECT COUNT(*)
    INTO v_total_complaints
    FROM complaints
    WHERE EXTRACT(MONTH FROM created_at) = p_month
      AND EXTRACT(YEAR  FROM created_at) = p_year;

    SELECT COUNT(*)
    INTO v_resolved_count
    FROM complaints
    WHERE resolved_at IS NOT NULL
      AND EXTRACT(MONTH FROM resolved_at) = p_month
      AND EXTRACT(YEAR  FROM resolved_at) = p_year;

    SELECT ROUND(
        AVG((CAST(resolved_at AS DATE) - CAST(created_at AS DATE)) * 24),
        2
    )
    INTO v_avg_resolution_hrs
    FROM complaints
    WHERE resolved_at IS NOT NULL
      AND EXTRACT(MONTH FROM resolved_at) = p_month
      AND EXTRACT(YEAR  FROM resolved_at) = p_year;

    SELECT NVL(SUM(repair_cost), 0)
    INTO v_total_cost
    FROM assignments
    WHERE completed_at IS NOT NULL
      AND EXTRACT(MONTH FROM completed_at) = p_month
      AND EXTRACT(YEAR  FROM completed_at) = p_year;

    v_avg_resolution_hrs := NVL(v_avg_resolution_hrs, 0);

    SELECT COUNT(*)
    INTO v_exists
    FROM maintenance_reports
    WHERE month = p_month
      AND year  = p_year;

    IF v_exists > 0 THEN
        UPDATE maintenance_reports
        SET generated_at       = SYSTIMESTAMP,
            total_complaints   = v_total_complaints,
            resolved_count     = v_resolved_count,
            avg_resolution_hrs = v_avg_resolution_hrs,
            total_cost         = v_total_cost
        WHERE month = p_month
          AND year  = p_year;
    ELSE
        INSERT INTO maintenance_reports (
            report_id,
            month,
            year,
            generated_at,
            total_complaints,
            resolved_count,
            avg_resolution_hrs,
            total_cost
        ) VALUES (
            seq_report_id.NEXTVAL,
            p_month,
            p_year,
            SYSTIMESTAMP,
            v_total_complaints,
            v_resolved_count,
            v_avg_resolution_hrs,
            v_total_cost
        );
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Report generated for ' || p_month || '/' || p_year ||
        ': total=' || v_total_complaints ||
        ', resolved=' || v_resolved_count ||
        ', avg_hrs=' || v_avg_resolution_hrs ||
        ', cost=' || v_total_cost
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END generate_monthly_report;
/

-- ----------------------------------------------------------------------------
-- Procedure 3: escalate_overdue_complaints
-- Cursor loops overdue assigned/in_progress complaints, upgrades priority,
-- recalculates SLA (via trigger), and flags supervisor in STATUS_LOG
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE escalate_overdue_complaints IS
    CURSOR c_overdue IS
        SELECT complaint_id,
               priority,
               status
        FROM complaints
        WHERE status IN ('assigned', 'in_progress')
          AND sla_deadline < SYSTIMESTAMP;

    v_new_priority  VARCHAR2(10);
    v_escalated     NUMBER := 0;
BEGIN
    FOR rec IN c_overdue LOOP
        v_new_priority := CASE rec.priority
            WHEN 'low'    THEN 'medium'
            WHEN 'medium' THEN 'urgent'
            ELSE 'urgent'
        END;

        IF v_new_priority <> rec.priority THEN
            UPDATE complaints
            SET priority = v_new_priority
            WHERE complaint_id = rec.complaint_id;

            INSERT INTO status_log (
                log_id,
                complaint_id,
                old_status,
                new_status,
                changed_by,
                changed_at,
                note
            ) VALUES (
                seq_log_id.NEXTVAL,
                rec.complaint_id,
                rec.status,
                rec.status,
                NULL,
                SYSTIMESTAMP,
                'SLA breach: priority escalated ' || rec.priority || ' -> ' ||
                v_new_priority || ' — supervisor flagged'
            );
        ELSE
            INSERT INTO status_log (
                log_id,
                complaint_id,
                old_status,
                new_status,
                changed_by,
                changed_at,
                note
            ) VALUES (
                seq_log_id.NEXTVAL,
                rec.complaint_id,
                rec.status,
                rec.status,
                NULL,
                SYSTIMESTAMP,
                'SLA breach: urgent complaint overdue — supervisor flagged'
            );
        END IF;

        v_escalated := v_escalated + 1;
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Escalated ' || v_escalated || ' overdue complaint(s).');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END escalate_overdue_complaints;
/

-- ----------------------------------------------------------------------------
PROMPT Procedures created: assign_worker, generate_monthly_report, escalate_overdue_complaints

-- ============================================================================
-- Push 9: Functions
-- Campus Maintenance & Complaint Management System
--   1. get_worker_performance(worker_id)  → score 0-100
--   2. get_resolution_time(complaint_id)  → hours
--   3. get_complaint_summary(student_id)  → stats object
--   4. calculate_sla_deadline(priority)   → TIMESTAMP
-- Prerequisite: Pushes 3–8
-- Run as: @sql/plsql/04_functions.sql
-- ============================================================================

-- Drop functions and type (safe re-run)
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION get_worker_performance';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION get_resolution_time';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION get_complaint_summary';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION calculate_sla_deadline';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TYPE complaint_summary_t FORCE';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- Object type for student complaint statistics
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TYPE complaint_summary_t AS OBJECT (
    total_complaints    NUMBER,
    open_complaints     NUMBER,
    resolved_complaints NUMBER,
    avg_feedback_rating NUMBER(5,2)
);
/

-- ----------------------------------------------------------------------------
-- Function 4: calculate_sla_deadline (used by SLA trigger logic)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_sla_deadline (
    p_priority   IN VARCHAR2,
    p_created_at IN TIMESTAMP DEFAULT SYSTIMESTAMP
) RETURN TIMESTAMP
IS
BEGIN
    RETURN CASE p_priority
        WHEN 'urgent' THEN p_created_at + NUMTODSINTERVAL(4,  'HOUR')
        WHEN 'medium' THEN p_created_at + NUMTODSINTERVAL(24, 'HOUR')
        WHEN 'low'    THEN p_created_at + NUMTODSINTERVAL(72, 'HOUR')
        ELSE NULL
    END;
END calculate_sla_deadline;
/

-- ----------------------------------------------------------------------------
-- Function 1: get_worker_performance
-- Same formula as trg_feedback_performance (Push 7)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_worker_performance (
    p_worker_id IN NUMBER
) RETURN NUMBER
IS
    v_avg_rating    NUMBER;
    v_avg_hours     NUMBER;
    v_rating_score  NUMBER;
    v_time_score    NUMBER;
    v_final_score   NUMBER;
BEGIN
    SELECT AVG(f.rating)
    INTO v_avg_rating
    FROM assignments a
    JOIN feedback f ON f.complaint_id = a.complaint_id
    WHERE a.worker_id = p_worker_id
      AND a.completed_at IS NOT NULL;

    SELECT AVG(
        (CAST(a.completed_at AS DATE) - CAST(c.created_at AS DATE)) * 24
    )
    INTO v_avg_hours
    FROM assignments a
    JOIN complaints c ON c.complaint_id = a.complaint_id
    WHERE a.worker_id = p_worker_id
      AND a.completed_at IS NOT NULL;

    IF v_avg_rating IS NULL AND v_avg_hours IS NULL THEN
        RETURN 0;
    END IF;

    v_rating_score := (NVL(v_avg_rating, 0) / 5) * 50;

    IF v_avg_hours IS NULL THEN
        v_time_score := 25;
    ELSIF v_avg_hours <= 4 THEN
        v_time_score := 50;
    ELSIF v_avg_hours <= 24 THEN
        v_time_score := 40;
    ELSIF v_avg_hours <= 48 THEN
        v_time_score := 25;
    ELSE
        v_time_score := GREATEST(0, 50 - ((v_avg_hours - 48) / 4));
    END IF;

    v_final_score := LEAST(100, GREATEST(0, ROUND(v_rating_score + v_time_score, 2)));

    RETURN v_final_score;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END get_worker_performance;
/

-- ----------------------------------------------------------------------------
-- Function 2: get_resolution_time
-- Returns hours from complaint created_at to resolved_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_resolution_time (
    p_complaint_id IN NUMBER
) RETURN NUMBER
IS
    v_hours NUMBER;
BEGIN
    SELECT ROUND(
        (CAST(resolved_at AS DATE) - CAST(created_at AS DATE)) * 24,
        2
    )
    INTO v_hours
    FROM complaints
    WHERE complaint_id = p_complaint_id
      AND resolved_at IS NOT NULL;

    RETURN v_hours;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_resolution_time;
/

-- ----------------------------------------------------------------------------
-- Function 3: get_complaint_summary
-- Returns object with student complaint statistics
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_complaint_summary (
    p_student_id IN NUMBER
) RETURN complaint_summary_t
IS
    v_total    NUMBER;
    v_open     NUMBER;
    v_resolved NUMBER;
    v_avg_rate NUMBER(5,2);
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM complaints
    WHERE student_id = p_student_id;

    SELECT COUNT(*)
    INTO v_open
    FROM complaints
    WHERE student_id = p_student_id
      AND status IN ('submitted', 'assigned', 'in_progress');

    SELECT COUNT(*)
    INTO v_resolved
    FROM complaints
    WHERE student_id = p_student_id
      AND status IN ('resolved', 'closed');

    SELECT ROUND(AVG(f.rating), 2)
    INTO v_avg_rate
    FROM complaints c
    JOIN feedback f ON f.complaint_id = c.complaint_id
    WHERE c.student_id = p_student_id;

    RETURN complaint_summary_t(
        NVL(v_total,    0),
        NVL(v_open,     0),
        NVL(v_resolved, 0),
        v_avg_rate
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN complaint_summary_t(0, 0, 0, NULL);
END get_complaint_summary;
/

-- ----------------------------------------------------------------------------
PROMPT Functions created: get_worker_performance, get_resolution_time, get_complaint_summary, calculate_sla_deadline

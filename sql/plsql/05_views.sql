-- ============================================================================
-- Push 10: Views
-- Campus Maintenance & Complaint Management System
--   1. active_complaints_view
--   2. worker_performance_view
--   3. overdue_complaints_view
--   4. monthly_summary_view
--   5. chronic_issues_view
-- Prerequisite: Pushes 3–9
-- Run as: @sql/plsql/05_views.sql
-- ============================================================================

BEGIN EXECUTE IMMEDIATE 'DROP VIEW chronic_issues_view';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW monthly_summary_view';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW overdue_complaints_view';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW worker_performance_view';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW active_complaints_view';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- View 1: Active complaints with location and assigned worker details
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW active_complaints_view AS
SELECT
    c.complaint_id,
    c.category,
    c.priority,
    c.status,
    c.description,
    c.created_at,
    c.sla_deadline,
    ROUND(
        (CAST(c.sla_deadline AS DATE) - CAST(SYSTIMESTAMP AS DATE)) * 24,
        2
    )                                                   AS hours_until_sla,
    s.name                                              AS student_name,
    s.roll_no                                           AS student_roll,
    l.building,
    l.floor,
    l.room_no,
    l.location_type,
    w.worker_id,
    u.name                                              AS worker_name,
    w.specialization                                    AS worker_specialization,
    a.assignment_id,
    a.assigned_at,
    a.started_at,
    sup.name                                            AS assigned_by_name
FROM complaints c
JOIN users s
    ON s.user_id = c.student_id
JOIN locations l
    ON l.location_id = c.location_id
LEFT JOIN assignments a
    ON a.complaint_id = c.complaint_id
   AND a.completed_at IS NULL
LEFT JOIN workers w
    ON w.worker_id = a.worker_id
LEFT JOIN users u
    ON u.user_id = w.user_id
LEFT JOIN users sup
    ON sup.user_id = a.assigned_by
WHERE c.status IN ('submitted', 'assigned', 'in_progress');

-- ----------------------------------------------------------------------------
-- View 2: Worker performance statistics for admin dashboard
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW worker_performance_view AS
SELECT
    w.worker_id,
    u.name                                              AS worker_name,
    w.specialization,
    w.performance_score                                 AS cached_score,
    get_worker_performance(w.worker_id)                 AS calculated_score,
    w.is_available,
    COUNT(DISTINCT a.assignment_id)                     AS total_assignments,
    COUNT(DISTINCT CASE
        WHEN a.completed_at IS NULL THEN a.assignment_id
    END)                                                AS open_assignments,
    COUNT(DISTINCT CASE
        WHEN a.completed_at IS NOT NULL THEN a.assignment_id
    END)                                                AS completed_assignments,
    ROUND(AVG(f.rating), 2)                             AS avg_rating,
    ROUND(AVG(
        CASE
            WHEN a.completed_at IS NOT NULL THEN
                (CAST(a.completed_at AS DATE) - CAST(c.created_at AS DATE)) * 24
        END
    ), 2)                                               AS avg_resolution_hrs,
    COUNT(DISTINCT CASE
        WHEN c.sla_deadline < NVL(a.completed_at, SYSTIMESTAMP)
         AND c.status IN ('assigned', 'in_progress')
        THEN c.complaint_id
    END)                                                AS overdue_count
FROM workers w
JOIN users u
    ON u.user_id = w.user_id
LEFT JOIN assignments a
    ON a.worker_id = w.worker_id
LEFT JOIN complaints c
    ON c.complaint_id = a.complaint_id
LEFT JOIN feedback f
    ON f.complaint_id = a.complaint_id
GROUP BY
    w.worker_id,
    u.name,
    w.specialization,
    w.performance_score,
    w.is_available;

-- ----------------------------------------------------------------------------
-- View 3: Overdue complaints past SLA deadline (not yet resolved/closed)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW overdue_complaints_view AS
SELECT
    c.complaint_id,
    c.category,
    c.priority,
    c.status,
    c.created_at,
    c.sla_deadline,
    ROUND(
        (CAST(SYSTIMESTAMP AS DATE) - CAST(c.sla_deadline AS DATE)) * 24,
        2
    )                                                   AS hours_overdue,
    s.name                                              AS student_name,
    l.building,
    l.floor,
    l.room_no,
    u.name                                              AS worker_name,
    sup.name                                            AS supervisor_name
FROM complaints c
JOIN users s
    ON s.user_id = c.student_id
JOIN locations l
    ON l.location_id = c.location_id
LEFT JOIN assignments a
    ON a.complaint_id = c.complaint_id
   AND a.completed_at IS NULL
LEFT JOIN workers w
    ON w.worker_id = a.worker_id
LEFT JOIN users u
    ON u.user_id = w.user_id
LEFT JOIN users sup
    ON sup.user_id = a.assigned_by
WHERE c.status IN ('submitted', 'assigned', 'in_progress')
  AND c.sla_deadline < SYSTIMESTAMP;

-- ----------------------------------------------------------------------------
-- View 4: Monthly complaint summary by category
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW monthly_summary_view AS
SELECT
    EXTRACT(YEAR  FROM c.created_at)                   AS report_year,
    EXTRACT(MONTH FROM c.created_at)                    AS report_month,
    c.category,
    COUNT(*)                                            AS total_complaints,
    COUNT(CASE
        WHEN c.status IN ('resolved', 'closed') THEN 1
    END)                                                AS resolved_count,
    COUNT(CASE
        WHEN c.status IN ('submitted', 'assigned', 'in_progress') THEN 1
    END)                                                AS open_count,
    ROUND(AVG(
        CASE
            WHEN c.resolved_at IS NOT NULL THEN
                (CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24
        END
    ), 2)                                               AS avg_resolution_hrs,
    COUNT(CASE
        WHEN c.resolved_at IS NOT NULL
         AND c.resolved_at <= c.sla_deadline THEN 1
    END)                                                AS sla_met_count,
    COUNT(CASE
        WHEN c.resolved_at IS NOT NULL
         AND c.resolved_at > c.sla_deadline THEN 1
    END)                                                AS sla_breached_count
FROM complaints c
GROUP BY
    EXTRACT(YEAR  FROM c.created_at),
    EXTRACT(MONTH FROM c.created_at),
    c.category;

-- ----------------------------------------------------------------------------
-- View 5: Chronic / recurring issues by location
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW chronic_issues_view AS
SELECT
    cf.flag_id,
    cf.location_id,
    l.building,
    l.floor,
    l.room_no,
    l.location_type,
    cf.category,
    cf.complaint_count,
    cf.flagged_at,
    ROUND(
        (CAST(SYSTIMESTAMP AS DATE) - CAST(cf.flagged_at AS DATE)),
        0
    )                                                   AS days_since_flagged
FROM chronic_flags cf
JOIN locations l
    ON l.location_id = cf.location_id
ORDER BY
    cf.complaint_count DESC,
    cf.flagged_at DESC;

-- ----------------------------------------------------------------------------
PROMPT Views created: active_complaints, worker_performance, overdue_complaints, monthly_summary, chronic_issues

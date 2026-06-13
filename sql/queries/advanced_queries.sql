-- ============================================================================
-- Push 11: Advanced Queries
-- Campus Maintenance & Complaint Management System
-- Prerequisite: Pushes 3–10 (schema, data, views, functions)
-- Run as: @sql/queries/advanced_queries.sql
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 100

PROMPT ============================================================
PROMPT Query 1: Top 5 complaint categories this month
PROMPT (GROUP BY + ORDER BY)
PROMPT ============================================================

SELECT category,
       COUNT(*) AS complaint_count
FROM complaints
WHERE EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM SYSDATE)
  AND EXTRACT(YEAR  FROM created_at) = EXTRACT(YEAR  FROM SYSDATE)
GROUP BY category
ORDER BY complaint_count DESC
FETCH FIRST 5 ROWS ONLY;


PROMPT ============================================================
PROMPT Query 2: Workers with more than 3 overdue complaints
PROMPT (HAVING)
PROMPT ============================================================

SELECT w.worker_id,
       u.name              AS worker_name,
       w.specialization,
       COUNT(c.complaint_id) AS overdue_complaints
FROM workers w
JOIN users u
    ON u.user_id = w.user_id
JOIN assignments a
    ON a.worker_id = w.worker_id
   AND a.completed_at IS NULL
JOIN complaints c
    ON c.complaint_id = a.complaint_id
WHERE c.status IN ('assigned', 'in_progress')
  AND c.sla_deadline < SYSTIMESTAMP
GROUP BY w.worker_id, u.name, w.specialization
HAVING COUNT(c.complaint_id) > 3
ORDER BY overdue_complaints DESC;


PROMPT ============================================================
PROMPT Query 3: Average resolution time by category
PROMPT (JOIN + AVG)
PROMPT ============================================================

SELECT c.category,
       COUNT(*)                                                    AS resolved_count,
       ROUND(AVG(
           (CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24
       ), 2)                                                       AS avg_resolution_hrs,
       ROUND(MIN(
           (CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24
       ), 2)                                                       AS fastest_hrs,
       ROUND(MAX(
           (CAST(c.resolved_at AS DATE) - CAST(c.created_at AS DATE)) * 24
       ), 2)                                                       AS slowest_hrs
FROM complaints c
WHERE c.resolved_at IS NOT NULL
GROUP BY c.category
ORDER BY avg_resolution_hrs DESC;


PROMPT ============================================================
PROMPT Query 4: Students with the most complaints
PROMPT (subquery)
PROMPT ============================================================

SELECT u.user_id,
       u.name,
       u.roll_no,
       u.email,
       stats.complaint_count
FROM users u
JOIN (
    SELECT student_id,
           COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY student_id
) stats
    ON stats.student_id = u.user_id
WHERE u.role = 'student'
ORDER BY stats.complaint_count DESC
FETCH FIRST 10 ROWS ONLY;


PROMPT ============================================================
PROMPT Query 5: Complaints solved within SLA vs breached
PROMPT (CASE WHEN)
PROMPT ============================================================

SELECT
    COUNT(*) AS total_resolved,
    COUNT(CASE
        WHEN resolved_at <= sla_deadline THEN 1
    END) AS sla_met,
    COUNT(CASE
        WHEN resolved_at > sla_deadline THEN 1
    END) AS sla_breached,
    ROUND(
        COUNT(CASE WHEN resolved_at <= sla_deadline THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS sla_met_pct,
    ROUND(
        COUNT(CASE WHEN resolved_at > sla_deadline THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS sla_breached_pct
FROM complaints
WHERE resolved_at IS NOT NULL;


PROMPT ============================================================
PROMPT Query 6: Complaint trend — last 6 months
PROMPT (GROUP BY month)
PROMPT ============================================================

SELECT TO_CHAR(TRUNC(created_at, 'MM'), 'YYYY-MM') AS month_label,
       EXTRACT(YEAR  FROM created_at)               AS report_year,
       EXTRACT(MONTH FROM created_at)                AS report_month,
       COUNT(*)                                    AS filed_count,
       COUNT(CASE
           WHEN status IN ('resolved', 'closed') THEN 1
       END)                                        AS resolved_count,
       COUNT(CASE
           WHEN status IN ('submitted', 'assigned', 'in_progress') THEN 1
       END)                                        AS still_open
FROM complaints
WHERE created_at >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -5)
GROUP BY TRUNC(created_at, 'MM'),
         EXTRACT(YEAR  FROM created_at),
         EXTRACT(MONTH FROM created_at)
ORDER BY month_label;


PROMPT ============================================================
PROMPT BONUS Query 7: SLA performance breakdown by priority
PROMPT ============================================================

SELECT priority,
       COUNT(*) AS resolved_total,
       COUNT(CASE WHEN resolved_at <= sla_deadline THEN 1 END) AS within_sla,
       COUNT(CASE WHEN resolved_at >  sla_deadline THEN 1 END) AS breached_sla,
       ROUND(AVG(
           (CAST(resolved_at AS DATE) - CAST(created_at AS DATE)) * 24
       ), 2) AS avg_resolution_hrs
FROM complaints
WHERE resolved_at IS NOT NULL
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'urgent' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low'    THEN 3
    END;


PROMPT ============================================================
PROMPT BONUS Query 8: Total repair cost by category (budget tracking)
PROMPT ============================================================

SELECT c.category,
       COUNT(DISTINCT a.assignment_id) AS completed_jobs,
       ROUND(SUM(a.repair_cost), 2)    AS total_repair_cost,
       ROUND(AVG(a.repair_cost), 2)    AS avg_repair_cost
FROM assignments a
JOIN complaints c
    ON c.complaint_id = a.complaint_id
WHERE a.completed_at IS NOT NULL
GROUP BY c.category
ORDER BY total_repair_cost DESC;

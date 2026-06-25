-- ============================================================================
-- DEMO QUERIES — End-to-end system demonstration
-- Run AFTER @run_all.sql
-- Use in SQL Developer: enable DBMS_OUTPUT (View → Dbms Output → green +)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT ===== 1. Verify tables have data =====
SELECT 'users' AS tbl, COUNT(*) AS cnt FROM users
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL SELECT 'workers', COUNT(*) FROM workers
UNION ALL SELECT 'assignments', COUNT(*) FROM assignments;

PROMPT ===== 2. SLA trigger — insert new complaint =====
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description)
VALUES (seq_complaint_id.NEXTVAL, 4, 2, 'electrical', 'urgent', 'DEMO: Test SLA trigger');
SELECT complaint_id, priority, created_at, sla_deadline
FROM complaints WHERE description = 'DEMO: Test SLA trigger';

PROMPT ===== 3. Function: calculate_sla_deadline =====
SELECT calculate_sla_deadline('medium', SYSTIMESTAMP) AS medium_deadline FROM dual;

PROMPT ===== 4. Procedure: assign_worker =====
BEGIN
    assign_worker(
        p_complaint_id  => (SELECT complaint_id FROM complaints WHERE description = 'DEMO: Test SLA trigger'),
        p_worker_id     => 1,
        p_supervisor_id => 2
    );
END;
/
SELECT complaint_id, status FROM complaints WHERE description = 'DEMO: Test SLA trigger';

PROMPT ===== 5. View: overdue complaints =====
SELECT complaint_id, category, priority, hours_overdue, building, room_no
FROM overdue_complaints_view
FETCH FIRST 5 ROWS ONLY;

PROMPT ===== 6. View: worker performance =====
SELECT worker_name, specialization, calculated_score, open_assignments, overdue_count
FROM worker_performance_view;

PROMPT ===== 7. Function: get_worker_performance =====
SELECT worker_id, get_worker_performance(worker_id) AS score FROM workers;

PROMPT ===== 8. Function: get_complaint_summary (student 4) =====
SELECT get_complaint_summary(4) FROM dual;

PROMPT ===== 9. Procedure: generate_monthly_report =====
EXEC generate_monthly_report(3, 2026);
SELECT month, year, total_complaints, resolved_count, avg_resolution_hrs, total_cost
FROM maintenance_reports WHERE month = 3 AND year = 2026;

PROMPT ===== 10. Procedure: escalate_overdue_complaints =====
EXEC escalate_overdue_complaints;

PROMPT ===== 11. View: chronic issues =====
SELECT building, room_no, category, complaint_count FROM chronic_issues_view;

PROMPT ===== 12. Status audit log (trigger demo) =====
SELECT log_id, complaint_id, old_status, new_status, note
FROM status_log
ORDER BY changed_at DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ===== 13. Advanced query: SLA met vs breached =====
SELECT
    COUNT(*) AS total_resolved,
    COUNT(CASE WHEN resolved_at <= sla_deadline THEN 1 END) AS sla_met,
    COUNT(CASE WHEN resolved_at >  sla_deadline THEN 1 END) AS sla_breached
FROM complaints WHERE resolved_at IS NOT NULL;

PROMPT ============================================================
PROMPT DEMO COMPLETE — All PL/SQL components verified
PROMPT ============================================================

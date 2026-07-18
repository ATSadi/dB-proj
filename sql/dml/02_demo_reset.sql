-- ============================================================================
-- DEMO RESET — wipe transactional data and load teacher-ready demo set
-- Run as campus_user after trigger/procedure fixes are applied
-- Connect: campus_user / Campus123456 @ localhost:1521/XEPDB1
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT ===== Clearing existing data =====
DELETE FROM feedback;
DELETE FROM status_log;
DELETE FROM assignments;
DELETE FROM chronic_flags;
DELETE FROM maintenance_reports;
DELETE FROM complaints;
DELETE FROM workers;
DELETE FROM locations;
DELETE FROM users;
COMMIT;

PROMPT ===== Users =====
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (1,  'Ayesha Khan',      NULL,         'admin@campus.edu',     'admin');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (2,  'Omar Siddiqui',    'SUP001',     'omar.s@campus.edu',    'supervisor');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (3,  'Fatima Ali',       'SUP002',     'fatima.a@campus.edu',  'supervisor');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (4,  'Hassan Raza',      'STU2021001', 'hassan.r@stu.edu',     'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (5,  'Sana Malik',       'STU2021002', 'sana.m@stu.edu',       'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (6,  'Bilal Ahmed',      'STU2021003', 'bilal.a@stu.edu',      'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (7,  'Zainab Hussain',   'STU2021004', 'zainab.h@stu.edu',     'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (8,  'Usman Tariq',      'STU2021005', 'usman.t@stu.edu',      'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (9,  'Mariam Noor',      'STU2021006', 'mariam.n@stu.edu',     'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (10, 'Rashid Iqbal',     'WRK301',     'rashid.i@campus.edu',  'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (11, 'Kamran Shah',      'WRK302',     'kamran.s@campus.edu',  'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (12, 'Nadia Farooq',     'WRK303',     'nadia.f@campus.edu',   'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (13, 'Imran Baig',       'WRK304',     'imran.b@campus.edu',   'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (14, 'Hira Sheikh',      'STU2021007', 'hira.s@stu.edu',       'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (15, 'Sara Cleaning',    'WRK305',     'sara.c@campus.edu',    'worker');

-- All demo accounts initially use: Password123
UPDATE users SET
    password_hash = 'scrypt$8a43a919685c40fea1d52d7693b63799$3936a5f85386eb00a1fa13b62c5035c1ac6349e3a18ae8f234a91573437592336978b651af3dcb9a9cd58b5bf74f1b3f6219308e96d73d793d0894ac7c3deb81',
    reset_token_hash = NULL,
    reset_token_expires = NULL,
    password_changed_at = SYSTIMESTAMP;

PROMPT ===== Locations =====
INSERT INTO locations VALUES (1,  'Block A',       'G',  '001',  'office');
INSERT INTO locations VALUES (2,  'Block A',       '1',  '101',  'classroom');
INSERT INTO locations VALUES (3,  'Block A',       '1',  '102',  'classroom');
INSERT INTO locations VALUES (4,  'Block A',       '2',  '201',  'lab');
INSERT INTO locations VALUES (5,  'Block A',       '2',  '202',  'lab');
INSERT INTO locations VALUES (6,  'Block B',       'G',  '010',  'washroom');
INSERT INTO locations VALUES (7,  'Block B',       '1',  '110',  'classroom');
INSERT INTO locations VALUES (8,  'Block B',       '1',  '111',  'classroom');
INSERT INTO locations VALUES (9,  'Block B',       '2',  '210',  'corridor');
INSERT INTO locations VALUES (10, 'Science Wing',  '1',  'Lab-1', 'lab');
INSERT INTO locations VALUES (11, 'Science Wing',  '1',  'Lab-2', 'lab');
INSERT INTO locations VALUES (12, 'Science Wing',  '2',  'Lab-3', 'lab');
INSERT INTO locations VALUES (13, 'Hostel North',  '1',  'H-101', 'hostel');
INSERT INTO locations VALUES (14, 'Hostel North',  '1',  'H-102', 'hostel');
INSERT INTO locations VALUES (15, 'Hostel North',  '2',  'H-201', 'hostel');
INSERT INTO locations VALUES (16, 'Hostel North',  '2',  'H-202', 'hostel');
INSERT INTO locations VALUES (17, 'Hostel North',  'G',  'Common-WC', 'washroom');
INSERT INTO locations VALUES (18, 'Admin Block',   '1',  'Reception', 'office');
INSERT INTO locations VALUES (19, 'Admin Block',   '2',  'Finance',   'office');
INSERT INTO locations VALUES (20, 'Library',       '1',  'Reading-1', 'classroom');
INSERT INTO locations VALUES (21, 'Library',       '2',  'Reading-2', 'classroom');
INSERT INTO locations VALUES (22, 'Sports Complex','G',  'Gym',       'corridor');
INSERT INTO locations VALUES (23, 'Cafeteria',     'G',  'Main Hall', 'corridor');
INSERT INTO locations VALUES (24, 'Parking Lot',   'G',  'Zone-B',    'corridor');

PROMPT ===== Workers =====
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (1, 10, 'electrical', 82.00, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (2, 11, 'plumbing',   88.00, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (3, 12, 'it',         79.00, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (4, 13, 'furniture',  74.00, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (5, 15, 'cleaning',   80.00, 'Y');

PROMPT ===== Complaints (mixed statuses + live relative dates) =====
-- Closed / historical (for reports + feedback history)
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (1, 4, 2, 'electrical', 'medium', 'Ceiling fan not working in classroom', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(20, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(19, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(19.5, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (2, 5, 7, 'plumbing', 'urgent', 'Water leak under desk area', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(18, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(17.8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(17.9, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (3, 6, 10, 'it', 'medium', 'Projector HDMI port damaged', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(16, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(15, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(15.5, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (4, 7, 13, 'furniture', 'low', 'Broken hostel bed frame', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(14, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(11, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(12, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (5, 8, 17, 'plumbing', 'urgent', 'Hostel washroom tap running continuously', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(12, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(11.8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(11.9, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (6, 9, 17, 'plumbing', 'medium', 'Hostel washroom drain blocked', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(10, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(9, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(9.2, 'DAY'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (7, 4, 17, 'plumbing', 'urgent', 'Hostel washroom pipe burst', 'closed',
        SYSTIMESTAMP - NUMTODSINTERVAL(8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(7.8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(7.9, 'DAY'));

-- Resolved (awaiting student rating) — demo Rate button
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (8, 4, 4, 'electrical', 'medium', 'Lab power socket sparking — DEMO rate me', 'resolved',
        SYSTIMESTAMP - NUMTODSINTERVAL(2, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(1, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(6, 'HOUR'));
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (9, 5, 20, 'furniture', 'medium', 'Library chair armrest broken — DEMO rate me', 'resolved',
        SYSTIMESTAMP - NUMTODSINTERVAL(1, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(0, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'));

-- In progress (worker can Resolve)
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (10, 6, 9, 'electrical', 'medium', 'Corridor light fixture hanging loose', 'in_progress',
        SYSTIMESTAMP - NUMTODSINTERVAL(8, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(16, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (11, 7, 6, 'plumbing', 'urgent', 'Block B washroom flooding', 'in_progress',
        SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(1, 'HOUR'), NULL);

-- Assigned (worker can Start)
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (12, 8, 15, 'furniture', 'low', 'Hostel cupboard door off hinges', 'assigned',
        SYSTIMESTAMP - NUMTODSINTERVAL(20, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(52, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (13, 9, 10, 'it', 'medium', 'Smart board calibration issue', 'assigned',
        SYSTIMESTAMP - NUMTODSINTERVAL(6, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(18, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (14, 14, 17, 'cleaning', 'medium', 'Hostel washroom hygiene poor', 'assigned',
        SYSTIMESTAMP - NUMTODSINTERVAL(4, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(20, 'HOUR'), NULL);

-- Overdue assigned (SLA breach for admin overdue view)
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (15, 5, 7, 'electrical', 'urgent', 'Classroom main switch tripping — OVERDUE', 'assigned',
        SYSTIMESTAMP - NUMTODSINTERVAL(10, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(5, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (16, 6, 11, 'it', 'medium', 'Lab software license expired — OVERDUE', 'assigned',
        SYSTIMESTAMP - NUMTODSINTERVAL(40, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(12, 'HOUR'), NULL);

-- Submitted (supervisor can Assign) — one per specialty
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (17, 4, 3, 'electrical', 'medium', 'Lights flickering in Block A 102 — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(2, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(22, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (18, 5, 17, 'plumbing', 'urgent', 'Toilet flush not working — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(1, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(3, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (19, 6, 5, 'it', 'urgent', 'Lab network switch down — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(30, 'MINUTE'), SYSTIMESTAMP + NUMTODSINTERVAL(3.5, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (20, 7, 21, 'furniture', 'medium', 'Library table wobble — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(45, 'MINUTE'), SYSTIMESTAMP + NUMTODSINTERVAL(23, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (21, 8, 23, 'cleaning', 'low', 'Cafeteria floor slippery — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(90, 'MINUTE'), SYSTIMESTAMP + NUMTODSINTERVAL(70, 'HOUR'), NULL);
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (22, 14, 24, 'other', 'low', 'Parking lot pothole near Zone B — READY TO ASSIGN', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(69, 'HOUR'), NULL);

-- Extra plumbing at loc 17 for chronic (>=3 already via 5,6,7 + these if needed)
INSERT INTO complaints (complaint_id, student_id, location_id, category, priority, description, status, created_at, sla_deadline, resolved_at)
VALUES (23, 9, 17, 'plumbing', 'low', 'Washroom mirror loose fitting', 'submitted',
        SYSTIMESTAMP - NUMTODSINTERVAL(5, 'HOUR'), SYSTIMESTAMP + NUMTODSINTERVAL(67, 'HOUR'), NULL);

PROMPT ===== Assignments =====
-- Completed history
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (1, 1, 1, 2, SYSTIMESTAMP - NUMTODSINTERVAL(20, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(19.9, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(19.5, 'DAY'), 450);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (2, 2, 2, 2, SYSTIMESTAMP - NUMTODSINTERVAL(18, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(17.95, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(17.9, 'DAY'), 1200);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (3, 3, 3, 3, SYSTIMESTAMP - NUMTODSINTERVAL(16, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(15.8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(15.5, 'DAY'), 350);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (4, 4, 4, 2, SYSTIMESTAMP - NUMTODSINTERVAL(14, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(13.5, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(12, 'DAY'), 800);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (5, 5, 2, 3, SYSTIMESTAMP - NUMTODSINTERVAL(12, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(11.95, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(11.9, 'DAY'), 250);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (6, 6, 2, 2, SYSTIMESTAMP - NUMTODSINTERVAL(10, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(9.5, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(9.2, 'DAY'), 400);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (7, 7, 2, 2, SYSTIMESTAMP - NUMTODSINTERVAL(8, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(7.95, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(7.9, 'DAY'), 3500);
-- Resolved awaiting rating
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (8, 8, 1, 2, SYSTIMESTAMP - NUMTODSINTERVAL(2, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(1.5, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(6, 'HOUR'), 600);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (9, 9, 4, 3, SYSTIMESTAMP - NUMTODSINTERVAL(1, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(20, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'), 150);
-- In progress
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (10, 10, 1, 3, SYSTIMESTAMP - NUMTODSINTERVAL(7, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(6, 'HOUR'), NULL, 0);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (11, 11, 2, 2, SYSTIMESTAMP - NUMTODSINTERVAL(2.5, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(2, 'HOUR'), NULL, 0);
-- Assigned
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (12, 12, 4, 2, SYSTIMESTAMP - NUMTODSINTERVAL(18, 'HOUR'), NULL, NULL, 0);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (13, 13, 3, 3, SYSTIMESTAMP - NUMTODSINTERVAL(5, 'HOUR'), NULL, NULL, 0);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (14, 14, 5, 2, SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'), NULL, NULL, 0);
-- Overdue assigned
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (15, 15, 1, 2, SYSTIMESTAMP - NUMTODSINTERVAL(9, 'HOUR'), NULL, NULL, 0);
INSERT INTO assignments (assignment_id, complaint_id, worker_id, assigned_by, assigned_at, started_at, completed_at, repair_cost)
VALUES (16, 16, 3, 3, SYSTIMESTAMP - NUMTODSINTERVAL(30, 'HOUR'), NULL, NULL, 0);

PROMPT ===== Feedback (closed only) =====
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (1, 1, 4, 4, 'Fixed quickly but room was dusty after repair.', SYSTIMESTAMP - NUMTODSINTERVAL(19, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (2, 2, 5, 5, 'Excellent response to urgent leak.', SYSTIMESTAMP - NUMTODSINTERVAL(17.5, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (3, 3, 6, 5, 'Projector working perfectly now.', SYSTIMESTAMP - NUMTODSINTERVAL(15, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (4, 4, 7, 4, 'Bed fixed but took a day longer than expected.', SYSTIMESTAMP - NUMTODSINTERVAL(11.5, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (5, 5, 8, 5, 'Urgent tap fixed fast.', SYSTIMESTAMP - NUMTODSINTERVAL(11.5, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (6, 6, 9, 4, 'Drain cleared successfully.', SYSTIMESTAMP - NUMTODSINTERVAL(9, 'DAY'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at)
VALUES (7, 7, 4, 5, 'Pipe burst fixed immediately.', SYSTIMESTAMP - NUMTODSINTERVAL(7.5, 'DAY'));

PROMPT ===== Sync worker availability from open assignments =====
UPDATE workers w
SET is_available = CASE
    WHEN EXISTS (
        SELECT 1 FROM assignments a
        WHERE a.worker_id = w.worker_id AND a.completed_at IS NULL
    ) THEN 'N' ELSE 'Y' END;

PROMPT ===== Sample monthly report =====
INSERT INTO maintenance_reports (report_id, month, year, generated_at, total_complaints, resolved_count, avg_resolution_hrs, total_cost)
VALUES (1, EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -1)), EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -1)),
        SYSTIMESTAMP, 7, 7, 12.40, 6950);

COMMIT;

PROMPT ===== Reset sequences =====
DECLARE
    PROCEDURE reset_seq(p_seq VARCHAR2, p_max NUMBER) IS
        l_start NUMBER := p_max + 1;
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_seq;
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || p_seq
            || ' START WITH ' || l_start
            || ' INCREMENT BY 1 NOCACHE NOCYCLE';
    END;
BEGIN
    reset_seq('seq_user_id', 15);
    reset_seq('seq_location_id', 24);
    reset_seq('seq_complaint_id', 23);
    reset_seq('seq_worker_id', 5);
    reset_seq('seq_assignment_id', 16);
    reset_seq('seq_feedback_id', 7);
    reset_seq('seq_flag_id', 5);
    reset_seq('seq_report_id', 1);
END;
/

-- status_log IDs come from triggers — sync sequence to real max
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(log_id), 0) INTO v_max FROM status_log;
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_log_id';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_log_id START WITH ' || (v_max + 1) ||
                      ' INCREMENT BY 1 NOCACHE NOCYCLE';
END;
/

PROMPT ===== Counts =====
SELECT 'users' t, COUNT(*) c FROM users
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'workers', COUNT(*) FROM workers
UNION ALL SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL SELECT 'assignments', COUNT(*) FROM assignments
UNION ALL SELECT 'feedback', COUNT(*) FROM feedback
UNION ALL SELECT 'chronic_flags', COUNT(*) FROM chronic_flags
UNION ALL SELECT 'status_log', COUNT(*) FROM status_log;

PROMPT DEMO RESET COMPLETE

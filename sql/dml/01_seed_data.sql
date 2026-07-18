-- ============================================================================
-- Push 5: DML — Seed Data
-- Campus Maintenance & Complaint Management System
-- Prerequisite: @sql/ddl/01_create_tables.sql
--               @sql/ddl/02_create_supporting_tables.sql
--               @sql/ddl/03_sequences.sql
-- Run as: @sql/dml/01_seed_data.sql
-- ============================================================================

SET DEFINE OFF;

-- Clear existing data (child tables first)
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

-- ============================================================================
-- USERS (14 rows: 1 admin, 2 supervisors, 6 students, 4 workers, 1 extra student)
-- ============================================================================
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (1,  'Ayesha Khan',      NULL,       'admin@campus.edu',     'admin');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (2,  'Omar Siddiqui',    'SUP001',   'omar.s@campus.edu',    'supervisor');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (3,  'Fatima Ali',       'SUP002',   'fatima.a@campus.edu',  'supervisor');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (4,  'Hassan Raza',      'STU2021001', 'hassan.r@stu.edu',   'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (5,  'Sana Malik',       'STU2021002', 'sana.m@stu.edu',     'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (6,  'Bilal Ahmed',      'STU2021003', 'bilal.a@stu.edu',    'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (7,  'Zainab Hussain',   'STU2021004', 'zainab.h@stu.edu',   'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (8,  'Usman Tariq',      'STU2021005', 'usman.t@stu.edu',    'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (9,  'Mariam Noor',      'STU2021006', 'mariam.n@stu.edu',   'student');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (10, 'Rashid Iqbal',     'WRK301',   'rashid.i@campus.edu',  'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (11, 'Kamran Shah',      'WRK302',   'kamran.s@campus.edu',  'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (12, 'Nadia Farooq',     'WRK303',   'nadia.f@campus.edu',   'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (13, 'Imran Baig',       'WRK304',   'imran.b@campus.edu',   'worker');
INSERT INTO users (user_id, name, roll_no, email, role) VALUES (14, 'Hira Sheikh',      'STU2021007', 'hira.s@stu.edu',     'student');

-- All demo accounts initially use: Password123
UPDATE users SET
    password_hash = 'scrypt$8a43a919685c40fea1d52d7693b63799$3936a5f85386eb00a1fa13b62c5035c1ac6349e3a18ae8f234a91573437592336978b651af3dcb9a9cd58b5bf74f1b3f6219308e96d73d793d0894ac7c3deb81',
    reset_token_hash = NULL,
    reset_token_expires = NULL,
    password_changed_at = SYSTIMESTAMP;

-- ============================================================================
-- LOCATIONS (24 rows)
-- ============================================================================
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

-- ============================================================================
-- WORKERS (4 rows)
-- ============================================================================
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (1, 10, 'electrical', 78.50, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (2, 11, 'plumbing',   85.00, 'N');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (3, 12, 'it',         72.25, 'Y');
INSERT INTO workers (worker_id, user_id, specialization, performance_score, is_available) VALUES (4, 13, 'furniture',  68.00, 'Y');

-- ============================================================================
-- COMPLAINTS (38 rows — varied category, priority, status, dates)
-- sla_deadline set manually (Push 6 trigger will automate this)
-- ============================================================================

-- January 2026
INSERT INTO complaints VALUES (1,  4, 2,  'electrical', 'medium', 'Ceiling fan not working in classroom',           'closed',      TO_TIMESTAMP('2026-01-05 09:15:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-06 09:15:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-05 18:30:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (2,  5, 7,  'plumbing',   'urgent', 'Water leak under desk area',                     'resolved',    TO_TIMESTAMP('2026-01-08 11:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-08 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-08 14:20:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (3,  6, 10, 'it',         'medium', 'Projector HDMI port damaged',                    'closed',      TO_TIMESTAMP('2026-01-12 14:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-13 14:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-12 17:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (4,  7, 13, 'furniture',  'low',    'Broken hostel bed frame',                        'closed',      TO_TIMESTAMP('2026-01-15 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-18 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-16 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (5,  8, 17, 'plumbing',   'urgent', 'Hostel washroom tap running continuously',       'resolved',    TO_TIMESTAMP('2026-01-18 07:45:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-18 11:45:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-18 10:30:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (6,  9, 6,  'cleaning',   'low',    'Washroom needs deep cleaning',                   'closed',      TO_TIMESTAMP('2026-01-20 16:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-23 16:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-21 09:00:00','YYYY-MM-DD HH24:MI:SS'));

-- February 2026
INSERT INTO complaints VALUES (7,  4, 4,  'electrical', 'urgent', 'Lab power socket sparking',                      'closed',      TO_TIMESTAMP('2026-02-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-02 14:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-02 12:45:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (8,  5, 20, 'furniture',  'medium', 'Library chair armrest broken',                   'resolved',    TO_TIMESTAMP('2026-02-05 13:20:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-06 13:20:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-05 16:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (9,  6, 11, 'it',         'medium', 'Lab PC batch not booting',                       'closed',      TO_TIMESTAMP('2026-02-08 09:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-09 09:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-08 15:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (10, 7, 17, 'plumbing',   'medium', 'Hostel washroom drain blocked',                  'resolved',    TO_TIMESTAMP('2026-02-10 18:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-11 18:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-11 08:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (11, 8, 17, 'plumbing',   'low',    'Low water pressure in hostel washroom',          'closed',      TO_TIMESTAMP('2026-02-12 07:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-15 07:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-13 11:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (12, 9, 3,  'electrical', 'medium', 'Lights flickering in Block A room 102',          'closed',      TO_TIMESTAMP('2026-02-14 11:45:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-15 11:45:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-14 19:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (13, 14,18,'other',      'low',    'Reception AC too noisy',                         'resolved',    TO_TIMESTAMP('2026-02-18 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-21 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-19 14:00:00','YYYY-MM-DD HH24:MI:SS'));

-- March 2026
INSERT INTO complaints VALUES (14, 4,  17, 'plumbing',   'urgent', 'Hostel washroom pipe burst',                     'closed',      TO_TIMESTAMP('2026-03-01 06:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-01 10:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-01 09:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (15, 5,  8,  'cleaning',   'medium', 'Classroom whiteboard stains',                    'resolved',    TO_TIMESTAMP('2026-03-03 12:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-04 12:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-03 17:30:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (16, 6,  12, 'electrical', 'medium', 'Science lab exhaust fan failure',              'closed',      TO_TIMESTAMP('2026-03-05 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-06 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-05 20:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (17, 7,  23, 'cleaning',   'low',    'Cafeteria floor slippery near entrance',         'resolved',    TO_TIMESTAMP('2026-03-07 08:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-10 08:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-07 16:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (18, 8,  2,  'furniture',  'medium', 'Loose desk hinge in Block A 101',                'closed',      TO_TIMESTAMP('2026-03-09 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-10 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-09 14:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (19, 9,  17, 'plumbing',   'medium', 'Toilet flush not working in hostel washroom',    'resolved',    TO_TIMESTAMP('2026-03-11 19:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-12 19:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-12 07:30:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (20, 14, 5,  'it',         'urgent', 'Lab network switch down',                        'closed',      TO_TIMESTAMP('2026-03-13 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-13 12:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-13 10:15:00','YYYY-MM-DD HH24:MI:SS'));

-- April 2026 — active / in-progress mix
INSERT INTO complaints VALUES (21, 4,  9,  'electrical', 'medium', 'Corridor light fixture hanging loose',           'in_progress', TO_TIMESTAMP('2026-04-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (22, 5,  15, 'furniture',  'low',    'Hostel cupboard door off hinges',                'assigned',    TO_TIMESTAMP('2026-04-03 14:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-06 14:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (23, 6,  10, 'it',         'medium', 'Smart board calibration issue',                  'assigned',    TO_TIMESTAMP('2026-04-05 11:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-06 11:30:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (24, 7,  6,  'plumbing',   'urgent', 'Block B washroom flooding',                      'in_progress', TO_TIMESTAMP('2026-04-06 07:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-06 11:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (25, 8,  21, 'furniture',  'medium', 'Library table wobble',                           'resolved',    TO_TIMESTAMP('2026-04-07 13:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-08 13:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-07 18:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (26, 9,  1,  'electrical', 'low',    'Office extension cord needed',                   'submitted',   TO_TIMESTAMP('2026-04-08 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-11 09:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (27, 14, 24, 'other',      'low',    'Parking lot pothole near Zone B',                  'submitted',   TO_TIMESTAMP('2026-04-09 16:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-12 16:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (28, 4,  17, 'cleaning',   'medium', 'Hostel washroom hygiene poor',                   'assigned',    TO_TIMESTAMP('2026-04-10 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-11 08:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);

-- May 2026 — includes overdue SLA cases for escalation demo
INSERT INTO complaints VALUES (29, 5,  7,  'electrical', 'urgent', 'Classroom main switch tripping',                 'assigned',    TO_TIMESTAMP('2026-05-01 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-01 12:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (30, 6,  11, 'it',         'medium', 'Lab software license expired message',           'assigned',    TO_TIMESTAMP('2026-05-03 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-04 10:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (31, 7,  16, 'furniture',  'low',    'Hostel room window latch broken',                'submitted',   TO_TIMESTAMP('2026-05-05 12:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-08 12:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (32, 8,  19, 'electrical', 'medium', 'Finance office UPS beeping',                     'in_progress', TO_TIMESTAMP('2026-05-07 09:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-08 09:30:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (33, 9,  22, 'cleaning',   'low',    'Gym mats need sanitizing',                       'resolved',    TO_TIMESTAMP('2026-05-08 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-11 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-09 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (34, 14, 13, 'plumbing',   'medium', 'Hostel room H-101 sink slow drain',              'closed',      TO_TIMESTAMP('2026-05-10 07:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-11 07:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-10 19:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO complaints VALUES (35, 4,  17, 'plumbing',   'urgent', 'Hostel washroom ceiling damp patch',             'assigned',    TO_TIMESTAMP('2026-05-11 06:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-11 10:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (36, 5,  3,  'electrical', 'medium', 'AC unit not cooling in room 102',                'submitted',   TO_TIMESTAMP('2026-05-12 11:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-13 11:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (37, 6,  17, 'plumbing',   'low',    'Washroom mirror loose fitting',                  'submitted',   TO_TIMESTAMP('2026-05-12 14:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-15 14:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);
INSERT INTO complaints VALUES (38, 7,  8,  'it',         'urgent', 'Classroom smart TV no display',                  'assigned',    TO_TIMESTAMP('2026-05-13 08:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-13 12:30:00','YYYY-MM-DD HH24:MI:SS'), NULL);

-- ============================================================================
-- ASSIGNMENTS (22 rows — for assigned / in_progress / resolved / closed)
-- ============================================================================
INSERT INTO assignments VALUES (1,  1,  1, 2, TO_TIMESTAMP('2026-01-05 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-05 11:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-05 18:30:00','YYYY-MM-DD HH24:MI:SS'), 450.00);
INSERT INTO assignments VALUES (2,  2,  2, 2, TO_TIMESTAMP('2026-01-08 11:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-08 12:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-08 14:20:00','YYYY-MM-DD HH24:MI:SS'), 1200.00);
INSERT INTO assignments VALUES (3,  3,  3, 3, TO_TIMESTAMP('2026-01-12 15:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-12 15:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-12 17:00:00','YYYY-MM-DD HH24:MI:SS'), 350.00);
INSERT INTO assignments VALUES (4,  4,  4, 2, TO_TIMESTAMP('2026-01-15 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-15 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-16 10:00:00','YYYY-MM-DD HH24:MI:SS'), 800.00);
INSERT INTO assignments VALUES (5,  5,  2, 3, TO_TIMESTAMP('2026-01-18 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-18 08:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-01-18 10:30:00','YYYY-MM-DD HH24:MI:SS'), 250.00);
INSERT INTO assignments VALUES (6,  7,  1, 2, TO_TIMESTAMP('2026-02-02 10:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-02 11:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-02 12:45:00','YYYY-MM-DD HH24:MI:SS'), 600.00);
INSERT INTO assignments VALUES (7,  8,  4, 3, TO_TIMESTAMP('2026-02-05 14:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-05 14:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-05 16:00:00','YYYY-MM-DD HH24:MI:SS'), 150.00);
INSERT INTO assignments VALUES (8,  9,  3, 2, TO_TIMESTAMP('2026-02-08 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-08 10:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-08 15:00:00','YYYY-MM-DD HH24:MI:SS'), 0.00);
INSERT INTO assignments VALUES (9,  10, 2, 3, TO_TIMESTAMP('2026-02-10 19:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-11 07:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-02-11 08:00:00','YYYY-MM-DD HH24:MI:SS'), 400.00);
INSERT INTO assignments VALUES (10, 14, 2, 2, TO_TIMESTAMP('2026-03-01 07:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-01 07:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-01 09:00:00','YYYY-MM-DD HH24:MI:SS'), 3500.00);
INSERT INTO assignments VALUES (11, 20, 3, 2, TO_TIMESTAMP('2026-03-13 08:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-13 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-03-13 10:15:00','YYYY-MM-DD HH24:MI:SS'), 0.00);
INSERT INTO assignments VALUES (12, 21, 1, 3, TO_TIMESTAMP('2026-04-01 11:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-01 12:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, 0.00);
INSERT INTO assignments VALUES (13, 22, 4, 2, TO_TIMESTAMP('2026-04-03 15:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (14, 23, 3, 3, TO_TIMESTAMP('2026-04-05 12:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (15, 24, 2, 2, TO_TIMESTAMP('2026-04-06 07:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-06 08:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, 0.00);
INSERT INTO assignments VALUES (16, 25, 4, 3, TO_TIMESTAMP('2026-04-07 14:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-07 14:30:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-04-07 18:00:00','YYYY-MM-DD HH24:MI:SS'), 200.00);
INSERT INTO assignments VALUES (17, 29, 1, 2, TO_TIMESTAMP('2026-05-01 09:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (18, 30, 3, 3, TO_TIMESTAMP('2026-05-03 11:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (19, 32, 1, 2, TO_TIMESTAMP('2026-05-07 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-07 10:30:00','YYYY-MM-DD HH24:MI:SS'), NULL, 0.00);
INSERT INTO assignments VALUES (20, 35, 2, 2, TO_TIMESTAMP('2026-05-11 07:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (21, 38, 3, 3, TO_TIMESTAMP('2026-05-13 09:00:00','YYYY-MM-DD HH24:MI:SS'), NULL, NULL, 0.00);
INSERT INTO assignments VALUES (22, 34, 2, 2, TO_TIMESTAMP('2026-05-10 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-10 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-10 19:00:00','YYYY-MM-DD HH24:MI:SS'), 175.00);

-- ============================================================================
-- FEEDBACK (15 rows — for resolved / closed complaints)
-- ============================================================================
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (1,  1,  4,  4, 'Fixed quickly but room was dusty after repair.',  TO_TIMESTAMP('2026-01-06 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (2,  2,  5,  5, 'Excellent response to urgent leak.',                TO_TIMESTAMP('2026-01-08 16:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (3,  3,  6,  5, 'Projector working perfectly now.',                  TO_TIMESTAMP('2026-01-13 09:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (4,  4,  7,  4, 'Bed fixed but took a day longer than expected.',    TO_TIMESTAMP('2026-01-17 08:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (5,  7,  4,  5, 'Dangerous issue handled within hours.',             TO_TIMESTAMP('2026-02-03 09:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (6,  8,  5,  4, 'Chair repaired same day.',                          TO_TIMESTAMP('2026-02-06 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (7,  9,  6,  3, 'Took too long to restore all PCs.',                 TO_TIMESTAMP('2026-02-09 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (8,  10, 7,  4, 'Drain cleared but smell remained briefly.',         TO_TIMESTAMP('2026-02-12 09:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (9,  14, 4,  5, 'Pipe burst fixed immediately.',                     TO_TIMESTAMP('2026-03-02 08:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (10, 16, 6,  4, 'Fan replaced efficiently.',                         TO_TIMESTAMP('2026-03-06 10:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (11, 18, 8,  5, 'Desk hinge tightened, good job.',                   TO_TIMESTAMP('2026-03-10 08:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (12, 20, 14, 5, 'Network restored before morning classes.',          TO_TIMESTAMP('2026-03-13 11:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (13, 25, 8,  4, 'Table stable now.',                                 TO_TIMESTAMP('2026-04-08 09:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (14, 33, 9,  3, 'Gym mats cleaned but scheduling was inconvenient.', TO_TIMESTAMP('2026-05-10 08:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, feedback_comment, submitted_at) VALUES (15, 34, 14, 4, 'Sink draining normally again.',                     TO_TIMESTAMP('2026-05-11 08:00:00','YYYY-MM-DD HH24:MI:SS'));

-- ============================================================================
-- CHRONIC_FLAGS (2 rows — location 17 has 5+ plumbing complaints)
-- ============================================================================
INSERT INTO chronic_flags VALUES (1, 17, 'plumbing', 5, TO_TIMESTAMP('2026-03-11 20:00:00','YYYY-MM-DD HH24:MI:SS'));
INSERT INTO chronic_flags VALUES (2, 10, 'it',       3, TO_TIMESTAMP('2026-02-08 16:00:00','YYYY-MM-DD HH24:MI:SS'));

-- ============================================================================
-- MAINTENANCE_REPORTS (2 sample monthly reports)
-- ============================================================================
INSERT INTO maintenance_reports VALUES (1, 1, 2026, TO_TIMESTAMP('2026-02-01 00:00:00','YYYY-MM-DD HH24:MI:SS'), 6,  5,  18.50, 5050.00);
INSERT INTO maintenance_reports VALUES (2, 2, 2026, TO_TIMESTAMP('2026-03-01 00:00:00','YYYY-MM-DD HH24:MI:SS'), 7,  6,  22.75,  550.00);

COMMIT;

-- ============================================================================
-- Reset sequences to continue after highest inserted IDs
-- ============================================================================
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
    reset_seq('seq_user_id',      14);
    reset_seq('seq_location_id',  24);
    reset_seq('seq_complaint_id', 38);
    reset_seq('seq_worker_id',     4);
    reset_seq('seq_assignment_id',22);
    reset_seq('seq_feedback_id',  15);
    reset_seq('seq_flag_id',       2);
    reset_seq('seq_report_id',     2);
    -- status_log populated by triggers in Push 6
    reset_seq('seq_log_id',        1);
END;
/

PROMPT Seed data loaded: 14 users, 24 locations, 38 complaints, 4 workers, 22 assignments, 15 feedback records

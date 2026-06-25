-- ============================================================================
-- FIX SCRIPT — run after first run_all.sql if FEEDBACK / views failed
--
-- STEP A (Admin / SYSTEM connection) — run this block first:
--   GRANT CREATE VIEW TO campus_user;
--
-- STEP B (Campus Project / campus_user connection) — run rest with F5
-- ============================================================================

PROMPT ===== Creating FEEDBACK table (comment is reserved in Oracle) =====

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE feedback CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE feedback (
    feedback_id       NUMBER(10)      NOT NULL,
    complaint_id      NUMBER          NOT NULL,
    student_id        NUMBER          NOT NULL,
    rating            NUMBER(1)       NOT NULL,
    feedback_comment  VARCHAR2(300),
    submitted_at      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT pk_feedback PRIMARY KEY (feedback_id),
    CONSTRAINT uq_feedback_complaint UNIQUE (complaint_id),

    CONSTRAINT fk_feedback_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id),

    CONSTRAINT fk_feedback_student FOREIGN KEY (student_id)
        REFERENCES users (user_id),

    CONSTRAINT chk_feedback_rating CHECK (rating BETWEEN 1 AND 5)
);

PROMPT ===== Inserting feedback seed data =====

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
COMMIT;

PROMPT ===== Re-run triggers, functions, views, procedures =====
@plsql/02_triggers_part2.sql
@plsql/04_functions.sql
@plsql/05_views.sql

PROMPT ===== Recompile submit_feedback_safe =====
@plsql/06_transactions.sql

PROMPT ===== Verify =====
SELECT 'feedback rows' AS check_item, COUNT(*) AS cnt FROM feedback
UNION ALL SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL SELECT 'views', COUNT(*) FROM user_views WHERE view_name LIKE '%COMPLAINTS_VIEW' OR view_name LIKE '%PERFORMANCE_VIEW';

PROMPT FIX COMPLETE — now run DEMO_QUERIES.sql

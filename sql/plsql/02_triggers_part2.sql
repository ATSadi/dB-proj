-- ============================================================================
-- Push 7: Triggers (Part 2) — Smart Logic
-- Campus Maintenance & Complaint Management System
--   4. After feedback insert → recalculate worker performance_score
--   5. After complaint insert → detect chronic issues (3+ same location+category)
-- Prerequisite: @sql/plsql/01_triggers.sql
-- Run as: @sql/plsql/02_triggers_part2.sql
-- ============================================================================

BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_feedback_performance';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_complaints_chronic_flag'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- Trigger 4: Recalculate worker performance_score after feedback
--
-- Score (0-100) = rating component (50%) + resolution-time component (50%)
--   Rating:      (avg_rating / 5) * 50
--   Resolution:  <= 4h → 50 | <= 24h → 40 | <= 48h → 25 | else scaled down
-- (Same formula used by get_worker_performance in Push 9)
-- ----------------------------------------------------------------------------
-- Compound trigger avoids ORA-04091 when recalculating from FEEDBACK
CREATE OR REPLACE TRIGGER trg_feedback_performance
FOR INSERT ON feedback
COMPOUND TRIGGER
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    g_complaint_ids t_ids;
    g_idx PLS_INTEGER := 0;

    AFTER EACH ROW IS
    BEGIN
        g_idx := g_idx + 1;
        g_complaint_ids(g_idx) := :NEW.complaint_id;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_worker_id     NUMBER;
        v_avg_rating    NUMBER;
        v_avg_hours     NUMBER;
        v_rating_score  NUMBER;
        v_time_score    NUMBER;
        v_final_score   NUMBER;
        i               PLS_INTEGER;
        v_complaint_id  NUMBER;
    BEGIN
        i := g_complaint_ids.FIRST;
        WHILE i IS NOT NULL LOOP
            v_complaint_id := g_complaint_ids(i);

            BEGIN
                SELECT a.worker_id
                INTO v_worker_id
                FROM assignments a
                WHERE a.complaint_id = v_complaint_id
                  AND a.completed_at IS NOT NULL
                ORDER BY a.completed_at DESC
                FETCH FIRST 1 ROW ONLY;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_worker_id := NULL;
            END;

            IF v_worker_id IS NOT NULL THEN
                SELECT AVG(f.rating)
                INTO v_avg_rating
                FROM assignments a
                JOIN feedback f ON f.complaint_id = a.complaint_id
                WHERE a.worker_id = v_worker_id
                  AND a.completed_at IS NOT NULL;

                SELECT AVG(
                    (CAST(a.completed_at AS DATE) - CAST(c.created_at AS DATE)) * 24
                )
                INTO v_avg_hours
                FROM assignments a
                JOIN complaints c ON c.complaint_id = a.complaint_id
                WHERE a.worker_id = v_worker_id
                  AND a.completed_at IS NOT NULL;

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

                UPDATE workers
                SET performance_score = v_final_score
                WHERE worker_id = v_worker_id;
            END IF;

            i := g_complaint_ids.NEXT(i);
        END LOOP;
    END AFTER STATEMENT;
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 5: Chronic issue detection
-- After complaint insert: if same location + category count >= 3,
-- insert or update CHRONIC_FLAGS
-- ----------------------------------------------------------------------------
-- Compound trigger avoids ORA-04091 (mutating table) on COMPLAINTS
CREATE OR REPLACE TRIGGER trg_complaints_chronic_flag
FOR INSERT ON complaints
COMPOUND TRIGGER
    TYPE t_row IS RECORD (
        location_id NUMBER,
        category    VARCHAR2(50)
    );
    TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
    g_rows t_rows;
    g_idx  PLS_INTEGER := 0;

    AFTER EACH ROW IS
    BEGIN
        g_idx := g_idx + 1;
        g_rows(g_idx).location_id := :NEW.location_id;
        g_rows(g_idx).category    := :NEW.category;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_count  NUMBER;
        v_exists NUMBER;
        i        PLS_INTEGER;
    BEGIN
        i := g_rows.FIRST;
        WHILE i IS NOT NULL LOOP
            SELECT COUNT(*)
            INTO v_count
            FROM complaints
            WHERE location_id = g_rows(i).location_id
              AND category    = g_rows(i).category;

            IF v_count >= 3 THEN
                SELECT COUNT(*)
                INTO v_exists
                FROM chronic_flags
                WHERE location_id = g_rows(i).location_id
                  AND category    = g_rows(i).category;

                IF v_exists = 0 THEN
                    INSERT INTO chronic_flags (
                        flag_id,
                        location_id,
                        category,
                        complaint_count,
                        flagged_at
                    ) VALUES (
                        seq_flag_id.NEXTVAL,
                        g_rows(i).location_id,
                        g_rows(i).category,
                        v_count,
                        SYSTIMESTAMP
                    );
                ELSE
                    UPDATE chronic_flags
                    SET complaint_count = v_count,
                        flagged_at      = SYSTIMESTAMP
                    WHERE location_id = g_rows(i).location_id
                      AND category    = g_rows(i).category;
                END IF;
            END IF;

            i := g_rows.NEXT(i);
        END LOOP;
    END AFTER STATEMENT;
END;
/

-- ----------------------------------------------------------------------------
PROMPT Triggers Part 2 created: feedback performance score, chronic issue detection

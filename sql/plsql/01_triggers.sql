-- ============================================================================
-- Push 6: Triggers (Part 1)
-- Campus Maintenance & Complaint Management System
--   1. Auto-set SLA deadline on complaint insert/update
--   2. Auto-log every status change into STATUS_LOG
--   3. Auto-update worker availability on assignment
-- Prerequisite: DDL scripts + @sql/dml/01_seed_data.sql
-- Run as: @sql/plsql/01_triggers.sql
-- ============================================================================

-- Drop existing triggers (safe re-run)
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_complaints_sla';              EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_complaints_status_log';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_complaints_initial_status_log'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_assignments_worker_busy';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_assignments_worker_free';     EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- Trigger 1: Auto-set SLA deadline
-- urgent = +4 hours | medium = +24 hours | low = +72 hours
-- Fires BEFORE INSERT and when priority is updated
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_complaints_sla
BEFORE INSERT OR UPDATE OF priority ON complaints
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.created_at IS NULL THEN
            :NEW.created_at := SYSTIMESTAMP;
        END IF;

        :NEW.sla_deadline := CASE :NEW.priority
            WHEN 'urgent' THEN :NEW.created_at + NUMTODSINTERVAL(4,  'HOUR')
            WHEN 'medium' THEN :NEW.created_at + NUMTODSINTERVAL(24, 'HOUR')
            WHEN 'low'    THEN :NEW.created_at + NUMTODSINTERVAL(72, 'HOUR')
        END;

    ELSIF UPDATING THEN
        IF :NEW.priority <> :OLD.priority THEN
            :NEW.sla_deadline := CASE :NEW.priority
                WHEN 'urgent' THEN :OLD.created_at + NUMTODSINTERVAL(4,  'HOUR')
                WHEN 'medium' THEN :OLD.created_at + NUMTODSINTERVAL(24, 'HOUR')
                WHEN 'low'    THEN :OLD.created_at + NUMTODSINTERVAL(72, 'HOUR')
            END;
        END IF;
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 2: Log every status change (BEFORE UPDATE on COMPLAINTS)
-- Also stamps resolved_at when status becomes resolved or closed
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_complaints_status_log
BEFORE UPDATE OF status ON complaints
FOR EACH ROW
WHEN (NEW.status <> OLD.status)
BEGIN
    IF :NEW.status IN ('resolved', 'closed') AND :NEW.resolved_at IS NULL THEN
        :NEW.resolved_at := SYSTIMESTAMP;
    END IF;

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
        :OLD.complaint_id,
        :OLD.status,
        :NEW.status,
        NULL,
        SYSTIMESTAMP,
        'Status updated via complaint record'
    );
END;
/

-- Log initial status when a new complaint is submitted
CREATE OR REPLACE TRIGGER trg_complaints_initial_status_log
AFTER INSERT ON complaints
FOR EACH ROW
BEGIN
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
        :NEW.complaint_id,
        NULL,
        :NEW.status,
        :NEW.student_id,
        :NEW.created_at,
        'Complaint submitted'
    );
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 3: Mark worker unavailable when a new assignment is created
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_assignments_worker_busy
AFTER INSERT ON assignments
FOR EACH ROW
BEGIN
    UPDATE workers
    SET is_available = 'N'
    WHERE worker_id = :NEW.worker_id;
END;
/

-- Mark worker available again when assignment is completed
-- (only if no other open assignments remain)
CREATE OR REPLACE TRIGGER trg_assignments_worker_free
AFTER UPDATE OF completed_at ON assignments
FOR EACH ROW
WHEN (NEW.completed_at IS NOT NULL AND OLD.completed_at IS NULL)
DECLARE
    v_open_assignments NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_open_assignments
    FROM assignments
    WHERE worker_id = :NEW.worker_id
      AND completed_at IS NULL;

    IF v_open_assignments = 0 THEN
        UPDATE workers
        SET is_available = 'Y'
        WHERE worker_id = :NEW.worker_id;
    END IF;
END;
/

-- ----------------------------------------------------------------------------
PROMPT Triggers created: SLA deadline, status audit log, worker availability

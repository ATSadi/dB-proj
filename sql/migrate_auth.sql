-- Add password and reset-token fields to an existing project database.
-- Safe to rerun. Run as CAMPUS_USER.

DECLARE
    PROCEDURE add_column_if_missing(p_name VARCHAR2, p_definition VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM user_tab_columns
        WHERE table_name = 'USERS' AND column_name = UPPER(p_name);

        IF v_count = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE users ADD (' || p_definition || ')';
        END IF;
    END;
BEGIN
    add_column_if_missing('password_hash', 'password_hash VARCHAR2(255)');
    add_column_if_missing('reset_token_hash', 'reset_token_hash VARCHAR2(64)');
    add_column_if_missing('reset_token_expires', 'reset_token_expires TIMESTAMP');
    add_column_if_missing('password_changed_at', 'password_changed_at TIMESTAMP DEFAULT SYSTIMESTAMP');
END;
/

-- All demo accounts initially use: Password123
UPDATE users
SET password_hash = 'scrypt$8a43a919685c40fea1d52d7693b63799$3936a5f85386eb00a1fa13b62c5035c1ac6349e3a18ae8f234a91573437592336978b651af3dcb9a9cd58b5bf74f1b3f6219308e96d73d793d0894ac7c3deb81',
    reset_token_hash = NULL,
    reset_token_expires = NULL,
    password_changed_at = SYSTIMESTAMP;

COMMIT;

PROMPT Authentication columns ready. Default demo password: Password123

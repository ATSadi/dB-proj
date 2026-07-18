require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const crypto = require('crypto');
const oracledb = require('oracledb');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const sessions = new Map();
const SESSION_TTL_MS = 8 * 60 * 60 * 1000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function mapRow(row) {
    const out = {};
    for (const [key, value] of Object.entries(row)) {
        out[key.toLowerCase()] = value instanceof Date ? value.toISOString() : value;
    }
    return out;
}

function mapRows(rows) {
    return (rows || []).map(mapRow);
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
    const hash = crypto.scryptSync(password, salt, 64).toString('hex');
    return `scrypt$${salt}$${hash}`;
}

function verifyPassword(password, encodedHash) {
    try {
        const [algorithm, salt, storedHex] = String(encodedHash || '').split('$');
        if (algorithm !== 'scrypt' || !salt || !storedHex) return false;
        const actual = crypto.scryptSync(password, salt, 64);
        const expected = Buffer.from(storedHex, 'hex');
        return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
    } catch (_err) {
        return false;
    }
}

function validateNewPassword(value) {
    const password = String(value || '');
    if (password.length < 8 || password.length > 128) {
        throw new Error('Password must be between 8 and 128 characters');
    }
    if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) {
        throw new Error('Password must contain at least one letter and one number');
    }
    return password;
}

function tokenHash(code) {
    return crypto.createHash('sha256').update(String(code)).digest('hex');
}

function createSession(user) {
    const token = crypto.randomBytes(32).toString('hex');
    sessions.set(token, {
        user_id: user.user_id,
        role: user.role,
        expires_at: Date.now() + SESSION_TTL_MS
    });
    return token;
}

function getSession(req) {
    const authorization = req.get('Authorization') || '';
    const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
    const session = sessions.get(token);
    if (!session) return null;
    if (session.expires_at <= Date.now()) {
        sessions.delete(token);
        return null;
    }
    return session;
}

function requireAdmin(req, res, next) {
    const session = getSession(req);
    if (!session) {
        return res.status(401).json({ error: 'Please sign in again' });
    }
    if (session.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    req.session = session;
    next();
}

function requiredText(value, field, maxLength) {
    const text = String(value || '').trim();
    if (!text) throw new Error(`${field} is required`);
    if (text.length > maxLength) throw new Error(`${field} must be ${maxLength} characters or fewer`);
    return text;
}

function validEmail(value) {
    const email = requiredText(value, 'Email', 100).toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new Error('Enter a valid email address');
    }
    return email;
}

function sendDbError(res, err) {
    if (err.errorNum === 1 || String(err.message).includes('ORA-00001')) {
        return res.status(409).json({ error: 'Email, roll number, or location already exists' });
    }
    if (String(err.message).includes('ORA-02290')) {
        return res.status(400).json({ error: 'A value does not match the allowed options' });
    }
    return res.status(500).json({ error: err.message });
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const result = await db.execute(
            `SELECT user_id, name, roll_no, email, role, password_hash
             FROM users
             WHERE LOWER(email) = LOWER(:email)`,
            { email }
        );

        if (!result.rows.length) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const row = mapRow(result.rows[0]);
        if (!verifyPassword(password, row.password_hash)) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const { password_hash: _passwordHash, ...user } = row;

        if (user.role === 'worker') {
            const workerResult = await db.execute(
                `SELECT worker_id, specialization, performance_score, is_available
                 FROM workers WHERE user_id = :userId`,
                { userId: user.user_id }
            );
            if (workerResult.rows.length) {
                user.worker = mapRow(workerResult.rows[0]);
            }
        }

        res.json({ user, token: createSession(user) });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/forgot-password', async (req, res) => {
    const genericMessage = 'If that account exists, a reset code has been generated.';
    try {
        const email = validEmail(req.body.email);
        const result = await db.execute(
            `SELECT user_id FROM users WHERE LOWER(email) = LOWER(:email)`,
            { email }
        );

        if (!result.rows.length) {
            return res.json({ message: genericMessage });
        }

        const code = String(crypto.randomInt(100000, 1000000));
        await db.execute(
            `UPDATE users
             SET reset_token_hash = :resetHash,
                 reset_token_expires = SYSTIMESTAMP + NUMTODSINTERVAL(10, 'MINUTE')
             WHERE user_id = :userId`,
            {
                resetHash: tokenHash(code),
                userId: result.rows[0].USER_ID
            }
        );

        const response = { message: genericMessage, expires_in_minutes: 10 };
        if (process.env.DEMO_MODE === 'true') {
            response.demo_code = code;
        } else {
            console.log(`Password reset code for ${email}: ${code}`);
        }
        res.json(response);
    } catch (err) {
        if (!err.errorNum && !String(err.message).startsWith('ORA-')) {
            return res.status(400).json({ error: err.message });
        }
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/reset-password', async (req, res) => {
    try {
        const email = validEmail(req.body.email);
        const code = requiredText(req.body.code, 'Reset code', 6);
        if (!/^\d{6}$/.test(code)) throw new Error('Reset code must be 6 digits');
        const password = validateNewPassword(req.body.new_password);
        const resetHash = tokenHash(code);

        const result = await db.execute(
            `SELECT user_id
             FROM users
             WHERE LOWER(email) = LOWER(:email)
               AND reset_token_hash = :resetHash
               AND reset_token_expires > SYSTIMESTAMP`,
            { email, resetHash }
        );

        if (!result.rows.length) {
            return res.status(400).json({ error: 'Reset code is invalid or expired' });
        }

        await db.execute(
            `UPDATE users
             SET password_hash = :passwordHash,
                 reset_token_hash = NULL,
                 reset_token_expires = NULL,
                 password_changed_at = SYSTIMESTAMP
             WHERE user_id = :userId`,
            {
                passwordHash: hashPassword(password),
                userId: result.rows[0].USER_ID
            }
        );

        res.json({ success: true, message: 'Password updated. You can now sign in.' });
    } catch (err) {
        if (!err.errorNum && !String(err.message).startsWith('ORA-')) {
            return res.status(400).json({ error: err.message });
        }
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Locations
// ---------------------------------------------------------------------------
app.get('/api/locations', async (_req, res) => {
    try {
        const result = await db.execute(
            `SELECT location_id, building, floor, room_no, location_type
             FROM locations
             ORDER BY building, floor, room_no`
        );
        res.json(mapRows(result.rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Admin directory management
// ---------------------------------------------------------------------------
app.get('/api/admin/directory', requireAdmin, async (_req, res) => {
    try {
        const [students, workers, locations] = await Promise.all([
            db.execute(
                `SELECT user_id, name, roll_no, email
                 FROM users WHERE role = 'student'
                 ORDER BY name`
            ),
            db.execute(
                `SELECT w.worker_id, w.user_id, u.name, u.roll_no, u.email,
                        w.specialization, w.performance_score, w.is_available
                 FROM workers w
                 JOIN users u ON u.user_id = w.user_id
                 ORDER BY u.name`
            ),
            db.execute(
                `SELECT location_id, building, floor, room_no, location_type
                 FROM locations
                 ORDER BY building, floor, room_no`
            )
        ]);

        res.json({
            students: mapRows(students.rows),
            workers: mapRows(workers.rows),
            locations: mapRows(locations.rows)
        });
    } catch (err) {
        sendDbError(res, err);
    }
});

app.post('/api/admin/students', requireAdmin, async (req, res) => {
    try {
        const name = requiredText(req.body.name, 'Name', 100);
        const rollNo = requiredText(req.body.roll_no, 'Roll number', 20).toUpperCase();
        const email = validEmail(req.body.email);
        const passwordHash = hashPassword('Password123');

        const result = await db.execute(
            `INSERT INTO users (user_id, name, roll_no, email, role, password_hash)
             VALUES (seq_user_id.NEXTVAL, :name, :rollNo, :email, 'student', :passwordHash)
             RETURNING user_id INTO :userId`,
            {
                name,
                rollNo,
                email,
                passwordHash,
                userId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({ user_id: result.outBinds.userId[0], name, roll_no: rollNo, email });
    } catch (err) {
        if (!err.errorNum && !String(err.message).startsWith('ORA-')) {
            return res.status(400).json({ error: err.message });
        }
        sendDbError(res, err);
    }
});

app.post('/api/admin/students/bulk', requireAdmin, async (req, res) => {
    const rows = Array.isArray(req.body.students) ? req.body.students : [];
    if (!rows.length) {
        return res.status(400).json({ error: 'No student rows supplied' });
    }
    if (rows.length > 2000) {
        return res.status(400).json({ error: 'Import is limited to 2,000 students at a time' });
    }

    const summary = { total: rows.length, inserted: 0, failed: 0, errors: [] };
    const defaultPasswordHash = hashPassword('Password123');
    for (let index = 0; index < rows.length; index += 1) {
        try {
            const name = requiredText(rows[index].name, 'Name', 100);
            const rollNo = requiredText(rows[index].roll_no, 'Roll number', 20).toUpperCase();
            const email = validEmail(rows[index].email);

            await db.execute(
                `INSERT INTO users (user_id, name, roll_no, email, role, password_hash)
                 VALUES (seq_user_id.NEXTVAL, :name, :rollNo, :email, 'student', :passwordHash)`,
                { name, rollNo, email, passwordHash: defaultPasswordHash }
            );
            summary.inserted += 1;
        } catch (err) {
            summary.failed += 1;
            summary.errors.push({
                row: index + 2,
                email: rows[index].email || '',
                error: (err.errorNum === 1 || String(err.message).includes('ORA-00001'))
                    ? 'Duplicate email or roll number'
                    : err.message
            });
        }
    }

    res.status(summary.inserted ? 201 : 400).json(summary);
});

app.post('/api/admin/locations', requireAdmin, async (req, res) => {
    try {
        const building = requiredText(req.body.building, 'Building', 50);
        const floor = requiredText(req.body.floor, 'Floor', 10);
        const roomNo = requiredText(req.body.room_no, 'Room number', 20);
        const locationType = requiredText(req.body.location_type, 'Location type', 30).toLowerCase();
        const allowed = ['classroom', 'lab', 'hostel', 'office', 'washroom', 'corridor'];
        if (!allowed.includes(locationType)) throw new Error('Invalid location type');

        const result = await db.execute(
            `INSERT INTO locations (location_id, building, floor, room_no, location_type)
             VALUES (seq_location_id.NEXTVAL, :building, :floor, :roomNo, :locationType)
             RETURNING location_id INTO :locationId`,
            {
                building,
                floor,
                roomNo,
                locationType,
                locationId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({ location_id: result.outBinds.locationId[0] });
    } catch (err) {
        if (!err.errorNum && !String(err.message).startsWith('ORA-')) {
            return res.status(400).json({ error: err.message });
        }
        sendDbError(res, err);
    }
});

app.post('/api/admin/workers', requireAdmin, async (req, res) => {
    try {
        const name = requiredText(req.body.name, 'Name', 100);
        const rollNo = requiredText(req.body.roll_no, 'Worker ID', 20).toUpperCase();
        const email = validEmail(req.body.email);
        const specialization = requiredText(req.body.specialization, 'Specialization', 50).toLowerCase();
        const passwordHash = hashPassword('Password123');
        const allowed = ['electrical', 'plumbing', 'furniture', 'it', 'cleaning', 'other'];
        if (!allowed.includes(specialization)) throw new Error('Invalid specialization');

        const result = await db.execute(
            `DECLARE
                 v_user_id NUMBER;
                 v_worker_id NUMBER;
             BEGIN
                 SELECT seq_user_id.NEXTVAL INTO v_user_id FROM dual;
                 SELECT seq_worker_id.NEXTVAL INTO v_worker_id FROM dual;
                 INSERT INTO users (user_id, name, roll_no, email, role, password_hash)
                 VALUES (v_user_id, :name, :rollNo, :email, 'worker', :passwordHash);
                 INSERT INTO workers (
                     worker_id, user_id, specialization, performance_score, is_available
                 ) VALUES (
                     v_worker_id, v_user_id, :specialization, 0, 'Y'
                 );
                 :userId := v_user_id;
                 :workerId := v_worker_id;
             END;`,
            {
                name,
                rollNo,
                email,
                specialization,
                passwordHash,
                userId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
                workerId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({
            user_id: result.outBinds.userId,
            worker_id: result.outBinds.workerId
        });
    } catch (err) {
        if (!err.errorNum && !String(err.message).startsWith('ORA-')) {
            return res.status(400).json({ error: err.message });
        }
        sendDbError(res, err);
    }
});

// ---------------------------------------------------------------------------
// Complaints
// ---------------------------------------------------------------------------
app.get('/api/complaints', async (req, res) => {
    try {
        const { student_id, worker_id, status } = req.query;
        let sql = `
            SELECT c.complaint_id, c.student_id, c.location_id, c.category, c.priority,
                   c.description, c.status, c.created_at, c.sla_deadline, c.resolved_at,
                   s.name AS student_name,
                   l.building, l.floor, l.room_no,
                   u.name AS worker_name
            FROM complaints c
            JOIN users s ON s.user_id = c.student_id
            JOIN locations l ON l.location_id = c.location_id
            LEFT JOIN assignments a ON a.complaint_id = c.complaint_id AND a.completed_at IS NULL
            LEFT JOIN workers w ON w.worker_id = a.worker_id
            LEFT JOIN users u ON u.user_id = w.user_id
            WHERE 1=1`;
        const binds = {};

        if (student_id) {
            sql += ' AND c.student_id = :studentId';
            binds.studentId = Number(student_id);
        }
        if (worker_id) {
            sql += ' AND a.worker_id = :workerId';
            binds.workerId = Number(worker_id);
        }
        if (status) {
            sql += ' AND c.status = :status';
            binds.status = status;
        }

        sql += ' ORDER BY c.created_at DESC';

        const result = await db.execute(sql, binds);
        res.json(mapRows(result.rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/complaints', async (req, res) => {
    try {
        const { student_id, location_id, category, priority, description } = req.body;

        const result = await db.execute(
            `INSERT INTO complaints (
                complaint_id, student_id, location_id, category, priority, description
             ) VALUES (
                seq_complaint_id.NEXTVAL, :studentId, :locationId, :category, :priority, :description
             ) RETURNING complaint_id INTO :complaintId`,
            {
                studentId: Number(student_id),
                locationId: Number(location_id),
                category,
                priority,
                description,
                complaintId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
            }
        );

        res.status(201).json({ complaint_id: result.outBinds.complaintId[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.patch('/api/complaints/:id/status', async (req, res) => {
    try {
        const { status } = req.body;
        const complaintId = Number(req.params.id);

        await db.execute(
            `UPDATE complaints SET status = :status WHERE complaint_id = :complaintId`,
            { status, complaintId }
        );

        if (status === 'in_progress') {
            await db.execute(
                `UPDATE assignments SET started_at = SYSTIMESTAMP
                 WHERE complaint_id = :complaintId AND started_at IS NULL`,
                { complaintId }
            );
        }

        if (status === 'resolved') {
            await db.execute(
                `UPDATE assignments SET completed_at = SYSTIMESTAMP
                 WHERE complaint_id = :complaintId AND completed_at IS NULL`,
                { complaintId }
            );
        }

        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Workers & assignments
// ---------------------------------------------------------------------------
app.get('/api/workers', async (_req, res) => {
    try {
        const result = await db.execute(
            `SELECT w.worker_id, w.user_id, w.specialization, w.performance_score,
                    w.is_available, u.name, u.email
             FROM workers w
             JOIN users u ON u.user_id = w.user_id
             ORDER BY u.name`
        );
        res.json(mapRows(result.rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.patch('/api/workers/:id/availability', async (req, res) => {
    try {
        const workerId = Number(req.params.id);
        const { is_available } = req.body;
        if (!['Y', 'N'].includes(is_available)) {
            return res.status(400).json({ error: 'is_available must be Y or N' });
        }

        await db.execute(
            `UPDATE workers SET is_available = :isAvailable WHERE worker_id = :workerId`,
            { isAvailable: is_available, workerId }
        );

        res.json({ success: true, is_available });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/complaints/:id/status-log', async (req, res) => {
    try {
        const complaintId = Number(req.params.id);
        const result = await db.execute(
            `SELECT l.log_id, l.complaint_id, l.old_status, l.new_status, l.changed_at,
                    u.name AS changed_by_name
             FROM status_log l
             LEFT JOIN users u ON u.user_id = l.changed_by
             WHERE l.complaint_id = :complaintId
             ORDER BY l.changed_at ASC`,
            { complaintId }
        );
        res.json(mapRows(result.rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/assignments', async (req, res) => {
    try {
        const { complaint_id, worker_id, supervisor_id } = req.body;

        await db.execute(
            `BEGIN assign_worker(:complaintId, :workerId, :supervisorId); END;`,
            {
                complaintId: Number(complaint_id),
                workerId: Number(worker_id),
                supervisorId: Number(supervisor_id)
            },
            { autoCommit: true }
        );

        res.status(201).json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Feedback
// ---------------------------------------------------------------------------
app.post('/api/feedback', async (req, res) => {
    try {
        const { complaint_id, student_id, rating, comment } = req.body;

        await db.execute(
            `INSERT INTO feedback (
                feedback_id, complaint_id, student_id, rating, feedback_comment
             ) VALUES (
                seq_feedback_id.NEXTVAL, :complaintId, :studentId, :rating, :feedbackComment
             )`,
            {
                complaintId: Number(complaint_id),
                studentId: Number(student_id),
                rating: Number(rating),
                feedbackComment: comment || null
            }
        );

        await db.execute(
            `UPDATE complaints SET status = 'closed' WHERE complaint_id = :complaintId`,
            { complaintId: Number(complaint_id) }
        );

        res.status(201).json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Admin dashboard
// ---------------------------------------------------------------------------
app.get('/api/dashboard', async (_req, res) => {
    try {
        const [overdue, workers, chronic, summary] = await Promise.all([
            db.execute(`SELECT * FROM overdue_complaints_view FETCH FIRST 10 ROWS ONLY`),
            db.execute(`SELECT * FROM worker_performance_view ORDER BY overdue_count DESC`),
            db.execute(`SELECT * FROM chronic_issues_view`),
            db.execute(
                `SELECT category, COUNT(*) AS cnt
                 FROM complaints
                 WHERE EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM SYSDATE)
                   AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM SYSDATE)
                 GROUP BY category
                 ORDER BY cnt DESC
                 FETCH FIRST 5 ROWS ONLY`
            )
        ]);

        res.json({
            overdue: mapRows(overdue.rows),
            workers: mapRows(workers.rows),
            chronic: mapRows(chronic.rows),
            topCategories: mapRows(summary.rows)
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reports', async (_req, res) => {
    try {
        const result = await db.execute(
            `SELECT report_id, month, year, generated_at, total_complaints,
                    resolved_count, avg_resolution_hrs, total_cost
             FROM maintenance_reports
             ORDER BY year DESC, month DESC`
        );
        res.json(mapRows(result.rows));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/reports/generate', async (req, res) => {
    try {
        const { month, year } = req.body;
        await db.execute(
            `BEGIN generate_monthly_report(:month, :year); END;`,
            { month: Number(month), year: Number(year) },
            { autoCommit: true }
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Health check
// ---------------------------------------------------------------------------
app.get('/api/health', async (_req, res) => {
    try {
        await db.execute('SELECT 1 FROM dual');
        res.json({ status: 'ok', database: 'connected' });
    } catch (err) {
        res.status(503).json({ status: 'error', database: err.message });
    }
});

app.get('*', (_req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

async function start() {
    try {
        await db.initPool();
        console.log('Oracle connection pool ready');
        app.listen(PORT, () => {
            console.log(`Server running at http://localhost:${PORT}`);
        });
    } catch (err) {
        console.error('Failed to start server:', err.message);
        console.error('Check your .env file (copy from .env.example)');
        process.exit(1);
    }
}

process.on('SIGINT', async () => {
    await db.closePool();
    process.exit(0);
});

start();

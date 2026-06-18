require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const oracledb = require('oracledb');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

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

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------
app.post('/api/login', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email is required' });
        }

        const result = await db.execute(
            `SELECT user_id, name, roll_no, email, role
             FROM users
             WHERE LOWER(email) = LOWER(:email)`,
            { email }
        );

        if (!result.rows.length) {
            return res.status(401).json({ error: 'User not found' });
        }

        const user = mapRow(result.rows[0]);

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

        res.json({ user });
    } catch (err) {
        console.error('Login error:', err);
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
                feedback_id, complaint_id, student_id, rating, comment
             ) VALUES (
                seq_feedback_id.NEXTVAL, :complaintId, :studentId, :rating, :comment
             )`,
            {
                complaintId: Number(complaint_id),
                studentId: Number(student_id),
                rating: Number(rating),
                comment: comment || null
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

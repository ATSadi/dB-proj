const oracledb = require('oracledb');

let pool;

async function initPool() {
    if (pool) return pool;

    pool = await oracledb.createPool({
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        connectString: process.env.DB_CONNECT_STRING,
        poolMin: 1,
        poolMax: 5,
        poolIncrement: 1
    });

    return pool;
}

async function getConnection() {
    if (!pool) await initPool();
    return pool.getConnection();
}

async function execute(sql, binds = {}, options = {}) {
    let connection;
    try {
        connection = await getConnection();
        const result = await connection.execute(sql, binds, {
            outFormat: oracledb.OUT_FORMAT_OBJECT,
            autoCommit: options.autoCommit !== false,
            ...options
        });
        return result;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection:', err.message);
            }
        }
    }
}

async function closePool() {
    if (pool) {
        await pool.close(0);
        pool = null;
    }
}

module.exports = { initPool, execute, closePool };

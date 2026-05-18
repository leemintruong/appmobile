const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.MYSQLHOST || 'localhost',
  port: Number(process.env.MYSQLPORT || 3306),
  user: process.env.MYSQLUSER || 'root',
  password: process.env.MYSQLPASSWORD || '123456',
  database: process.env.MYSQLDATABASE || 'nutrition_app_v2',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;
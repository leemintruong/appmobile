const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// Routes
app.use('/api/auth',    require('./routes/auth'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/foods',   require('./routes/foods'));
app.use('/api/meals',   require('./routes/meals'));
app.use('/api/weights', require('./routes/weights'));
app.use('/api/reports', require('./routes/reports'));
app.use('/api/water', require('./routes/water'));
app.use('/api/activities', require('./routes/activities'));
app.use('/api/ai', require('./routes/ai'));
app.use('/api/suggestions', require('./routes/suggestions'));
app.use('/api/ai-coach', require('./routes/ai_coach'));

// Health check
app.get('/', (req, res) => res.json({ status: 'ok', message: 'Nutrition API running' }));
const db = require('./config/db');

app.get('/api/debug/db', async (req, res) => {
  try {
    const [[databaseRow]] = await db.query('SELECT DATABASE() AS current_database');
    const [usersTable] = await db.query("SHOW TABLES LIKE 'users'");
    const [allTables] = await db.query('SHOW TABLES');

    res.json({
      success: true,
      current_database: databaseRow.current_database,
      has_users_table: usersTable.length > 0,
      tables_count: allTables.length,
      tables: allTables,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});
// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Lỗi server', error: err.message });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running on port ${PORT}`);
});
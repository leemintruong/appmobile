const router = require('express').Router();
const db     = require('../config/db');
const auth   = require('../middleware/auth');

// GET /api/reports/daily?date=2026-05-10
router.get('/daily', auth, async (req, res) => {
  const date = req.query.date || new Date().toISOString().slice(0, 10);
  const uid  = req.user.id;

  const [nutrition] = await db.query(
    'SELECT * FROM v_daily_nutrition WHERE user_id = ? AND log_date = ?',
    [uid, date]
  );
  const [meals] = await db.query(
    'SELECT * FROM v_meal_summary WHERE user_id = ? AND log_date = ?',
    [uid, date]
  );
  const [goal] = await db.query(
    `SELECT daily_calorie_goal, daily_protein_goal,
            daily_carbs_goal,   daily_fat_goal
     FROM goals WHERE user_id = ? ORDER BY created_at DESC LIMIT 1`,
    [uid]
  );

  res.json({
    date,
    nutrition: nutrition[0] || null,
    meals,
    goal: goal[0] || null
  });
});

// GET /api/reports/weekly?start=2026-05-04
router.get('/weekly', auth, async (req, res) => {
  const start = req.query.start ||
    new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);
  const end   = req.query.end   ||
    new Date().toISOString().slice(0, 10);

  const [rows] = await db.query(
    `SELECT * FROM v_daily_nutrition
     WHERE user_id = ? AND log_date BETWEEN ? AND ?
     ORDER BY log_date`,
    [req.user.id, start, end]
  );

  const avg = rows.length ? {
    avg_calories: Math.round(rows.reduce((s,r) => s + r.total_calories, 0) / rows.length),
    avg_protein:  Math.round(rows.reduce((s,r) => s + r.total_protein,  0) / rows.length),
    avg_carbs:    Math.round(rows.reduce((s,r) => s + r.total_carbs,    0) / rows.length),
    avg_fat:      Math.round(rows.reduce((s,r) => s + r.total_fat,      0) / rows.length),
  } : null;

  res.json({ start, end, days: rows, average: avg });
});

// GET /api/reports/monthly?month=2026-05
router.get('/monthly', auth, async (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);
  const start = `${month}-01`;
  const end   = new Date(
    new Date(start).getFullYear(),
    new Date(start).getMonth() + 1, 0
  ).toISOString().slice(0, 10);

  const [nutrition] = await db.query(
    `SELECT * FROM v_daily_nutrition
     WHERE user_id = ? AND log_date BETWEEN ? AND ?
     ORDER BY log_date`,
    [req.user.id, start, end]
  );
  const [weights] = await db.query(
    `SELECT weight, log_date FROM weight_logs
     WHERE user_id = ? AND log_date BETWEEN ? AND ?
     ORDER BY log_date`,
    [req.user.id, start, end]
  );

  res.json({ month, nutrition, weights });
});

module.exports = router;
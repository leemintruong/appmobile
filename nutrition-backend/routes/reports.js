const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// GET /api/reports/daily?date=2026-05-10
router.get('/daily', auth, async (req, res) => {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const uid = req.user.id;

    const [nutrition] = await db.query(
      'SELECT * FROM v_daily_nutrition WHERE user_id = ? AND log_date = ?',
      [uid, date]
    );

    const [meals] = await db.query(
      'SELECT * FROM v_meal_summary WHERE user_id = ? AND log_date = ?',
      [uid, date]
    );

    const [goal] = await db.query(
      `SELECT 
          daily_calorie_goal,
          daily_protein_goal,
          daily_carbs_goal,
          daily_fat_goal
       FROM goals 
       WHERE user_id = ? 
       ORDER BY created_at DESC 
       LIMIT 1`,
      [uid]
    );

    const n = nutrition[0] || {};
    const g = goal[0] || {};

    return res.json({
      success: true,
      date,

      // Flat fields để Flutter HomeScreen đọc trực tiếp
      total_calories: Number(n.total_calories || 0),
      total_protein: Number(n.total_protein || 0),
      total_carbs: Number(n.total_carbs || 0),
      total_fat: Number(n.total_fat || 0),

      daily_calorie_goal: Number(g.daily_calorie_goal || 0),
      daily_protein_goal: Number(g.daily_protein_goal || 0),
      daily_carbs_goal: Number(g.daily_carbs_goal || 0),
      daily_fat_goal: Number(g.daily_fat_goal || 0),

      // Giữ lại dạng chi tiết nếu màn report cần
      nutrition: n,
      meals,
      goal: g,
    });
  } catch (err) {
    console.error('DAILY REPORT ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo ngày',
      error: err.message,
    });
  }
});

// GET /api/reports/weekly?start=2026-05-04
router.get('/weekly', auth, async (req, res) => {
  try {
    const start =
      req.query.start ||
      new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);

    const end =
      req.query.end ||
      new Date().toISOString().slice(0, 10);

    const [rows] = await db.query(
      `SELECT * 
       FROM v_daily_nutrition
       WHERE user_id = ? 
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const average = rows.length
      ? {
          avg_calories: Math.round(
            rows.reduce((sum, r) => sum + Number(r.total_calories || 0), 0) /
              rows.length
          ),
          avg_protein: Math.round(
            rows.reduce((sum, r) => sum + Number(r.total_protein || 0), 0) /
              rows.length
          ),
          avg_carbs: Math.round(
            rows.reduce((sum, r) => sum + Number(r.total_carbs || 0), 0) /
              rows.length
          ),
          avg_fat: Math.round(
            rows.reduce((sum, r) => sum + Number(r.total_fat || 0), 0) /
              rows.length
          ),
        }
      : {
          avg_calories: 0,
          avg_protein: 0,
          avg_carbs: 0,
          avg_fat: 0,
        };

    return res.json({
      success: true,
      start,
      end,
      days: rows,
      average,

      // Flat field tiện cho Flutter
      avg_calories: average.avg_calories,
      avg_protein: average.avg_protein,
      avg_carbs: average.avg_carbs,
      avg_fat: average.avg_fat,
    });
  } catch (err) {
    console.error('WEEKLY REPORT ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo tuần',
      error: err.message,
    });
  }
});

// GET /api/reports/monthly?month=2026-05
router.get('/monthly', auth, async (req, res) => {
  try {
    const month = req.query.month || new Date().toISOString().slice(0, 7);

    const start = `${month}-01`;

    const end = new Date(
      new Date(start).getFullYear(),
      new Date(start).getMonth() + 1,
      0
    )
      .toISOString()
      .slice(0, 10);

    const [nutrition] = await db.query(
      `SELECT * 
       FROM v_daily_nutrition
       WHERE user_id = ? 
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [weights] = await db.query(
      `SELECT weight, log_date 
       FROM weight_logs
       WHERE user_id = ? 
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    return res.json({
      success: true,
      month,
      start,
      end,
      nutrition,
      weights,
    });
  } catch (err) {
    console.error('MONTHLY REPORT ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo tháng',
      error: err.message,
    });
  }
});

module.exports = router;
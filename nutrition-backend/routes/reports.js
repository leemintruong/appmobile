const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function today() {
  return new Date().toISOString().slice(0, 10);
}

function toNumber(v) {
  return Number(v || 0);
}

// GET /api/reports/daily?date=2026-05-10
router.get('/daily', auth, async (req, res) => {
  try {
    const date = req.query.date || today();
    const uid = req.user.id;

    const [[nutrition = {}]] = await db.query(
      'SELECT * FROM v_daily_nutrition WHERE user_id = ? AND log_date = ? LIMIT 1',
      [uid, date]
    );

    const [meals] = await db.query(
      `SELECT * FROM v_meal_summary
       WHERE user_id = ? AND log_date = ?
       ORDER BY FIELD(meal_type, 'breakfast', 'lunch', 'dinner', 'snack')`,
      [uid, date]
    );

    const [[goal = {}]] = await db.query(
      `SELECT daily_calorie_goal, daily_protein_goal, daily_carbs_goal,
              daily_fat_goal, daily_water_goal_ml
       FROM goals
       WHERE user_id = ? AND is_active = 1
       ORDER BY created_at DESC LIMIT 1`,
      [uid]
    );

    const [[water = {}]] = await db.query(
      `SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml
       FROM water_logs WHERE user_id = ? AND log_date = ?`,
      [uid, date]
    );

    const [[activity = {}]] = await db.query(
      `SELECT COALESCE(SUM(calories_burned), 0) AS total_calories_burned,
              COALESCE(SUM(duration_minutes), 0) AS total_activity_minutes
       FROM activity_logs WHERE user_id = ? AND log_date = ?`,
      [uid, date]
    );

    const [[weight = {}]] = await db.query(
      `SELECT weight_kg, log_date
       FROM weight_logs
       WHERE user_id = ? AND log_date <= ?
       ORDER BY log_date DESC LIMIT 1`,
      [uid, date]
    );

    return res.json({
      success: true,
      date,
      total_calories: toNumber(nutrition.total_calories),
      total_protein: toNumber(nutrition.total_protein),
      total_carbs: toNumber(nutrition.total_carbs),
      total_fat: toNumber(nutrition.total_fat),
      daily_calorie_goal: toNumber(goal.daily_calorie_goal),
      daily_protein_goal: toNumber(goal.daily_protein_goal),
      daily_carbs_goal: toNumber(goal.daily_carbs_goal),
      daily_fat_goal: toNumber(goal.daily_fat_goal),
      daily_water_goal_ml: toNumber(goal.daily_water_goal_ml),
      total_water_ml: toNumber(water.total_water_ml),
      total_calories_burned: toNumber(activity.total_calories_burned),
      total_activity_minutes: toNumber(activity.total_activity_minutes),
      current_weight_kg: weight.weight_kg ? Number(weight.weight_kg) : null,
      current_weight_date: weight.log_date || null,
      nutrition,
      meals,
      goal,
    });
  } catch (err) {
    console.error('DAILY REPORT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy báo cáo ngày' });
  }
});

// GET /api/reports/weekly?start=2026-05-04&end=2026-05-10
router.get('/weekly', auth, async (req, res) => {
  try {
    const end = req.query.end || today();
    const start = req.query.start || new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);

    const [nutritionRows] = await db.query(
      `SELECT * FROM v_daily_nutrition
       WHERE user_id = ? AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [waterRows] = await db.query(
      `SELECT log_date, SUM(amount_ml) AS total_water_ml
       FROM water_logs
       WHERE user_id = ? AND log_date BETWEEN ? AND ?
       GROUP BY log_date ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [activityRows] = await db.query(
      `SELECT log_date, SUM(duration_minutes) AS total_activity_minutes,
              SUM(calories_burned) AS total_calories_burned
       FROM activity_logs
       WHERE user_id = ? AND log_date BETWEEN ? AND ?
       GROUP BY log_date ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const average = nutritionRows.length
      ? {
          avg_calories: Math.round(nutritionRows.reduce((sum, r) => sum + Number(r.total_calories || 0), 0) / nutritionRows.length),
          avg_protein: Math.round(nutritionRows.reduce((sum, r) => sum + Number(r.total_protein || 0), 0) / nutritionRows.length),
          avg_carbs: Math.round(nutritionRows.reduce((sum, r) => sum + Number(r.total_carbs || 0), 0) / nutritionRows.length),
          avg_fat: Math.round(nutritionRows.reduce((sum, r) => sum + Number(r.total_fat || 0), 0) / nutritionRows.length),
        }
      : { avg_calories: 0, avg_protein: 0, avg_carbs: 0, avg_fat: 0 };

    return res.json({
      success: true,
      start,
      end,
      days: nutritionRows,
      water: waterRows,
      activities: activityRows,
      average,
      avg_calories: average.avg_calories,
      avg_protein: average.avg_protein,
      avg_carbs: average.avg_carbs,
      avg_fat: average.avg_fat,
    });
  } catch (err) {
    console.error('WEEKLY REPORT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy báo cáo tuần' });
  }
});

// GET /api/reports/monthly?month=2026-05
router.get('/monthly', auth, async (req, res) => {
  try {
    const month = req.query.month || new Date().toISOString().slice(0, 7);
    const start = `${month}-01`;
    const end = new Date(new Date(start).getFullYear(), new Date(start).getMonth() + 1, 0).toISOString().slice(0, 10);

    const [nutrition] = await db.query(
      `SELECT * FROM v_daily_nutrition
       WHERE user_id = ? AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [weights] = await db.query(
      `SELECT weight_kg, log_date, note
       FROM weight_logs
       WHERE user_id = ? AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    return res.json({ success: true, month, start, end, nutrition, weights });
  } catch (err) {
    console.error('MONTHLY REPORT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy báo cáo tháng' });
  }
});

module.exports = router;

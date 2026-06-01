const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function localDateKey(value = new Date()) {
  const d = value instanceof Date ? value : new Date(value);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function today() {
  return localDateKey(new Date());
}

function toNumber(v) {
  return Number(v || 0);
}

async function getDetailedMeals(userId, date) {
  const [rows] = await db.query(
    `SELECT
        ml.id AS meal_log_id,
        ml.meal_type,
        ml.log_date,
        mli.id AS item_id,
        mli.food_id,
        COALESCE(f.name, mli.custom_food_name) AS food_name,
        mli.custom_food_name,
        mli.amount,
        mli.amount_unit,
        mli.total_calories,
        mli.total_protein,
        mli.total_carbs,
        mli.total_fat,
        mli.source
     FROM meal_logs ml
     LEFT JOIN meal_log_items mli ON mli.meal_log_id = ml.id
     LEFT JOIN foods f ON f.id = mli.food_id
     WHERE ml.user_id = ?
       AND ml.log_date = ?
     ORDER BY FIELD(ml.meal_type, 'breakfast', 'lunch', 'dinner', 'snack'), ml.id, mli.id`,
    [userId, date]
  );

  const grouped = {};

  for (const r of rows) {
    if (!grouped[r.meal_type]) {
      grouped[r.meal_type] = {
        meal_log_id: r.meal_log_id,
        meal_type: r.meal_type,
        log_date: r.log_date,
        items: [],
        total_calories: 0,
        total_protein: 0,
        total_carbs: 0,
        total_fat: 0,
      };
    }

    if (!r.item_id) continue;

    const item = {
      item_id: r.item_id,
      food_id: r.food_id,
      food_name: r.food_name,
      custom_food_name: r.custom_food_name,
      amount: Number(r.amount || 0),
      amount_unit: r.amount_unit,
      total_calories: Number(r.total_calories || 0),
      total_protein: Number(r.total_protein || 0),
      total_carbs: Number(r.total_carbs || 0),
      total_fat: Number(r.total_fat || 0),
      source: r.source,
    };

    grouped[r.meal_type].items.push(item);
    grouped[r.meal_type].total_calories += item.total_calories;
    grouped[r.meal_type].total_protein += item.total_protein;
    grouped[r.meal_type].total_carbs += item.total_carbs;
    grouped[r.meal_type].total_fat += item.total_fat;
  }

  return Object.values(grouped).map((meal) => ({
    ...meal,
    item_count: meal.items.length,
    summary_text: meal.items.map((x) => x.food_name).filter(Boolean).join(', '),
    total_calories: Number(meal.total_calories.toFixed(1)),
    total_protein: Number(meal.total_protein.toFixed(1)),
    total_carbs: Number(meal.total_carbs.toFixed(1)),
    total_fat: Number(meal.total_fat.toFixed(1)),
  }));
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

    const meals = await getDetailedMeals(uid, date);

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
      selected_date: date,
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
    const start = req.query.start || localDateKey(new Date(Date.now() - 6 * 86400000));

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
    const month = req.query.month || today().slice(0, 7);
    const start = `${month}-01`;
    const end = localDateKey(new Date(new Date(start).getFullYear(), new Date(start).getMonth() + 1, 0));

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

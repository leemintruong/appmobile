const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const { todayVN, normalizeDate, getLast7DaysRange, getMonthRange, enumerateDates } = require('../utils/date');

function toNumber(v) {
  return Number(v || 0);
}

function round1(n) {
  return Math.round(Number(n || 0) * 10) / 10;
}

function mealLabel(type) {
  const labels = {
    breakfast: 'Sáng',
    lunch: 'Trưa',
    dinner: 'Tối',
    snack: 'Bữa phụ',
  };
  return labels[type] || type;
}

async function getDetailedMeals(userId, date) {
  const [rows] = await db.query(
    `SELECT
        ml.id AS meal_log_id,
        ml.meal_type,
        DATE_FORMAT(ml.log_date, '%Y-%m-%d') AS log_date,
        mli.id AS item_id,
        mli.food_id,
        COALESCE(f.name, mli.custom_food_name) AS food_name,
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

  for (const row of rows) {
    if (!grouped[row.meal_type]) {
      grouped[row.meal_type] = {
        meal_log_id: row.meal_log_id,
        meal_type: row.meal_type,
        meal_label: mealLabel(row.meal_type),
        log_date: row.log_date,
        items: [],
        item_count: 0,
        total_calories: 0,
        total_protein: 0,
        total_carbs: 0,
        total_fat: 0,
        summary_text: '',
      };
    }

    if (!row.item_id) continue;

    const item = {
      item_id: row.item_id,
      food_id: row.food_id,
      food_name: row.food_name,
      name: row.food_name,
      amount: Number(row.amount || 0),
      quantity: Number(row.amount || 0),
      amount_unit: row.amount_unit,
      serving_unit: row.amount_unit,
      total_calories: Number(row.total_calories || 0),
      total_protein: Number(row.total_protein || 0),
      total_carbs: Number(row.total_carbs || 0),
      total_fat: Number(row.total_fat || 0),
      source: row.source || 'manual',
      is_ai: row.source === 'ai',
    };

    grouped[row.meal_type].items.push(item);
    grouped[row.meal_type].item_count += 1;
    grouped[row.meal_type].total_calories += item.total_calories;
    grouped[row.meal_type].total_protein += item.total_protein;
    grouped[row.meal_type].total_carbs += item.total_carbs;
    grouped[row.meal_type].total_fat += item.total_fat;
  }

  return Object.values(grouped).map((meal) => ({
    ...meal,
    total_calories: round1(meal.total_calories),
    total_protein: round1(meal.total_protein),
    total_carbs: round1(meal.total_carbs),
    total_fat: round1(meal.total_fat),
    summary_text: meal.items.map((item) => `${item.food_name} ${item.amount}${item.amount_unit}`).join(' · '),
  }));
}

// GET /api/reports/daily?date=2026-05-10
router.get('/daily', auth, async (req, res) => {
  try {
    const date = normalizeDate(req.query.date);
    const uid = req.user.id;

    const [[nutrition = {}]] = await db.query(
      `SELECT
          user_id,
          DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
          total_calories,
          total_protein,
          total_carbs,
          total_fat
       FROM v_daily_nutrition
       WHERE user_id = ? AND log_date = ?
       LIMIT 1`,
      [uid, date]
    );

    const meals = await getDetailedMeals(uid, date);

    const [[goal = {}]] = await db.query(
      `SELECT daily_calorie_goal, daily_protein_goal, daily_carbs_goal,
              daily_fat_goal, daily_water_goal_ml
       FROM goals
       WHERE user_id = ? AND is_active = 1
       ORDER BY created_at DESC
       LIMIT 1`,
      [uid]
    );

    const [[water = {}]] = await db.query(
      `SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml
       FROM water_logs
       WHERE user_id = ? AND log_date = ?`,
      [uid, date]
    );

    const [[activity = {}]] = await db.query(
      `SELECT COALESCE(SUM(calories_burned), 0) AS total_calories_burned,
              COALESCE(SUM(duration_minutes), 0) AS total_activity_minutes
       FROM activity_logs
       WHERE user_id = ? AND log_date = ?`,
      [uid, date]
    );

    const [[weight = {}]] = await db.query(
      `SELECT weight_kg, DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date
       FROM weight_logs
       WHERE user_id = ? AND log_date <= ?
       ORDER BY log_date DESC
       LIMIT 1`,
      [uid, date]
    );

    const totalCalories = toNumber(nutrition.total_calories);
    const totalProtein = toNumber(nutrition.total_protein);
    const totalCarbs = toNumber(nutrition.total_carbs);
    const totalFat = toNumber(nutrition.total_fat);

    return res.json({
      success: true,
      date,
      total_calories: totalCalories,
      total_protein: totalProtein,
      total_carbs: totalCarbs,
      total_fat: totalFat,
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
      meals,
      meal_count: meals.length,
      item_count: meals.reduce((sum, meal) => sum + Number(meal.item_count || 0), 0),
      nutrition: {
        ...nutrition,
        total_calories: totalCalories,
        total_protein: totalProtein,
        total_carbs: totalCarbs,
        total_fat: totalFat,
      },
      goal,
    });
  } catch (err) {
    console.error('DAILY REPORT ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo ngày',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// GET /api/reports/weekly?start=2026-05-04&end=2026-05-10
router.get('/weekly', auth, async (req, res) => {
  try {
    const range = getLast7DaysRange(req.query.end);
    const start = normalizeDate(req.query.start || range.start);
    const end = normalizeDate(req.query.end || range.end);

    const [nutritionRows] = await db.query(
      `SELECT
          DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
          total_calories,
          total_protein,
          total_carbs,
          total_fat
       FROM v_daily_nutrition
       WHERE user_id = ?
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [waterRows] = await db.query(
      `SELECT DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
              SUM(amount_ml) AS total_water_ml
       FROM water_logs
       WHERE user_id = ?
         AND log_date BETWEEN ? AND ?
       GROUP BY log_date
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [activityRows] = await db.query(
      `SELECT DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
              SUM(duration_minutes) AS total_activity_minutes,
              SUM(calories_burned) AS total_calories_burned
       FROM activity_logs
       WHERE user_id = ?
         AND log_date BETWEEN ? AND ?
       GROUP BY log_date
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const nutritionMap = new Map(nutritionRows.map((row) => [row.log_date, row]));
    const waterMap = new Map(waterRows.map((row) => [row.log_date, row]));
    const activityMap = new Map(activityRows.map((row) => [row.log_date, row]));

    const days = enumerateDates(start, end).map((date) => {
      const n = nutritionMap.get(date) || {};
      const w = waterMap.get(date) || {};
      const a = activityMap.get(date) || {};

      return {
        log_date: date,
        date,
        total_calories: toNumber(n.total_calories),
        total_protein: toNumber(n.total_protein),
        total_carbs: toNumber(n.total_carbs),
        total_fat: toNumber(n.total_fat),
        total_water_ml: toNumber(w.total_water_ml),
        total_activity_minutes: toNumber(a.total_activity_minutes),
        total_calories_burned: toNumber(a.total_calories_burned),
      };
    });

    const average = days.length
      ? {
          avg_calories: Math.round(days.reduce((sum, r) => sum + Number(r.total_calories || 0), 0) / days.length),
          avg_protein: Math.round(days.reduce((sum, r) => sum + Number(r.total_protein || 0), 0) / days.length),
          avg_carbs: Math.round(days.reduce((sum, r) => sum + Number(r.total_carbs || 0), 0) / days.length),
          avg_fat: Math.round(days.reduce((sum, r) => sum + Number(r.total_fat || 0), 0) / days.length),
        }
      : { avg_calories: 0, avg_protein: 0, avg_carbs: 0, avg_fat: 0 };

    return res.json({
      success: true,
      start,
      end,
      days,
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
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo tuần',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// GET /api/reports/monthly?month=2026-05
router.get('/monthly', auth, async (req, res) => {
  try {
    const { month, start, end } = getMonthRange(req.query.month);

    const [nutritionRows] = await db.query(
      `SELECT
          DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
          total_calories,
          total_protein,
          total_carbs,
          total_fat
       FROM v_daily_nutrition
       WHERE user_id = ?
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const [weights] = await db.query(
      `SELECT weight_kg,
              DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date,
              note
       FROM weight_logs
       WHERE user_id = ?
         AND log_date BETWEEN ? AND ?
       ORDER BY log_date`,
      [req.user.id, start, end]
    );

    const nutritionMap = new Map(nutritionRows.map((row) => [row.log_date, row]));
    const days = enumerateDates(start, end).map((date) => {
      const n = nutritionMap.get(date) || {};

      return {
        log_date: date,
        date,
        total_calories: toNumber(n.total_calories),
        total_protein: toNumber(n.total_protein),
        total_carbs: toNumber(n.total_carbs),
        total_fat: toNumber(n.total_fat),
      };
    });

    return res.json({
      success: true,
      month,
      start,
      end,
      days,
      nutrition: days,
      weights,
    });
  } catch (err) {
    console.error('MONTHLY REPORT ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy báo cáo tháng',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

module.exports = router;

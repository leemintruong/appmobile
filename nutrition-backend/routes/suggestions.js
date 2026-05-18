const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// GET /api/suggestions/templates?meal_type=lunch
router.get('/templates', auth, async (req, res) => {
  try {
    const mealType = req.query.meal_type || null;

    const [[goal = {}]] = await db.query(
      `SELECT goal_type FROM goals
       WHERE user_id = ? AND is_active = 1
       ORDER BY created_at DESC
       LIMIT 1`,
      [req.user.id]
    );

    const goalType = goal.goal_type || 'all';

    const params = [goalType];
    let where = `WHERE is_active = 1 AND (goal_type = ? OR goal_type = 'all')`;

    if (mealType) {
      where += ` AND meal_type = ?`;
      params.push(mealType);
    }

    const [templates] = await db.query(
      `SELECT *
       FROM meal_templates
       ${where}
       ORDER BY meal_type, total_calories`,
      params
    );

    return res.json({
      success: true,
      goal_type: goalType,
      templates,
    });
  } catch (err) {
    console.error('GET TEMPLATES ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy gợi ý bữa ăn',
    });
  }
});

// GET /api/suggestions/daily?date=2026-05-10
router.get('/daily', auth, async (req, res) => {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);

    const [[goal = {}]] = await db.query(
      `SELECT * FROM goals
       WHERE user_id = ? AND is_active = 1
       ORDER BY created_at DESC
       LIMIT 1`,
      [req.user.id]
    );

    const [[nutrition = {}]] = await db.query(
      `SELECT * FROM v_daily_nutrition
       WHERE user_id = ? AND log_date = ?
       LIMIT 1`,
      [req.user.id, date]
    );

    const [[water = {}]] = await db.query(
      `SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml
       FROM water_logs
       WHERE user_id = ? AND log_date = ?`,
      [req.user.id, date]
    );

    const suggestions = [];

    const totalCalories = Number(nutrition.total_calories || 0);
    const totalProtein = Number(nutrition.total_protein || 0);
    const dailyCalories = Number(goal.daily_calorie_goal || 0);
    const dailyProtein = Number(goal.daily_protein_goal || 0);
    const totalWater = Number(water.total_water_ml || 0);
    const waterGoal = Number(goal.daily_water_goal_ml || 2000);

    if (dailyProtein && totalProtein < dailyProtein * 0.7) {
      suggestions.push('Bạn đang thiếu protein so với mục tiêu. Có thể bổ sung ức gà, trứng, cá, đậu hũ hoặc sữa chua Hy Lạp.');
    }

    if (goal.goal_type === 'lose_weight' && dailyCalories && totalCalories > dailyCalories) {
      suggestions.push('Bạn đã vượt mục tiêu calo hôm nay. Bữa sau nên chọn rau, protein nạc và giảm đồ chiên/ngọt.');
    }

    if (totalWater < waterGoal * 0.6) {
      suggestions.push('Bạn đang uống ít nước. Hãy thêm 1 ly nước và bật nhắc uống nước.');
    }

    if (!suggestions.length) {
      suggestions.push('Hôm nay dữ liệu đang ổn. Tiếp tục ghi bữa ăn đều để báo cáo chính xác hơn.');
    }

    return res.json({
      success: true,
      date,
      goal_type: goal.goal_type || 'all',
      suggestions,
      summary: {
        total_calories: totalCalories,
        daily_calorie_goal: dailyCalories,
        total_protein: totalProtein,
        daily_protein_goal: dailyProtein,
        total_water_ml: totalWater,
        daily_water_goal_ml: waterGoal,
      },
    });
  } catch (err) {
    console.error('GET DAILY SUGGESTIONS ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy gợi ý dinh dưỡng',
    });
  }
});

module.exports = router;

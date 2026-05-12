const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// GET /api/meals?date=2026-05-10
router.get('/', auth, async (req, res) => {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);

    const [rows] = await db.query(
      `SELECT 
          ml.id AS meal_log_id,
          ml.meal_type,
          f.id AS food_id,
          f.name AS food_name,
          f.serving_unit,
          mli.quantity,
          mli.total_calories,
          mli.total_protein,
          mli.total_carbs,
          mli.total_fat
       FROM meal_logs ml
       JOIN meal_log_items mli ON mli.meal_log_id = ml.id
       JOIN foods f ON f.id = mli.food_id
       WHERE ml.user_id = ? 
         AND ml.log_date = ?
       ORDER BY FIELD(ml.meal_type, 'breakfast', 'lunch', 'dinner', 'snack'), ml.id`,
      [req.user.id, date]
    );

    const grouped = {};
    let total_calories = 0;
    let total_protein = 0;
    let total_carbs = 0;
    let total_fat = 0;

    for (const r of rows) {
      if (!grouped[r.meal_type]) {
        grouped[r.meal_type] = {
          meal_log_id: r.meal_log_id,
          meal_type: r.meal_type,
          items: [],
          total_calories: 0,
          total_protein: 0,
          total_carbs: 0,
          total_fat: 0,
        };
      }

      const item = {
        food_id: r.food_id,
        food_name: r.food_name,
        quantity: Number(r.quantity || 0),
        serving_unit: r.serving_unit,
        total_calories: Number(r.total_calories || 0),
        total_protein: Number(r.total_protein || 0),
        total_carbs: Number(r.total_carbs || 0),
        total_fat: Number(r.total_fat || 0),
      };

      grouped[r.meal_type].items.push(item);

      grouped[r.meal_type].total_calories += item.total_calories;
      grouped[r.meal_type].total_protein += item.total_protein;
      grouped[r.meal_type].total_carbs += item.total_carbs;
      grouped[r.meal_type].total_fat += item.total_fat;

      total_calories += item.total_calories;
      total_protein += item.total_protein;
      total_carbs += item.total_carbs;
      total_fat += item.total_fat;
    }

    return res.json({
      success: true,
      date,
      meals: Object.values(grouped),
      total_calories: Math.round(total_calories * 10) / 10,
      total_protein: Math.round(total_protein * 10) / 10,
      total_carbs: Math.round(total_carbs * 10) / 10,
      total_fat: Math.round(total_fat * 10) / 10,
    });
  } catch (err) {
    console.error('GET MEALS ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy bữa ăn',
      error: err.message,
    });
  }
});

// POST /api/meals
router.post('/', auth, async (req, res) => {
  const { meal_type, date, items } = req.body;

  if (!meal_type || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Thiếu dữ liệu bữa ăn',
    });
  }

  const validMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  if (!validMealTypes.includes(meal_type)) {
    return res.status(400).json({
      success: false,
      message: 'Loại bữa ăn không hợp lệ',
    });
  }

  const log_date = date || new Date().toISOString().slice(0, 10);

  const conn = await db.getConnection();

  try {
    await conn.beginTransaction();

    const [logResult] = await conn.query(
      'INSERT INTO meal_logs (user_id, meal_type, log_date) VALUES (?, ?, ?)',
      [req.user.id, meal_type, log_date]
    );

    const meal_log_id = logResult.insertId;

    let total_calories = 0;
    let total_protein = 0;
    let total_carbs = 0;
    let total_fat = 0;

    for (const item of items) {
      const foodId = Number(item.food_id);
      const quantity = Number(item.quantity);

      if (!foodId || !quantity || quantity <= 0) {
        continue;
      }

      const [foods] = await conn.query(
        'SELECT calories, protein, carbs, fat FROM foods WHERE id = ?',
        [foodId]
      );

      if (!foods.length) {
        continue;
      }

      const f = foods[0];

      const itemCalories = Math.round((Number(f.calories || 0) / 100) * quantity * 10) / 10;
      const itemProtein = Math.round((Number(f.protein || 0) / 100) * quantity * 10) / 10;
      const itemCarbs = Math.round((Number(f.carbs || 0) / 100) * quantity * 10) / 10;
      const itemFat = Math.round((Number(f.fat || 0) / 100) * quantity * 10) / 10;

      await conn.query(
        `INSERT INTO meal_log_items
          (meal_log_id, food_id, quantity, total_calories, total_protein, total_carbs, total_fat)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          meal_log_id,
          foodId,
          quantity,
          itemCalories,
          itemProtein,
          itemCarbs,
          itemFat,
        ]
      );

      total_calories += itemCalories;
      total_protein += itemProtein;
      total_carbs += itemCarbs;
      total_fat += itemFat;
    }

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Lưu bữa ăn thành công',
      meal_log_id,
      date: log_date,
      total_calories: Math.round(total_calories * 10) / 10,
      total_protein: Math.round(total_protein * 10) / 10,
      total_carbs: Math.round(total_carbs * 10) / 10,
      total_fat: Math.round(total_fat * 10) / 10,
    });
  } catch (err) {
    await conn.rollback();

    console.error('ADD MEAL ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lưu bữa ăn',
      error: err.message,
    });
  } finally {
    conn.release();
  }
});

// DELETE /api/meals/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id FROM meal_logs WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bữa ăn',
      });
    }

    await db.query(
      'DELETE FROM meal_logs WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    return res.json({
      success: true,
      message: 'Đã xóa bữa ăn',
    });
  } catch (err) {
    console.error('DELETE MEAL ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa bữa ăn',
      error: err.message,
    });
  }
});

module.exports = router;
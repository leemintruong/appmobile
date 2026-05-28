const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const { todayVN, normalizeDate } = require('../utils/date');

const MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack'];

function round1(n) {
  return Math.round(Number(n || 0) * 10) / 10;
}

function round2(n) {
  return Math.round(Number(n || 0) * 100) / 100;
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

function emptyMealGroup(row) {
  return {
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

function buildMealGroups(rows) {
  const grouped = {};
  let totalCalories = 0;
  let totalProtein = 0;
  let totalCarbs = 0;
  let totalFat = 0;
  let totalItems = 0;

  for (const r of rows) {
    if (!grouped[r.meal_type]) grouped[r.meal_type] = emptyMealGroup(r);

    if (!r.item_id) continue;

    const item = {
      item_id: r.item_id,
      food_id: r.food_id,
      food_name: r.food_name,
      name: r.food_name,
      amount: Number(r.amount || 0),
      quantity: Number(r.amount || 0),
      amount_unit: r.amount_unit,
      serving_unit: r.amount_unit,
      total_calories: Number(r.total_calories || 0),
      total_protein: Number(r.total_protein || 0),
      total_carbs: Number(r.total_carbs || 0),
      total_fat: Number(r.total_fat || 0),
      source: r.source || 'manual',
      is_ai: r.source === 'ai',
    };

    grouped[r.meal_type].items.push(item);
    grouped[r.meal_type].item_count += 1;
    grouped[r.meal_type].total_calories += item.total_calories;
    grouped[r.meal_type].total_protein += item.total_protein;
    grouped[r.meal_type].total_carbs += item.total_carbs;
    grouped[r.meal_type].total_fat += item.total_fat;

    totalCalories += item.total_calories;
    totalProtein += item.total_protein;
    totalCarbs += item.total_carbs;
    totalFat += item.total_fat;
    totalItems += 1;
  }

  const meals = Object.values(grouped).map((meal) => ({
    ...meal,
    total_calories: round1(meal.total_calories),
    total_protein: round1(meal.total_protein),
    total_carbs: round1(meal.total_carbs),
    total_fat: round1(meal.total_fat),
    summary_text: meal.items
      .map((item) => `${item.food_name} ${item.amount}${item.amount_unit}`)
      .join(' · '),
  }));

  return {
    meals,
    total_calories: round1(totalCalories),
    total_protein: round1(totalProtein),
    total_carbs: round1(totalCarbs),
    total_fat: round1(totalFat),
    meal_count: meals.length,
    item_count: totalItems,
  };
}

async function getMealRows(userId, date) {
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

  return rows;
}

// GET /api/meals?date=2026-05-10
router.get('/', auth, async (req, res) => {
  try {
    const date = normalizeDate(req.query.date);
    const rows = await getMealRows(req.user.id, date);
    const summary = buildMealGroups(rows);

    return res.json({
      success: true,
      date,
      ...summary,
    });
  } catch (err) {
    console.error('GET MEALS ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy bữa ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// GET /api/meals/history?from=2026-05-01&to=2026-05-10
router.get('/history', auth, async (req, res) => {
  try {
    const to = normalizeDate(req.query.to);
    const from = normalizeDate(req.query.from || to);

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
         AND ml.log_date BETWEEN ? AND ?
       ORDER BY ml.log_date DESC, FIELD(ml.meal_type, 'breakfast', 'lunch', 'dinner', 'snack'), ml.id, mli.id`,
      [req.user.id, from, to]
    );

    const byDate = {};
    for (const row of rows) {
      if (!byDate[row.log_date]) byDate[row.log_date] = [];
      byDate[row.log_date].push(row);
    }

    const days = Object.entries(byDate).map(([date, dayRows]) => ({
      date,
      ...buildMealGroups(dayRows),
    }));

    return res.json({
      success: true,
      from,
      to,
      days,
    });
  } catch (err) {
    console.error('GET MEAL HISTORY ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy lịch sử bữa ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// POST /api/meals
router.post('/', auth, async (req, res) => {
  const mealType = req.body.meal_type;
  const logDate = normalizeDate(req.body.date);
  const items = Array.isArray(req.body.items) ? req.body.items : [];
  const replace = Boolean(req.body.replace);

  if (!MEAL_TYPES.includes(mealType)) {
    return res.status(400).json({ success: false, message: 'Loại bữa ăn không hợp lệ' });
  }

  if (!items.length) {
    return res.status(400).json({ success: false, message: 'Bữa ăn phải có ít nhất 1 món' });
  }

  const conn = await db.getConnection();

  try {
    await conn.beginTransaction();

    const [logResult] = await conn.query(
      `INSERT INTO meal_logs (user_id, meal_type, log_date)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), updated_at = CURRENT_TIMESTAMP`,
      [req.user.id, mealType, logDate]
    );

    const mealLogId = logResult.insertId;

    if (replace) {
      await conn.query('DELETE FROM meal_log_items WHERE meal_log_id = ?', [mealLogId]);
    }

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;
    let insertedItems = 0;

    for (const item of items) {
      const foodId = item.food_id ? Number(item.food_id) : null;
      const amount = Number(item.amount ?? item.quantity);

      if (!amount || amount <= 0) continue;

      if (foodId) {
        const [foods] = await conn.query(
          `SELECT id, calories, protein, carbs, fat, base_amount, base_unit
           FROM foods
           WHERE id = ? AND status = 'approved'
           LIMIT 1`,
          [foodId]
        );

        if (!foods.length) continue;

        const f = foods[0];
        const baseAmount = Number(f.base_amount || 100);
        const amountUnit = item.amount_unit || f.base_unit || 'g';

        const itemCalories = round2(Number(f.calories || 0) * amount / baseAmount);
        const itemProtein = round2(Number(f.protein || 0) * amount / baseAmount);
        const itemCarbs = round2(Number(f.carbs || 0) * amount / baseAmount);
        const itemFat = round2(Number(f.fat || 0) * amount / baseAmount);

        await conn.query(
          `INSERT INTO meal_log_items
           (meal_log_id, food_id, custom_food_name, amount, amount_unit,
            total_calories, total_protein, total_carbs, total_fat, source)
           VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)`,
          [
            mealLogId,
            foodId,
            amount,
            amountUnit,
            itemCalories,
            itemProtein,
            itemCarbs,
            itemFat,
            item.source || 'manual',
          ]
        );

        totalCalories += itemCalories;
        totalProtein += itemProtein;
        totalCarbs += itemCarbs;
        totalFat += itemFat;
        insertedItems += 1;
      } else if (item.custom_food_name) {
        const itemCalories = round2(item.total_calories);
        const itemProtein = round2(item.total_protein);
        const itemCarbs = round2(item.total_carbs);
        const itemFat = round2(item.total_fat);

        await conn.query(
          `INSERT INTO meal_log_items
           (meal_log_id, food_id, custom_food_name, amount, amount_unit,
            total_calories, total_protein, total_carbs, total_fat, source)
           VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            mealLogId,
            String(item.custom_food_name).trim(),
            amount,
            item.amount_unit || 'portion',
            itemCalories,
            itemProtein,
            itemCarbs,
            itemFat,
            item.source || 'manual',
          ]
        );

        totalCalories += itemCalories;
        totalProtein += itemProtein;
        totalCarbs += itemCarbs;
        totalFat += itemFat;
        insertedItems += 1;
      }
    }

    if (!insertedItems) {
      await conn.rollback();
      return res.status(400).json({ success: false, message: 'Không có món ăn hợp lệ để lưu' });
    }

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Lưu bữa ăn thành công',
      meal_log_id: mealLogId,
      date: logDate,
      total_calories: round1(totalCalories),
      total_protein: round1(totalProtein),
      total_carbs: round1(totalCarbs),
      total_fat: round1(totalFat),
    });
  } catch (err) {
    await conn.rollback();
    console.error('ADD MEAL ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lưu bữa ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  } finally {
    conn.release();
  }
});

// DELETE /api/meals/items/:itemId
router.delete('/items/:itemId', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT mli.id
       FROM meal_log_items mli
       JOIN meal_logs ml ON ml.id = mli.meal_log_id
       WHERE mli.id = ?
         AND ml.user_id = ?
       LIMIT 1`,
      [req.params.itemId, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy món ăn trong bữa' });
    }

    await db.query('DELETE FROM meal_log_items WHERE id = ?', [req.params.itemId]);

    return res.json({ success: true, message: 'Đã xóa món ăn khỏi bữa' });
  } catch (err) {
    console.error('DELETE MEAL ITEM ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa món ăn' });
  }
});

// DELETE /api/meals/:mealLogId
router.delete('/:mealLogId', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id FROM meal_logs WHERE id = ? AND user_id = ? LIMIT 1',
      [req.params.mealLogId, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bữa ăn' });
    }

    await db.query('DELETE FROM meal_logs WHERE id = ? AND user_id = ?', [req.params.mealLogId, req.user.id]);

    return res.json({ success: true, message: 'Đã xóa bữa ăn' });
  } catch (err) {
    console.error('DELETE MEAL ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa bữa ăn' });
  }
});

module.exports = router;

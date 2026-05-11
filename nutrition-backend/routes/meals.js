const router = require('express').Router();
const db     = require('../config/db');
const auth   = require('../middleware/auth');

// GET /api/meals?date=2026-05-10
router.get('/', auth, async (req, res) => {
  const date = req.query.date || new Date().toISOString().slice(0, 10);
  const [rows] = await db.query(
    `SELECT ml.id AS meal_log_id, ml.meal_type,
            f.id AS food_id, f.name AS food_name,
            f.serving_unit, mli.quantity,
            mli.total_calories, mli.total_protein,
            mli.total_carbs,    mli.total_fat
     FROM meal_logs ml
     JOIN meal_log_items mli ON mli.meal_log_id = ml.id
     JOIN foods f            ON f.id = mli.food_id
     WHERE ml.user_id = ? AND ml.log_date = ?
     ORDER BY FIELD(ml.meal_type,'breakfast','lunch','dinner','snack'), ml.id`,
    [req.user.id, date]
  );

  // Nhóm theo bữa
  const grouped = {};
  for (const r of rows) {
    if (!grouped[r.meal_type]) {
      grouped[r.meal_type] = {
        meal_log_id: r.meal_log_id,
        meal_type: r.meal_type,
        items: [],
        total_calories: 0, total_protein: 0,
        total_carbs: 0,    total_fat: 0
      };
    }
    grouped[r.meal_type].items.push({
      food_id: r.food_id, food_name: r.food_name,
      quantity: r.quantity, serving_unit: r.serving_unit,
      total_calories: r.total_calories, total_protein: r.total_protein,
      total_carbs: r.total_carbs, total_fat: r.total_fat
    });
    grouped[r.meal_type].total_calories += r.total_calories;
    grouped[r.meal_type].total_protein  += r.total_protein;
    grouped[r.meal_type].total_carbs    += r.total_carbs;
    grouped[r.meal_type].total_fat      += r.total_fat;
  }

  res.json({ date, meals: Object.values(grouped) });
});

// POST /api/meals — tạo bữa và thêm danh sách món
router.post('/', auth, async (req, res) => {
  const { meal_type, date, items } = req.body;
  // items: [{ food_id, quantity }, ...]
  if (!meal_type || !items?.length)
    return res.status(400).json({ message: 'Thiếu dữ liệu' });

  const log_date = date || new Date().toISOString().slice(0, 10);
  const conn = await (await require('../config/db')).getConnection();

  try {
    await conn.beginTransaction();

    const [logResult] = await conn.query(
      'INSERT INTO meal_logs (user_id, meal_type, log_date) VALUES (?,?,?)',
      [req.user.id, meal_type, log_date]
    );
    const meal_log_id = logResult.insertId;

    for (const item of items) {
      const [foods] = await conn.query(
        'SELECT calories, protein, carbs, fat FROM foods WHERE id = ?',
        [item.food_id]
      );
      if (!foods.length) continue;
      const f = foods[0];
      const q = item.quantity;
      await conn.query(
        `INSERT INTO meal_log_items
           (meal_log_id, food_id, quantity,
            total_calories, total_protein, total_carbs, total_fat)
         VALUES (?,?,?,?,?,?,?)`,
        [
          meal_log_id, item.food_id, q,
          Math.round((f.calories / 100) * q * 10) / 10,
          Math.round((f.protein  / 100) * q * 10) / 10,
          Math.round((f.carbs    / 100) * q * 10) / 10,
          Math.round((f.fat      / 100) * q * 10) / 10,
        ]
      );
    }

    await conn.commit();
    res.status(201).json({ message: 'Lưu bữa ăn thành công', meal_log_id });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  } finally {
    conn.release();
  }
});

// DELETE /api/meals/:id
router.delete('/:id', auth, async (req, res) => {
  const [rows] = await db.query(
    'SELECT id FROM meal_logs WHERE id = ? AND user_id = ?',
    [req.params.id, req.user.id]
  );
  if (!rows.length) return res.status(404).json({ message: 'Không tìm thấy' });
  await db.query('DELETE FROM meal_logs WHERE id = ?', [req.params.id]);
  res.json({ message: 'Đã xóa bữa ăn' });
});

module.exports = router;
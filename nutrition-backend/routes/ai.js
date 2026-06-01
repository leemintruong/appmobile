const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function round2(n) {
  return Math.round(Number(n || 0) * 100) / 100;
}

// POST /api/ai/scan-meal
// Demo mock AI: chưa cần gọi AI thật. Client gửi image_url, backend trả kết quả giả lập.
router.post('/scan-meal', auth, async (req, res) => {
  const conn = await db.getConnection();

  try {
    const imageUrl = req.body.image_url || '/uploads/meals/mock-food.jpg';

    await conn.beginTransaction();

    const [imageResult] = await conn.query(
      `INSERT INTO meal_images (user_id, image_url, status)
       VALUES (?, ?, 'analyzed')`,
      [req.user.id, imageUrl]
    );

    const mealImageId = imageResult.insertId;

    // Mock result: cơm + ức gà + rau. Khi nâng cấp thật, thay đoạn này bằng AI API.
    const mockItems = [
      { name: 'Cơm trắng', food_id: 1, amount: 180, unit: 'g' },
      { name: 'Ức gà luộc', food_id: 6, amount: 120, unit: 'g' },
      { name: 'Rau xanh', food_id: null, amount: 100, unit: 'g', calories: 45, protein: 3, carbs: 5, fat: 2 },
    ];

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;
    const calculatedItems = [];

    for (const item of mockItems) {
      if (item.food_id) {
        const [foods] = await conn.query(
          `SELECT calories, protein, carbs, fat, base_amount, base_unit
           FROM foods WHERE id = ? LIMIT 1`,
          [item.food_id]
        );
        if (!foods.length) continue;
        const f = foods[0];
        const baseAmount = Number(f.base_amount || 100);
        item.calories = round2(Number(f.calories || 0) * item.amount / baseAmount);
        item.protein = round2(Number(f.protein || 0) * item.amount / baseAmount);
        item.carbs = round2(Number(f.carbs || 0) * item.amount / baseAmount);
        item.fat = round2(Number(f.fat || 0) * item.amount / baseAmount);
      }

      totalCalories += Number(item.calories || 0);
      totalProtein += Number(item.protein || 0);
      totalCarbs += Number(item.carbs || 0);
      totalFat += Number(item.fat || 0);
      calculatedItems.push(item);
    }

    const [scanResult] = await conn.query(
      `INSERT INTO ai_scan_results
       (meal_image_id, user_id, provider, estimated_calories, estimated_protein,
        estimated_carbs, estimated_fat, confidence_score, status, raw_response_json)
       VALUES (?, ?, 'mock_ai', ?, ?, ?, ?, 86.5, 'draft', ?)`,
      [mealImageId, req.user.id, round2(totalCalories), round2(totalProtein), round2(totalCarbs), round2(totalFat), JSON.stringify({ mock: true })]
    );

    const scanResultId = scanResult.insertId;

    for (const item of calculatedItems) {
      await conn.query(
        `INSERT INTO ai_scan_result_items
         (ai_scan_result_id, detected_food_name, matched_food_id, estimated_amount,
          estimated_unit, estimated_calories, estimated_protein, estimated_carbs,
          estimated_fat, confidence_score)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [scanResultId, item.name, item.food_id, item.amount, item.unit, round2(item.calories), round2(item.protein), round2(item.carbs), round2(item.fat), item.food_id ? 88 : 74]
      );
    }

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'AI đã phân tích ảnh món ăn',
      scan_result_id: scanResultId,
      meal_image_id: mealImageId,
      estimated_calories: round2(totalCalories),
      estimated_protein: round2(totalProtein),
      estimated_carbs: round2(totalCarbs),
      estimated_fat: round2(totalFat),
      items: calculatedItems,
    });
  } catch (err) {
    await conn.rollback();
    console.error('AI SCAN ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi phân tích ảnh món ăn' });
  } finally {
    conn.release();
  }
});


// POST /api/ai/scan-results/:scanResultId/items/:itemId/add-to-foods
// Tạo thực phẩm cá nhân từ món AI nhận diện, rồi liên kết item AI với foods.id.
router.post('/scan-results/:scanResultId/items/:itemId/add-to-foods', auth, async (req, res) => {
  const conn = await db.getConnection();

  try {
    const scanResultId = Number(req.params.scanResultId);
    const itemId = Number(req.params.itemId);

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT
          item.*,
          result.user_id
       FROM ai_scan_result_items item
       JOIN ai_scan_results result ON result.id = item.ai_scan_result_id
       WHERE item.id = ?
         AND item.ai_scan_result_id = ?
         AND result.user_id = ?
       LIMIT 1`,
      [itemId, scanResultId, req.user.id]
    );

    if (!rows.length) {
      await conn.rollback();
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy món AI cần thêm vào thư viện',
      });
    }

    const item = rows[0];

    if (item.matched_food_id) {
      await conn.commit();
      return res.json({
        success: true,
        message: 'Món này đã có trong thư viện',
        food_id: item.matched_food_id,
        already_exists: true,
      });
    }

    const foodName = String(item.detected_food_name || 'Món AI').trim();
    const baseAmount = Number(item.estimated_amount || 1);
    const baseUnit = item.estimated_unit || 'serving';

    const [foodResult] = await conn.query(
      `INSERT INTO foods
       (category_id, name, brand, calories, protein, carbs, fat, fiber, sugar, sodium_mg,
        base_amount, base_unit, serving_size, serving_unit, created_by,
        visibility, status, is_verified)
       VALUES (NULL, ?, 'AI Scanner', ?, ?, ?, ?, 0, 0, 0, ?, ?, ?, ?, ?, 'private', 'approved', 0)`,
      [
        foodName,
        Number(item.estimated_calories || 0),
        Number(item.estimated_protein || 0),
        Number(item.estimated_carbs || 0),
        Number(item.estimated_fat || 0),
        baseAmount > 0 ? baseAmount : 1,
        baseUnit,
        baseAmount > 0 ? baseAmount : 1,
        baseUnit,
        req.user.id,
      ]
    );

    const foodId = foodResult.insertId;

    await conn.query(
      `UPDATE ai_scan_result_items
       SET matched_food_id = ?
       WHERE id = ?`,
      [foodId, itemId]
    );

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Đã thêm món AI vào thư viện thực phẩm',
      food_id: foodId,
      food: {
        id: foodId,
        name: foodName,
        calories: Number(item.estimated_calories || 0),
        protein: Number(item.estimated_protein || 0),
        carbs: Number(item.estimated_carbs || 0),
        fat: Number(item.estimated_fat || 0),
        base_amount: baseAmount > 0 ? baseAmount : 1,
        base_unit: baseUnit,
      },
    });
  } catch (err) {
    await conn.rollback();
    console.error('ADD AI FOOD TO LIBRARY ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi thêm món AI vào thư viện',
    });
  } finally {
    conn.release();
  }
});


// GET /api/ai/scan-results/:id
router.get('/scan-results/:id', auth, async (req, res) => {
  try {
    const [results] = await db.query(
      `SELECT * FROM ai_scan_results WHERE id = ? AND user_id = ? LIMIT 1`,
      [req.params.id, req.user.id]
    );

    if (!results.length) return res.status(404).json({ success: false, message: 'Không tìm thấy kết quả AI' });

    const [items] = await db.query(
      `SELECT * FROM ai_scan_result_items WHERE ai_scan_result_id = ? ORDER BY id`,
      [req.params.id]
    );

    return res.json({ success: true, result: results[0], items });
  } catch (err) {
    console.error('GET AI RESULT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy kết quả AI' });
  }
});

// POST /api/ai/scan-results/:id/confirm
router.post('/scan-results/:id/confirm', auth, async (req, res) => {
  const conn = await db.getConnection();

  try {
    const mealType = req.body.meal_type || 'breakfast';
    const logDate = req.body.date || new Date().toISOString().slice(0, 10);

    await conn.beginTransaction();

    const [results] = await conn.query(
      `SELECT * FROM ai_scan_results
       WHERE id = ? AND user_id = ? AND status = 'draft'
       LIMIT 1`,
      [req.params.id, req.user.id]
    );

    if (!results.length) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Không tìm thấy kết quả AI cần xác nhận' });
    }

    const [mealLogResult] = await conn.query(
      `INSERT INTO meal_logs (user_id, meal_type, log_date)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), updated_at = CURRENT_TIMESTAMP`,
      [req.user.id, mealType, logDate]
    );

    const mealLogId = mealLogResult.insertId;

    const [items] = await conn.query(
      `SELECT * FROM ai_scan_result_items WHERE ai_scan_result_id = ?`,
      [req.params.id]
    );

    for (const item of items) {
      await conn.query(
        `INSERT INTO meal_log_items
         (meal_log_id, food_id, custom_food_name, amount, amount_unit,
          total_calories, total_protein, total_carbs, total_fat, source, ai_scan_result_item_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ai', ?)`,
        [mealLogId, item.matched_food_id, item.matched_food_id ? null : item.detected_food_name,
         item.estimated_amount || 1, item.estimated_unit || 'portion', item.estimated_calories || 0,
         item.estimated_protein || 0, item.estimated_carbs || 0, item.estimated_fat || 0, item.id]
      );
    }

    await conn.query(`UPDATE ai_scan_results SET status = 'confirmed' WHERE id = ?`, [req.params.id]);
    await conn.query(`UPDATE meal_images SET status = 'confirmed' WHERE id = ?`, [results[0].meal_image_id]);

    await conn.commit();

    return res.json({ success: true, message: 'Đã xác nhận và lưu bữa ăn từ AI', meal_log_id: mealLogId });
  } catch (err) {
    await conn.rollback();
    console.error('CONFIRM AI RESULT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xác nhận kết quả AI' });
  } finally {
    conn.release();
  }
});

module.exports = router;

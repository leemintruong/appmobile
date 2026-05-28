const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

async function getUserRole(userId) {
  const [rows] = await db.query('SELECT role FROM users WHERE id = ? LIMIT 1', [userId]);
  return rows[0]?.role || 'user';
}

function round2(n) {
  return Math.round(Number(n || 0) * 100) / 100;
}

async function findFoodCategoryIdByName(name) {
  if (!name) return null;

  const [rows] = await db.query(
    `SELECT id FROM food_categories WHERE name = ? LIMIT 1`,
    [name]
  );

  return rows[0]?.id || null;
}

// GET /api/foods/categories
router.get('/categories', auth, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT id, name, description FROM food_categories ORDER BY name');
    return res.json({ success: true, categories: rows });
  } catch (err) {
    console.error('GET FOOD CATEGORIES ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy danh mục món ăn' });
  }
});

// POST /api/foods/from-ai-result-item/:itemId
// Tạo món ăn cá nhân từ món AI nhận diện.
router.post('/from-ai-result-item/:itemId', auth, async (req, res) => {
  const conn = await db.getConnection();

  try {
    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT
          item.id AS item_id,
          item.detected_food_name,
          item.matched_food_id,
          item.estimated_amount,
          item.estimated_unit,
          item.estimated_calories,
          item.estimated_protein,
          item.estimated_carbs,
          item.estimated_fat,
          result.user_id
       FROM ai_scan_result_items item
       JOIN ai_scan_results result ON result.id = item.ai_scan_result_id
       WHERE item.id = ?
         AND result.user_id = ?
       LIMIT 1`,
      [req.params.itemId, req.user.id]
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
        message: 'Món này đã có trong thư viện thực phẩm',
        food_id: item.matched_food_id,
        already_exists: true,
      });
    }

    const foodName = String(req.body.name || item.detected_food_name || 'Món AI').trim();

    const [existing] = await conn.query(
      `SELECT id
       FROM foods
       WHERE name = ?
         AND (created_by = ? OR visibility IN ('system','public'))
       LIMIT 1`,
      [foodName, req.user.id]
    );

    if (existing.length) {
      await conn.query(
        `UPDATE ai_scan_result_items
         SET matched_food_id = ?
         WHERE id = ?`,
        [existing[0].id, item.item_id]
      );

      await conn.commit();

      return res.json({
        success: true,
        message: 'Món đã tồn tại, đã liên kết với kết quả AI',
        food_id: existing[0].id,
        already_exists: true,
      });
    }

    const categoryId = req.body.category_id
      ? Number(req.body.category_id)
      : await findFoodCategoryIdByName('Món nhà nấu');

    const amount = Number(item.estimated_amount || 1);
    const unit = item.estimated_unit || 'serving';

    const [inserted] = await conn.query(
      `INSERT INTO foods
       (category_id, name, brand, calories, protein, carbs, fat,
        base_amount, base_unit, serving_size, serving_unit,
        created_by, visibility, status, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'private', 'approved', 0)`,
      [
        categoryId,
        foodName,
        'AI estimate',
        round2(item.estimated_calories),
        round2(item.estimated_protein),
        round2(item.estimated_carbs),
        round2(item.estimated_fat),
        amount > 0 ? round2(amount) : 1,
        unit,
        amount > 0 ? round2(amount) : 1,
        unit,
        req.user.id,
      ]
    );

    await conn.query(
      `UPDATE ai_scan_result_items
       SET matched_food_id = ?
       WHERE id = ?`,
      [inserted.insertId, item.item_id]
    );

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Đã thêm món AI vào thư viện thực phẩm',
      food_id: inserted.insertId,
      food: {
        id: inserted.insertId,
        name: foodName,
        calories: round2(item.estimated_calories),
        protein: round2(item.estimated_protein),
        carbs: round2(item.estimated_carbs),
        fat: round2(item.estimated_fat),
        base_amount: amount > 0 ? round2(amount) : 1,
        base_unit: unit,
      },
    });
  } catch (err) {
    await conn.rollback();
    console.error('CREATE FOOD FROM AI ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi thêm món AI vào thư viện',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  } finally {
    conn.release();
  }
});

// GET /api/foods?search=gà&category_id=2&page=1&limit=20
router.get('/', auth, async (req, res) => {
  try {
    const search = String(req.query.search || '').trim();
    const categoryId = req.query.category_id ? Number(req.query.category_id) : null;
    const category = String(req.query.category || '').trim();
    const page = Math.max(Number(req.query.page || 1), 1);
    const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 100);
    const offset = (page - 1) * limit;

    const whereParts = [`(f.visibility = 'system' OR f.visibility = 'public' OR f.created_by = ?)`];
    const params = [req.user.id];

    if (search) {
      whereParts.push('f.name LIKE ?');
      params.push(`%${search}%`);
    }

    if (categoryId) {
      whereParts.push('f.category_id = ?');
      params.push(categoryId);
    }

    if (category) {
      whereParts.push('c.name = ?');
      params.push(category);
    }

    const where = `WHERE ${whereParts.join(' AND ')}`;

    const [rows] = await db.query(
      `SELECT
          f.id,
          f.category_id,
          c.name AS category,
          f.name,
          f.brand,
          f.calories,
          f.protein,
          f.carbs,
          f.fat,
          f.fiber,
          f.sugar,
          f.sodium_mg,
          f.base_amount,
          f.base_unit,
          f.serving_size,
          f.serving_unit,
          f.visibility,
          f.status,
          f.is_verified,
          EXISTS(SELECT 1 FROM favorite_foods ff WHERE ff.user_id = ? AND ff.food_id = f.id) AS is_favorite
       FROM foods f
       LEFT JOIN food_categories c ON c.id = f.category_id
       ${where}
         AND f.status = 'approved'
       ORDER BY f.name
       LIMIT ? OFFSET ?`,
      [req.user.id, ...params, limit, offset]
    );

    const [[countRow]] = await db.query(
      `SELECT COUNT(*) AS total
       FROM foods f
       LEFT JOIN food_categories c ON c.id = f.category_id
       ${where}
         AND f.status = 'approved'`,
      params
    );

    return res.json({
      success: true,
      page,
      limit,
      total: Number(countRow.total || 0),
      foods: rows,
    });
  } catch (err) {
    console.error('GET FOODS ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách món ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// GET /api/foods/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
          f.*,
          c.name AS category,
          EXISTS(SELECT 1 FROM favorite_foods ff WHERE ff.user_id = ? AND ff.food_id = f.id) AS is_favorite
       FROM foods f
       LEFT JOIN food_categories c ON c.id = f.category_id
       WHERE f.id = ?
         AND (f.visibility IN ('system','public') OR f.created_by = ?)
       LIMIT 1`,
      [req.user.id, req.params.id, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy món ăn' });
    }

    return res.json({ success: true, food: rows[0] });
  } catch (err) {
    console.error('GET FOOD DETAIL ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy chi tiết món ăn' });
  }
});

// POST /api/foods
router.post('/', auth, async (req, res) => {
  try {
    const {
      category_id,
      name,
      brand,
      calories,
      protein = 0,
      carbs = 0,
      fat = 0,
      fiber = 0,
      sugar = 0,
      sodium_mg = 0,
      base_amount = 100,
      base_unit = 'g',
      serving_size,
      serving_unit,
      visibility,
    } = req.body;

    if (!name || calories == null || Number(calories) < 0) {
      return res.status(400).json({ success: false, message: 'Thiếu tên món hoặc calo không hợp lệ' });
    }

    if (Number(base_amount) <= 0) {
      return res.status(400).json({ success: false, message: 'base_amount phải lớn hơn 0' });
    }

    const role = await getUserRole(req.user.id);
    const canCreatePublic = role === 'admin' || role === 'nutritionist';
    const finalVisibility = canCreatePublic && visibility ? visibility : 'private';
    const finalStatus = finalVisibility === 'private' ? 'approved' : 'pending';
    const isVerified = canCreatePublic ? 1 : 0;

    const [result] = await db.query(
      `INSERT INTO foods
       (category_id, name, brand, calories, protein, carbs, fat, fiber, sugar, sodium_mg,
        base_amount, base_unit, serving_size, serving_unit, created_by, visibility, status, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        category_id || null,
        String(name).trim(),
        brand || null,
        Number(calories),
        Number(protein),
        Number(carbs),
        Number(fat),
        Number(fiber),
        Number(sugar),
        Number(sodium_mg),
        Number(base_amount),
        base_unit || 'g',
        serving_size || base_amount,
        serving_unit || base_unit || 'g',
        req.user.id,
        finalVisibility,
        finalStatus,
        isVerified,
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Thêm món ăn thành công',
      id: result.insertId,
      status: finalStatus,
    });
  } catch (err) {
    console.error('CREATE FOOD ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi thêm món ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// POST /api/foods/:id/favorite
router.post('/:id/favorite', auth, async (req, res) => {
  try {
    await db.query(
      'INSERT IGNORE INTO favorite_foods (user_id, food_id) VALUES (?, ?)',
      [req.user.id, req.params.id]
    );

    return res.json({ success: true, message: 'Đã thêm vào món yêu thích' });
  } catch (err) {
    console.error('ADD FAVORITE ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi thêm món yêu thích' });
  }
});

// DELETE /api/foods/:id/favorite
router.delete('/:id/favorite', auth, async (req, res) => {
  try {
    await db.query('DELETE FROM favorite_foods WHERE user_id = ? AND food_id = ?', [req.user.id, req.params.id]);
    return res.json({ success: true, message: 'Đã xóa khỏi món yêu thích' });
  } catch (err) {
    console.error('REMOVE FAVORITE ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa món yêu thích' });
  }
});

module.exports = router;

const router = require('express').Router();
const db     = require('../config/db');
const auth   = require('../middleware/auth');

// GET /api/foods?search=gà&category=Thịt&page=1&limit=20
router.get('/', auth, async (req, res) => {
  const { search = '', category = '', page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;
  const params = [];
  let where = 'WHERE 1=1';

  if (search) { where += ' AND name LIKE ?'; params.push(`%${search}%`); }
  if (category) { where += ' AND category = ?'; params.push(category); }

  const [rows] = await db.query(
    `SELECT id, name, calories, protein, carbs, fat,
            serving_size, serving_unit, category
     FROM foods ${where}
     ORDER BY name LIMIT ? OFFSET ?`,
    [...params, parseInt(limit), parseInt(offset)]
  );
  res.json(rows);
});

// GET /api/foods/:id
router.get('/:id', auth, async (req, res) => {
  const [rows] = await db.query('SELECT * FROM foods WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ message: 'Không tìm thấy' });
  res.json(rows[0]);
});

// POST /api/foods
router.post('/', auth, async (req, res) => {
  const { name, calories, protein, carbs, fat,
          serving_size, serving_unit, category } = req.body;
  if (!name || calories == null)
    return res.status(400).json({ message: 'Thiếu thông tin bắt buộc' });

  const [result] = await db.query(
    `INSERT INTO foods
       (name, calories, protein, carbs, fat, serving_size, serving_unit, category)
     VALUES (?,?,?,?,?,?,?,?)`,
    [name, calories, protein || 0, carbs || 0, fat || 0,
     serving_size || 100, serving_unit || 'g', category || null]
  );
  res.status(201).json({ message: 'Thêm món ăn thành công', id: result.insertId });
});

module.exports = router;
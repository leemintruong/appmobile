const router = require('express').Router();
const db     = require('../config/db');
const auth   = require('../middleware/auth');

// GET /api/weights?from=2026-04-01&to=2026-05-10
router.get('/', auth, async (req, res) => {
  const { from, to } = req.query;
  let where = 'WHERE user_id = ?';
  const params = [req.user.id];
  if (from) { where += ' AND log_date >= ?'; params.push(from); }
  if (to)   { where += ' AND log_date <= ?'; params.push(to); }

  const [rows] = await db.query(
    `SELECT id, weight, log_date, note FROM weight_logs
     ${where} ORDER BY log_date ASC`,
    params
  );
  res.json(rows);
});

// POST /api/weights
router.post('/', auth, async (req, res) => {
  const { weight, date, note } = req.body;
  if (!weight) return res.status(400).json({ message: 'Thiếu cân nặng' });

  const log_date = date || new Date().toISOString().slice(0, 10);
  await db.query(
    `INSERT INTO weight_logs (user_id, weight, log_date, note)
     VALUES (?,?,?,?)
     ON DUPLICATE KEY UPDATE weight=VALUES(weight), note=VALUES(note)`,
    [req.user.id, weight, log_date, note || null]
  );
  res.status(201).json({ message: 'Đã lưu cân nặng' });
});

// DELETE /api/weights/:id
router.delete('/:id', auth, async (req, res) => {
  await db.query(
    'DELETE FROM weight_logs WHERE id = ? AND user_id = ?',
    [req.params.id, req.user.id]
  );
  res.json({ message: 'Đã xóa' });
});

module.exports = router;
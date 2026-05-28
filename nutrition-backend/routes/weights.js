const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const { normalizeDate } = require('../utils/date');

// GET /api/weights?from=2026-04-01&to=2026-05-10
router.get('/', auth, async (req, res) => {
  try {
    const { from, to } = req.query;
    let where = 'WHERE user_id = ?';
    const params = [req.user.id];

    if (from) { where += ' AND log_date >= ?'; params.push(from); }
    if (to) { where += ' AND log_date <= ?'; params.push(to); }

    const [rows] = await db.query(
      `SELECT id, weight_kg, weight_kg AS weight, DATE_FORMAT(log_date, '%Y-%m-%d') AS log_date, note
       FROM weight_logs ${where}
       ORDER BY log_date ASC`,
      params
    );

    return res.json({ success: true, weights: rows });
  } catch (err) {
    console.error('GET WEIGHTS ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy cân nặng' });
  }
});

// POST /api/weights
router.post('/', auth, async (req, res) => {
  try {
    const weightKg = Number(req.body.weight_kg ?? req.body.weight);
    const logDate = normalizeDate(req.body.date);
    const note = req.body.note || null;

    if (!weightKg || weightKg <= 0) {
      return res.status(400).json({ success: false, message: 'Cân nặng không hợp lệ' });
    }

    await db.query(
      `INSERT INTO weight_logs (user_id, weight_kg, log_date, note)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE weight_kg = VALUES(weight_kg), note = VALUES(note)`,
      [req.user.id, weightKg, logDate, note]
    );

    await db.query('UPDATE user_profiles SET current_weight_kg = ? WHERE user_id = ?', [weightKg, req.user.id]);

    return res.status(201).json({ success: true, message: 'Đã lưu cân nặng', weight_kg: weightKg, log_date: logDate });
  } catch (err) {
    console.error('SAVE WEIGHT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lưu cân nặng' });
  }
});

// DELETE /api/weights/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await db.query('DELETE FROM weight_logs WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Đã xóa cân nặng' });
  } catch (err) {
    console.error('DELETE WEIGHT ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa cân nặng' });
  }
});

module.exports = router;

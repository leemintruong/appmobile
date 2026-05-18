const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function today() { return new Date().toISOString().slice(0, 10); }

// GET /api/water?date=2026-05-10
router.get('/', auth, async (req, res) => {
  try {
    const date = req.query.date || today();
    const [logs] = await db.query(
      `SELECT id, amount_ml, log_date, created_at
       FROM water_logs WHERE user_id = ? AND log_date = ? ORDER BY created_at`,
      [req.user.id, date]
    );
    const [[summary]] = await db.query(
      'SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml FROM water_logs WHERE user_id = ? AND log_date = ?',
      [req.user.id, date]
    );
    const [[goal = {}]] = await db.query(
      `SELECT daily_water_goal_ml FROM goals
       WHERE user_id = ? AND is_active = 1 ORDER BY created_at DESC LIMIT 1`,
      [req.user.id]
    );
    return res.json({ success: true, date, total_water_ml: Number(summary.total_water_ml || 0), daily_water_goal_ml: Number(goal.daily_water_goal_ml || 2000), logs });
  } catch (err) {
    console.error('GET WATER ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy dữ liệu nước uống' });
  }
});

// POST /api/water
router.post('/', auth, async (req, res) => {
  try {
    const amountMl = Number(req.body.amount_ml);
    const logDate = req.body.date || today();
    if (!amountMl || amountMl <= 0) return res.status(400).json({ success: false, message: 'Lượng nước không hợp lệ' });
    const [result] = await db.query('INSERT INTO water_logs (user_id, amount_ml, log_date) VALUES (?, ?, ?)', [req.user.id, amountMl, logDate]);
    return res.status(201).json({ success: true, message: 'Đã lưu lượng nước uống', id: result.insertId, amount_ml: amountMl, log_date: logDate });
  } catch (err) {
    console.error('SAVE WATER ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lưu nước uống' });
  }
});

// DELETE /api/water/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await db.query('DELETE FROM water_logs WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Đã xóa bản ghi nước uống' });
  } catch (err) {
    console.error('DELETE WATER ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa nước uống' });
  }
});

module.exports = router;

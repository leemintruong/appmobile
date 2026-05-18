const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function today() { return new Date().toISOString().slice(0, 10); }

// GET /api/activities?date=2026-05-10
router.get('/', auth, async (req, res) => {
  try {
    const date = req.query.date || today();
    const [activities] = await db.query(
      `SELECT id, activity_name, duration_minutes, calories_burned, log_date, created_at
       FROM activity_logs WHERE user_id = ? AND log_date = ? ORDER BY created_at`,
      [req.user.id, date]
    );
    const [[summary]] = await db.query(
      `SELECT COALESCE(SUM(duration_minutes), 0) AS total_activity_minutes,
              COALESCE(SUM(calories_burned), 0) AS total_calories_burned
       FROM activity_logs WHERE user_id = ? AND log_date = ?`,
      [req.user.id, date]
    );
    return res.json({ success: true, date, total_activity_minutes: Number(summary.total_activity_minutes || 0), total_calories_burned: Number(summary.total_calories_burned || 0), activities });
  } catch (err) {
    console.error('GET ACTIVITIES ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy vận động' });
  }
});

// POST /api/activities
router.post('/', auth, async (req, res) => {
  try {
    const activityName = String(req.body.activity_name || '').trim();
    const durationMinutes = Number(req.body.duration_minutes);
    const caloriesBurned = Number(req.body.calories_burned || 0);
    const logDate = req.body.date || today();
    if (!activityName || !durationMinutes || durationMinutes <= 0) {
      return res.status(400).json({ success: false, message: 'Thông tin vận động không hợp lệ' });
    }
    const [result] = await db.query(
      `INSERT INTO activity_logs (user_id, activity_name, duration_minutes, calories_burned, log_date)
       VALUES (?, ?, ?, ?, ?)`,
      [req.user.id, activityName, durationMinutes, caloriesBurned, logDate]
    );
    return res.status(201).json({ success: true, message: 'Đã lưu hoạt động', id: result.insertId });
  } catch (err) {
    console.error('SAVE ACTIVITY ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lưu vận động' });
  }
});

// DELETE /api/activities/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await db.query('DELETE FROM activity_logs WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Đã xóa hoạt động' });
  } catch (err) {
    console.error('DELETE ACTIVITY ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi xóa vận động' });
  }
});

module.exports = router;

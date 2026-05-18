const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

function round(n) {
  return Math.round(Number(n || 0));
}

function calcGoal(profile, goalType) {
  const weight = Number(profile.current_weight_kg);
  const height = Number(profile.height_cm);
  const age = Number(profile.age);
  const bmr = profile.gender === 'male'
    ? 10 * weight + 6.25 * height - 5 * age + 5
    : 10 * weight + 6.25 * height - 5 * age - 161;
  const factors = { sedentary: 1.2, light: 1.375, moderate: 1.55, active: 1.725, very_active: 1.9 };
  const tdee = bmr * (factors[profile.activity_level] || 1.55);
  const calorieMap = { lose_weight: tdee - 500, gain_weight: tdee + 300, build_muscle: tdee + 200, maintain: tdee };
  const dailyCalorieGoal = Math.max(round(calorieMap[goalType] || tdee), 1200);
  return {
    daily_calorie_goal: dailyCalorieGoal,
    daily_protein_goal: round(weight * 1.6),
    daily_carbs_goal: round((dailyCalorieGoal * 0.45) / 4),
    daily_fat_goal: round((dailyCalorieGoal * 0.25) / 9),
    daily_water_goal_ml: round(weight * 35),
  };
}

// GET /api/profile
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.name, u.email, u.role, u.status,
              p.gender, p.age, p.height_cm, p.current_weight_kg, p.activity_level, p.unit_system,
              g.id AS goal_id, g.goal_type, g.target_weight_kg,
              g.daily_calorie_goal, g.daily_protein_goal, g.daily_carbs_goal, g.daily_fat_goal,
              g.daily_water_goal_ml, g.start_date, g.end_date
       FROM users u
       LEFT JOIN user_profiles p ON p.user_id = u.id
       LEFT JOIN goals g ON g.user_id = u.id AND g.is_active = 1
       WHERE u.id = ? LIMIT 1`,
      [req.user.id]
    );
    if (!rows.length) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
    return res.json({ success: true, profile: rows[0] });
  } catch (err) {
    console.error('GET PROFILE ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy hồ sơ' });
  }
});

// PUT /api/profile
router.put('/', auth, async (req, res) => {
  const conn = await db.getConnection();
  try {
    const uid = req.user.id;
    const { name, gender, age, height_cm, height, current_weight_kg, weight, activity_level = 'moderate', unit_system = 'metric' } = req.body;
    const finalHeight = Number(height_cm ?? height);
    const finalWeight = Number(current_weight_kg ?? weight);
    if (!gender || !age || !finalHeight || !finalWeight) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ hồ sơ cá nhân' });
    }
    await conn.beginTransaction();
    if (name) await conn.query('UPDATE users SET name = ? WHERE id = ?', [String(name).trim(), uid]);
    await conn.query(
      `INSERT INTO user_profiles (user_id, gender, age, height_cm, current_weight_kg, activity_level, unit_system)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE gender=VALUES(gender), age=VALUES(age), height_cm=VALUES(height_cm),
       current_weight_kg=VALUES(current_weight_kg), activity_level=VALUES(activity_level),
       unit_system=VALUES(unit_system), updated_at=CURRENT_TIMESTAMP`,
      [uid, gender, Number(age), finalHeight, finalWeight, activity_level, unit_system]
    );
    await conn.commit();
    return res.json({ success: true, message: 'Cập nhật hồ sơ thành công' });
  } catch (err) {
    await conn.rollback();
    console.error('UPDATE PROFILE ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi cập nhật hồ sơ' });
  } finally {
    conn.release();
  }
});

// POST /api/profile/goal
router.post('/goal', auth, async (req, res) => {
  const conn = await db.getConnection();
  try {
    const uid = req.user.id;
    const goalType = req.body.goal_type || 'maintain';
    const targetWeightKg = req.body.target_weight_kg ?? req.body.target_weight ?? null;
    const validGoalTypes = ['lose_weight', 'gain_weight', 'maintain', 'build_muscle'];
    if (!validGoalTypes.includes(goalType)) {
      return res.status(400).json({ success: false, message: 'Mục tiêu không hợp lệ' });
    }
    const [profiles] = await db.query('SELECT * FROM user_profiles WHERE user_id = ? LIMIT 1', [uid]);
    if (!profiles.length) return res.status(400).json({ success: false, message: 'Vui lòng cập nhật hồ sơ trước' });
    const goal = calcGoal(profiles[0], goalType);
    await conn.beginTransaction();
    await conn.query('UPDATE goals SET is_active = 0 WHERE user_id = ? AND is_active = 1', [uid]);
    const [result] = await conn.query(
      `INSERT INTO goals
       (user_id, goal_type, target_weight_kg, daily_calorie_goal, daily_protein_goal,
        daily_carbs_goal, daily_fat_goal, daily_water_goal_ml, start_date, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_DATE, 1)`,
      [uid, goalType, targetWeightKg, goal.daily_calorie_goal, goal.daily_protein_goal,
       goal.daily_carbs_goal, goal.daily_fat_goal, goal.daily_water_goal_ml]
    );
    await conn.commit();
    return res.status(201).json({ success: true, message: 'Thiết lập mục tiêu thành công', goal_id: result.insertId, ...goal });
  } catch (err) {
    await conn.rollback();
    console.error('CREATE GOAL ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi thiết lập mục tiêu' });
  } finally {
    conn.release();
  }
});

// GET /api/profile/goals
router.get('/goals', auth, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM goals WHERE user_id = ? ORDER BY is_active DESC, created_at DESC', [req.user.id]);
    return res.json({ success: true, goals: rows });
  } catch (err) {
    console.error('GET GOALS ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy mục tiêu' });
  }
});

module.exports = router;

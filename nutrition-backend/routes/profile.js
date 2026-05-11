const router = require('express').Router();
const db     = require('../config/db');
const auth   = require('../middleware/auth');

// GET /api/profile
router.get('/', auth, async (req, res) => {
  const [rows] = await db.query(
    `SELECT u.id, u.name, u.email,
            p.gender, p.age, p.height, p.weight, p.activity_level,
            g.goal_type, g.target_weight, g.daily_calorie_goal,
            g.daily_protein_goal, g.daily_carbs_goal, g.daily_fat_goal
     FROM users u
     LEFT JOIN user_profiles p ON p.user_id = u.id
     LEFT JOIN goals g ON g.user_id = u.id
     WHERE u.id = ?
     ORDER BY g.created_at DESC LIMIT 1`,
    [req.user.id]
  );
  if (rows.length === 0) return res.status(404).json({ message: 'Không tìm thấy' });
  res.json(rows[0]);
});

// PUT /api/profile
router.put('/', auth, async (req, res) => {
  const { name, gender, age, height, weight, activity_level } = req.body;
  const uid = req.user.id;

  if (name) await db.query('UPDATE users SET name = ? WHERE id = ?', [name, uid]);

  const [existing] = await db.query(
    'SELECT id FROM user_profiles WHERE user_id = ?', [uid]
  );
  if (existing.length > 0) {
    await db.query(
      `UPDATE user_profiles
       SET gender=?, age=?, height=?, weight=?, activity_level=?
       WHERE user_id=?`,
      [gender, age, height, weight, activity_level, uid]
    );
  } else {
    await db.query(
      `INSERT INTO user_profiles (user_id,gender,age,height,weight,activity_level)
       VALUES (?,?,?,?,?,?)`,
      [uid, gender, age, height, weight, activity_level]
    );
  }
  res.json({ message: 'Cập nhật thành công' });
});

// POST /api/profile/goal
router.post('/goal', auth, async (req, res) => {
  const { goal_type, target_weight } = req.body;
  const uid = req.user.id;

  // Tính calo mục tiêu tự động
  const [profRows] = await db.query(
    'SELECT * FROM user_profiles WHERE user_id = ?', [uid]
  );
  if (profRows.length === 0)
    return res.status(400).json({ message: 'Vui lòng cập nhật hồ sơ trước' });

  const p = profRows[0];
  let bmr = p.gender === 'male'
    ? 10 * p.weight + 6.25 * p.height - 5 * p.age + 5
    : 10 * p.weight + 6.25 * p.height - 5 * p.age - 161;

  const factors = {
    sedentary: 1.2, light: 1.375, moderate: 1.55,
    active: 1.725, very_active: 1.9
  };
  const tdee = bmr * (factors[p.activity_level] || 1.55);

  const calorieMap = {
    lose_weight: tdee - 500, gain_weight: tdee + 300,
    build_muscle: tdee + 200, maintain: tdee
  };
  const daily_calorie_goal = Math.round(calorieMap[goal_type] || tdee);
  const daily_protein_goal = Math.round(p.weight * 1.6);
  const daily_carbs_goal   = Math.round((daily_calorie_goal * 0.45) / 4);
  const daily_fat_goal     = Math.round((daily_calorie_goal * 0.25) / 9);

  await db.query(
    `INSERT INTO goals
       (user_id, goal_type, target_weight, daily_calorie_goal,
        daily_protein_goal, daily_carbs_goal, daily_fat_goal)
     VALUES (?,?,?,?,?,?,?)`,
    [uid, goal_type, target_weight || null, daily_calorie_goal,
     daily_protein_goal, daily_carbs_goal, daily_fat_goal]
  );

  res.status(201).json({
    message: 'Thiết lập mục tiêu thành công',
    daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal
  });
});

module.exports = router;
const router = require('express').Router();
const { GoogleGenAI } = require('@google/genai');
const db = require('../config/db');
const auth = require('../middleware/auth');

function localDateKey(value = new Date()) {
  const d = value instanceof Date ? value : new Date(value);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function toNumber(v) {
  return Number(v || 0);
}

function cleanAiText(text) {
  return String(text || '')
    .replace(/```json/g, '')
    .replace(/```/g, '')
    .trim();
}

function getGeminiClient() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY');
  }

  return new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });
}

async function getDetailedMeals(userId, date) {
  const [rows] = await db.query(
    `SELECT
        ml.id AS meal_log_id,
        ml.meal_type,
        ml.log_date,
        mli.id AS item_id,
        mli.food_id,
        COALESCE(f.name, mli.custom_food_name) AS food_name,
        mli.amount,
        mli.amount_unit,
        mli.total_calories,
        mli.total_protein,
        mli.total_carbs,
        mli.total_fat,
        mli.source
     FROM meal_logs ml
     LEFT JOIN meal_log_items mli ON mli.meal_log_id = ml.id
     LEFT JOIN foods f ON f.id = mli.food_id
     WHERE ml.user_id = ?
       AND ml.log_date = ?
     ORDER BY FIELD(ml.meal_type, 'breakfast', 'lunch', 'dinner', 'snack'), ml.id, mli.id`,
    [userId, date]
  );

  const grouped = {};

  for (const r of rows) {
    if (!grouped[r.meal_type]) {
      grouped[r.meal_type] = {
        meal_type: r.meal_type,
        log_date: r.log_date,
        items: [],
        total_calories: 0,
        total_protein: 0,
        total_carbs: 0,
        total_fat: 0,
      };
    }

    if (!r.item_id) continue;

    const item = {
      item_id: r.item_id,
      food_id: r.food_id,
      food_name: r.food_name,
      amount: Number(r.amount || 0),
      amount_unit: r.amount_unit,
      total_calories: Number(r.total_calories || 0),
      total_protein: Number(r.total_protein || 0),
      total_carbs: Number(r.total_carbs || 0),
      total_fat: Number(r.total_fat || 0),
      source: r.source,
    };

    grouped[r.meal_type].items.push(item);
    grouped[r.meal_type].total_calories += item.total_calories;
    grouped[r.meal_type].total_protein += item.total_protein;
    grouped[r.meal_type].total_carbs += item.total_carbs;
    grouped[r.meal_type].total_fat += item.total_fat;
  }

  return Object.values(grouped).map((meal) => ({
    ...meal,
    item_count: meal.items.length,
    summary_text: meal.items.map((x) => x.food_name).filter(Boolean).join(', '),
    total_calories: Number(meal.total_calories.toFixed(1)),
    total_protein: Number(meal.total_protein.toFixed(1)),
    total_carbs: Number(meal.total_carbs.toFixed(1)),
    total_fat: Number(meal.total_fat.toFixed(1)),
  }));
}

async function getUserNutritionContext(userId, date) {
  const [[profile = {}]] = await db.query(
    `SELECT
        u.id,
        u.name,
        u.email,
        p.gender,
        p.age,
        p.height_cm,
        p.current_weight_kg,
        p.activity_level,
        g.goal_type,
        g.target_weight_kg,
        g.daily_calorie_goal,
        g.daily_protein_goal,
        g.daily_carbs_goal,
        g.daily_fat_goal,
        g.daily_water_goal_ml
     FROM users u
     LEFT JOIN user_profiles p ON p.user_id = u.id
     LEFT JOIN goals g ON g.user_id = u.id AND g.is_active = 1
     WHERE u.id = ?
     LIMIT 1`,
    [userId]
  );

  const [[nutrition = {}]] = await db.query(
    `SELECT *
     FROM v_daily_nutrition
     WHERE user_id = ? AND log_date = ?
     LIMIT 1`,
    [userId, date]
  );

  const meals = await getDetailedMeals(userId, date);

  const [[water = {}]] = await db.query(
    `SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml
     FROM water_logs
     WHERE user_id = ? AND log_date = ?`,
    [userId, date]
  );

  const [[activity = {}]] = await db.query(
    `SELECT
        COALESCE(SUM(duration_minutes), 0) AS total_activity_minutes,
        COALESCE(SUM(calories_burned), 0) AS total_calories_burned
     FROM activity_logs
     WHERE user_id = ? AND log_date = ?`,
    [userId, date]
  );

  const [weights] = await db.query(
    `SELECT weight_kg, log_date, note
     FROM weight_logs
     WHERE user_id = ?
     ORDER BY log_date DESC
     LIMIT 5`,
    [userId]
  );

  return {
    date,
    profile,
    daily: {
      total_calories: toNumber(nutrition.total_calories),
      total_protein: toNumber(nutrition.total_protein),
      total_carbs: toNumber(nutrition.total_carbs),
      total_fat: toNumber(nutrition.total_fat),
      total_water_ml: toNumber(water.total_water_ml),
      total_activity_minutes: toNumber(activity.total_activity_minutes),
      total_calories_burned: toNumber(activity.total_calories_burned),
    },
    meals,
    recent_weights: weights,
  };
}

function buildSystemPrompt(mode = 'chat') {
  const modeInstruction = mode === 'meal_suggestion'
    ? 'Tập trung gợi ý bữa ăn hoặc bữa phụ phù hợp với phần calo/macro còn thiếu.'
    : 'Tập trung trả lời câu hỏi của người dùng dựa trên dữ liệu ăn uống, calo, macro, nước, vận động và mục tiêu.';

  return `
Bạn là AI Coach dinh dưỡng và sức khỏe tổng quát trong một app theo dõi dinh dưỡng.
Bạn KHÔNG phải bác sĩ, không chẩn đoán bệnh, không kê thuốc, không thay thế tư vấn y tế chuyên môn.

Luật an toàn:
- Không kết luận người dùng mắc bệnh.
- Không hướng dẫn ngừng/dùng thuốc.
- Nếu người dùng hỏi về triệu chứng nguy hiểm như đau ngực, khó thở, ngất, chảy máu, sốt cao kéo dài, đau dữ dội, hãy khuyên liên hệ bác sĩ/cấp cứu.
- Chỉ phân tích dinh dưỡng, calo, protein, carb, fat, nước, vận động, cân nặng và thói quen ăn uống.
- Luôn nói rõ số liệu chỉ là ước tính nếu dựa trên AI scan.
- Trả lời bằng tiếng Việt, dễ hiểu, ngắn gọn, có hành động cụ thể.

${modeInstruction}

Cách trả lời:
1. Nhận xét nhanh 1-2 câu.
2. Nêu phần còn thiếu/thừa nếu có.
3. Gợi ý 2-4 món hoặc hành động phù hợp.
4. Thêm lưu ý an toàn nếu câu hỏi liên quan sức khỏe/bệnh/thuốc.
`;
}

async function askGemini({ message, context, mode = 'chat' }) {
  const ai = getGeminiClient();

  const prompt = `
${buildSystemPrompt(mode)}

Dữ liệu người dùng dạng JSON:
${JSON.stringify(context, null, 2)}

Câu hỏi người dùng:
${message}

Hãy trả lời ngắn gọn, tự nhiên, như một AI Coach dinh dưỡng thân thiện.
`;

  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [{ text: prompt }],
  });

  return cleanAiText(response.text);
}

async function saveChat(userId, userMessage, aiResponse, mode, date) {
  try {
    await db.query(
      `INSERT INTO ai_health_chats (user_id, user_message, ai_response, mode, context_date)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, userMessage, aiResponse, mode, date]
    );
  } catch (err) {
    // Không làm hỏng response nếu bảng history chưa migrate.
    console.warn('SAVE AI HEALTH CHAT WARNING:', err.message);
  }
}

// POST /api/ai-coach/chat
router.post('/chat', auth, async (req, res) => {
  try {
    const message = String(req.body.message || '').trim();
    const date = req.body.date || localDateKey();

    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập câu hỏi',
      });
    }

    const context = await getUserNutritionContext(req.user.id, date);
    const answer = await askGemini({ message, context, mode: 'chat' });

    await saveChat(req.user.id, message, answer, 'chat', date);

    return res.json({
      success: true,
      date,
      answer,
      context_summary: {
        total_calories: context.daily.total_calories,
        daily_calorie_goal: toNumber(context.profile.daily_calorie_goal),
        total_protein: context.daily.total_protein,
        daily_protein_goal: toNumber(context.profile.daily_protein_goal),
        total_water_ml: context.daily.total_water_ml,
        daily_water_goal_ml: toNumber(context.profile.daily_water_goal_ml),
      },
    });
  } catch (err) {
    console.error('AI HEALTH CHAT ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi hỏi AI Coach',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// POST /api/ai-coach/suggest-meal
router.post('/suggest-meal', auth, async (req, res) => {
  try {
    const date = req.body.date || localDateKey();
    const mealType = req.body.meal_type || 'snack';
    const extra = String(req.body.note || '').trim();

    const context = await getUserNutritionContext(req.user.id, date);

    const message = `
Hãy gợi ý một bữa ${mealType} phù hợp cho hôm nay.
Ưu tiên mục tiêu hiện tại của tôi, phần calo còn thiếu, protein còn thiếu, và các bữa tôi đã ăn.
${extra ? `Ghi chú thêm: ${extra}` : ''}
`;

    const answer = await askGemini({
      message,
      context,
      mode: 'meal_suggestion',
    });

    await saveChat(req.user.id, message, answer, 'meal_suggestion', date);

    return res.json({
      success: true,
      date,
      meal_type: mealType,
      answer,
      context_summary: {
        total_calories: context.daily.total_calories,
        daily_calorie_goal: toNumber(context.profile.daily_calorie_goal),
        total_protein: context.daily.total_protein,
        daily_protein_goal: toNumber(context.profile.daily_protein_goal),
      },
    });
  } catch (err) {
    console.error('AI MEAL SUGGESTION ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi gợi ý bữa ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  }
});

// GET /api/ai-coach/history?limit=20
router.get('/history', auth, async (req, res) => {
  try {
    const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 50);

    const [rows] = await db.query(
      `SELECT id, user_message, ai_response, mode, context_date, created_at
       FROM ai_health_chats
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT ?`,
      [req.user.id, limit]
    );

    return res.json({
      success: true,
      history: rows.reverse(),
    });
  } catch (err) {
    console.error('GET AI HEALTH HISTORY ERROR:', err);
    return res.json({
      success: true,
      history: [],
      warning: 'Chưa có bảng ai_health_chats hoặc chưa có lịch sử',
    });
  }
});

module.exports = router;

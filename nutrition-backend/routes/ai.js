const router = require('express').Router();
const { GoogleGenAI } = require('@google/genai');
const db = require('../config/db');
const auth = require('../middleware/auth');

function round2(n) {
  return Math.round(Number(n || 0) * 100) / 100;
}

function cleanJsonText(text) {
  if (!text) return '{}';

  let cleaned = text
    .replace(/```json/g, '')
    .replace(/```/g, '')
    .trim();

  const firstBrace = cleaned.indexOf('{');
  const lastBrace = cleaned.lastIndexOf('}');

  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    cleaned = cleaned.slice(firstBrace, lastBrace + 1);
  }

  return cleaned;
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isGeminiBusyError(err) {
  return (
    err?.status === 503 ||
    err?.message?.includes('503') ||
    err?.message?.toLowerCase?.().includes('high demand') ||
    err?.message?.toLowerCase?.().includes('unavailable') ||
    err?.message?.toLowerCase?.().includes('overloaded')
  );
}

async function callGeminiModel(ai, model, prompt, imageBase64, mimeType) {
  const response = await ai.models.generateContent({
    model,
    contents: [
      {
        inlineData: {
          mimeType,
          data: imageBase64,
        },
      },
      {
        text: prompt,
      },
    ],
  });

  const text = response.text || '';
  const jsonText = cleanJsonText(text);

  return JSON.parse(jsonText);
}

async function analyzeFoodImageWithGemini(imageBase64, mimeType = 'image/jpeg') {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY');
  }

  const ai = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });

  const prompt = `
You are a nutrition estimation assistant.

Analyze the food image and return ONLY valid JSON.
Do not return markdown. Do not wrap the result in code fences.

Return exactly this JSON structure:
{
  "estimated_calories": number,
  "estimated_protein": number,
  "estimated_carbs": number,
  "estimated_fat": number,
  "confidence_score": number,
  "items": [
    {
      "detected_food_name": string,
      "estimated_amount": number,
      "estimated_unit": string,
      "estimated_calories": number,
      "estimated_protein": number,
      "estimated_carbs": number,
      "estimated_fat": number,
      "confidence_score": number
    }
  ],
  "note": string
}

Rules:
- Estimate only visible food.
- If the food is Vietnamese, use Vietnamese food names.
- If portion size is uncertain, estimate conservatively.
- Use units like g, ml, bowl, plate, piece, serving when suitable.
- Calories and macros are estimates, not medical advice.
- Lower confidence_score if image is unclear.
`;

  const models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  let lastError;

  for (const model of models) {
    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        console.log(`Gemini scan try model=${model}, attempt=${attempt}`);

        return await callGeminiModel(ai, model, prompt, imageBase64, mimeType);
      } catch (err) {
        lastError = err;

        console.error(`Gemini scan failed model=${model}, attempt=${attempt}`, {
          status: err?.status,
          message: err?.message,
        });

        if (!isGeminiBusyError(err)) {
          throw err;
        }

        await sleep(1200 * attempt);
      }
    }
  }

  const e = new Error(
    'Gemini đang quá tải tạm thời. Vui lòng thử lại sau vài phút.'
  );
  e.status = lastError?.status || 503;
  throw e;
}

async function findMatchedFoodId(conn, detectedName) {
  if (!detectedName) return null;

  const name = String(detectedName).trim();

  const [exact] = await conn.query(
    `SELECT id FROM foods WHERE name = ? LIMIT 1`,
    [name]
  );

  if (exact.length) return exact[0].id;

  const [like] = await conn.query(
    `SELECT id FROM foods
     WHERE name LIKE ?
     ORDER BY id
     LIMIT 1`,
    [`%${name}%`]
  );

  if (like.length) return like[0].id;

  return null;
}

// POST /api/ai/scan-meal
// Body:
// {
//   "image_base64": "...",
//   "mime_type": "image/jpeg"
// }
router.post('/scan-meal', auth, async (req, res) => {
  const conn = await db.getConnection();

  try {
    const imageBase64 = req.body.image_base64;
    const mimeType = req.body.mime_type || 'image/jpeg';

    if (!imageBase64) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu ảnh image_base64',
      });
    }

    await conn.beginTransaction();

    const imageUrl = req.body.image_url || '/uploads/meals/gemini-inline-image.jpg';

    const [imageResult] = await conn.query(
      `INSERT INTO meal_images (user_id, image_url, status)
       VALUES (?, ?, 'analyzed')`,
      [req.user.id, imageUrl]
    );

    const mealImageId = imageResult.insertId;

    const aiResult = await analyzeFoodImageWithGemini(imageBase64, mimeType);

    const items = Array.isArray(aiResult.items) ? aiResult.items : [];

    const estimatedCalories = round2(aiResult.estimated_calories);
    const estimatedProtein = round2(aiResult.estimated_protein);
    const estimatedCarbs = round2(aiResult.estimated_carbs);
    const estimatedFat = round2(aiResult.estimated_fat);
    const confidenceScore = round2(aiResult.confidence_score || 0);

    const [scanResult] = await conn.query(
      `INSERT INTO ai_scan_results
       (meal_image_id, user_id, provider, estimated_calories, estimated_protein,
        estimated_carbs, estimated_fat, confidence_score, status, raw_response_json)
       VALUES (?, ?, 'gemini', ?, ?, ?, ?, ?, 'draft', ?)`,
      [
        mealImageId,
        req.user.id,
        estimatedCalories,
        estimatedProtein,
        estimatedCarbs,
        estimatedFat,
        confidenceScore,
        JSON.stringify(aiResult),
      ]
    );

    const scanResultId = scanResult.insertId;
    const savedItems = [];

    for (const item of items) {
      const detectedName = item.detected_food_name || item.name || 'Món ăn';
      const matchedFoodId = await findMatchedFoodId(conn, detectedName);

      const estimatedAmount = round2(item.estimated_amount || 1);
      const estimatedUnit = item.estimated_unit || 'serving';

      const itemCalories = round2(item.estimated_calories);
      const itemProtein = round2(item.estimated_protein);
      const itemCarbs = round2(item.estimated_carbs);
      const itemFat = round2(item.estimated_fat);
      const itemConfidence = round2(item.confidence_score || 0);

      const [saved] = await conn.query(
        `INSERT INTO ai_scan_result_items
         (ai_scan_result_id, detected_food_name, matched_food_id, estimated_amount,
          estimated_unit, estimated_calories, estimated_protein, estimated_carbs,
          estimated_fat, confidence_score)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          scanResultId,
          detectedName,
          matchedFoodId,
          estimatedAmount,
          estimatedUnit,
          itemCalories,
          itemProtein,
          itemCarbs,
          itemFat,
          itemConfidence,
        ]
      );

      savedItems.push({
        id: saved.insertId,
        detected_food_name: detectedName,
        matched_food_id: matchedFoodId,
        estimated_amount: estimatedAmount,
        estimated_unit: estimatedUnit,
        estimated_calories: itemCalories,
        estimated_protein: itemProtein,
        estimated_carbs: itemCarbs,
        estimated_fat: itemFat,
        confidence_score: itemConfidence,
      });
    }

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'AI đã phân tích ảnh món ăn',
      scan_result_id: scanResultId,
      meal_image_id: mealImageId,
      estimated_calories: estimatedCalories,
      estimated_protein: estimatedProtein,
      estimated_carbs: estimatedCarbs,
      estimated_fat: estimatedFat,
      confidence_score: confidenceScore,
      note: aiResult.note || '',
      items: savedItems,
    });
  } catch (err) {
    await conn.rollback();

    console.error('AI SCAN ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi phân tích ảnh món ăn',
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  } finally {
    conn.release();
  }
});


// POST /api/ai/scan-results/:scanResultId/items/:itemId/add-to-foods
// Giữ nguyên Gemini scan thật, chỉ bổ sung chức năng thêm món AI nhận diện vào thư viện thực phẩm.
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
      error: process.env.NODE_ENV === 'production' ? undefined : err.message,
    });
  } finally {
    conn.release();
  }
});


// GET /api/ai/scan-results/:id
router.get('/scan-results/:id', auth, async (req, res) => {
  try {
    const [results] = await db.query(
      `SELECT *
       FROM ai_scan_results
       WHERE id = ? AND user_id = ?
       LIMIT 1`,
      [req.params.id, req.user.id]
    );

    if (!results.length) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kết quả AI',
      });
    }

    const [items] = await db.query(
      `SELECT *
       FROM ai_scan_result_items
       WHERE ai_scan_result_id = ?
       ORDER BY id`,
      [req.params.id]
    );

    return res.json({
      success: true,
      result: results[0],
      items,
    });
  } catch (err) {
    console.error('GET AI RESULT ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy kết quả AI',
    });
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
      `SELECT *
       FROM ai_scan_results
       WHERE id = ? AND user_id = ? AND status = 'draft'
       LIMIT 1`,
      [req.params.id, req.user.id]
    );

    if (!results.length) {
      await conn.rollback();

      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kết quả AI cần xác nhận',
      });
    }

    const [mealLogResult] = await conn.query(
      `INSERT INTO meal_logs (user_id, meal_type, log_date)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), updated_at = CURRENT_TIMESTAMP`,
      [req.user.id, mealType, logDate]
    );

    const mealLogId = mealLogResult.insertId;

    const [items] = await conn.query(
      `SELECT *
       FROM ai_scan_result_items
       WHERE ai_scan_result_id = ?`,
      [req.params.id]
    );

    for (const item of items) {
      await conn.query(
        `INSERT INTO meal_log_items
         (meal_log_id, food_id, custom_food_name, amount, amount_unit,
          total_calories, total_protein, total_carbs, total_fat, source, ai_scan_result_item_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ai', ?)`,
        [
          mealLogId,
          item.matched_food_id,
          item.matched_food_id ? null : item.detected_food_name,
          item.estimated_amount || 1,
          item.estimated_unit || 'serving',
          item.estimated_calories || 0,
          item.estimated_protein || 0,
          item.estimated_carbs || 0,
          item.estimated_fat || 0,
          item.id,
        ]
      );
    }

    await conn.query(
      `UPDATE ai_scan_results SET status = 'confirmed' WHERE id = ?`,
      [req.params.id]
    );

    await conn.query(
      `UPDATE meal_images SET status = 'confirmed' WHERE id = ?`,
      [results[0].meal_image_id]
    );

    await conn.commit();

    return res.json({
      success: true,
      message: 'Đã xác nhận và lưu bữa ăn từ AI',
      meal_log_id: mealLogId,
    });
  } catch (err) {
    await conn.rollback();

    console.error('CONFIRM AI RESULT ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi xác nhận kết quả AI',
    });
  } finally {
    conn.release();
  }
});

module.exports = router;
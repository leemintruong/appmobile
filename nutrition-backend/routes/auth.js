const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const auth = require('../middleware/auth');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'nutrition_secret_key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function signToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role || 'user' },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ thông tin' });
    }

    if (!/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ success: false, message: 'Email không hợp lệ' });
    }

    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Mật khẩu phải có ít nhất 6 ký tự' });
    }

    const [exists] = await db.query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    if (exists.length) {
      return res.status(409).json({ success: false, message: 'Email đã được sử dụng' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      `INSERT INTO users (name, email, password_hash, role, status)
       VALUES (?, ?, ?, 'user', 'active')`,
      [name, email, passwordHash]
    );

    const user = { id: result.insertId, name, email, role: 'user', status: 'active' };

    return res.status(201).json({
      success: true,
      message: 'Đăng ký thành công',
      token: signToken(user),
      user,
    });
  } catch (err) {
    console.error('REGISTER ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi đăng ký' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập email và mật khẩu' });
    }

    const [rows] = await db.query(
      `SELECT id, name, email, password_hash, role, status
       FROM users
       WHERE email = ?
       LIMIT 1`,
      [email]
    );

    if (!rows.length) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
    }

    const user = rows[0];

    if (user.status !== 'active') {
      return res.status(403).json({ success: false, message: 'Tài khoản không còn hoạt động' });
    }

    let match = false;
    try {
      match = await bcrypt.compare(password, user.password_hash);
    } catch (_) {
      match = false;
    }

    // Chỉ dùng để test sample data trong môi trường dev.
    if (!match && process.env.ALLOW_DEMO_LOGIN === 'true' && password === 'matkhau123') {
      match = true;
    }

    if (!match) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
    }

    return res.json({
      success: true,
      message: 'Đăng nhập thành công',
      token: signToken(user),
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    console.error('LOGIN ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi đăng nhập' });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, name, email, role, status, created_at
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
    }

    return res.json({ success: true, user: rows[0] });
  } catch (err) {
    console.error('ME ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi lấy thông tin tài khoản' });
  }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);

    if (!email) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập email' });
    }

    const [users] = await db.query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);

    if (!users.length) {
      return res.json({ success: true, message: 'Nếu email tồn tại, hệ thống sẽ tạo mã đặt lại mật khẩu' });
    }

    const resetToken = crypto.randomBytes(24).toString('hex');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await db.query(
      `INSERT INTO password_reset_tokens (user_id, token, expires_at)
       VALUES (?, ?, ?)`,
      [users[0].id, resetToken, expiresAt]
    );

    return res.json({
      success: true,
      message: 'Đã tạo mã đặt lại mật khẩu',
      reset_token: process.env.NODE_ENV === 'production' ? undefined : resetToken,
    });
  } catch (err) {
    console.error('FORGOT PASSWORD ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi tạo mã đặt lại mật khẩu' });
  }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req, res) => {
  const conn = await db.getConnection();

  try {
    const token = String(req.body.token || '').trim();
    const password = String(req.body.password || '');

    if (!token || password.length < 6) {
      return res.status(400).json({ success: false, message: 'Token hoặc mật khẩu không hợp lệ' });
    }

    await conn.beginTransaction();

    const [tokens] = await conn.query(
      `SELECT id, user_id
       FROM password_reset_tokens
       WHERE token = ? AND used_at IS NULL AND expires_at > NOW()
       LIMIT 1`,
      [token]
    );

    if (!tokens.length) {
      await conn.rollback();
      return res.status(400).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    await conn.query('UPDATE users SET password_hash = ? WHERE id = ?', [passwordHash, tokens[0].user_id]);
    await conn.query('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = ?', [tokens[0].id]);

    await conn.commit();
    return res.json({ success: true, message: 'Đặt lại mật khẩu thành công' });
  } catch (err) {
    await conn.rollback();
    console.error('RESET PASSWORD ERROR:', err);
    return res.status(500).json({ success: false, message: 'Lỗi server khi đặt lại mật khẩu' });
  } finally {
    conn.release();
  }
});

module.exports = router;

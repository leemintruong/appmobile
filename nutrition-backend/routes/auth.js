const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      });
    }

    const [rows] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email đã được sử dụng',
      });
    }

    const hash = await bcrypt.hash(password, 10);

    const [result] = await db.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hash]
    );

    return res.status(201).json({
      success: true,
      message: 'Đăng ký thành công',
      user: {
        id: result.insertId,
        name,
        email,
      },
    });
  } catch (err) {
    console.error('REGISTER ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi đăng ký',
      error: err.message,
    });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập email và mật khẩu',
      });
    }

    const [rows] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email hoặc mật khẩu không đúng',
      });
    }

    const user = rows[0];

    let match = false;

    try {
      match = await bcrypt.compare(password, user.password);
    } catch (bcryptErr) {
      console.log('BCRYPT COMPARE ERROR:', bcryptErr.message);
      match = false;
    }

    // Chỉ để test dữ liệu mẫu trong SQL của bạn.
    // Vì file SQL đang dùng hash minh họa "$2b$10$examplehash..."
    // Khi làm thật thì nên xóa đoạn fallback này và dùng hash bcrypt thật.
    const isDemoHash =
      typeof user.password === 'string' &&
      user.password.includes('examplehash');

    if (!match && isDemoHash && password === 'matkhau123') {
      match = true;
    }

    if (!match) {
      return res.status(401).json({
        success: false,
        message: 'Email hoặc mật khẩu không đúng',
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
      },
      process.env.JWT_SECRET || 'nutrition_secret_key',
      {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      }
    );

    return res.json({
      success: true,
      message: 'Đăng nhập thành công',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (err) {
    console.error('LOGIN ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi đăng nhập',
      error: err.message,
    });
  }
});

module.exports = router;
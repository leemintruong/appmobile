const router  = require('express').Router();
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const db      = require('../config/db');
require('dotenv').config();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password)
    return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });

  const [rows] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
  if (rows.length > 0)
    return res.status(400).json({ message: 'Email đã được sử dụng' });

  const hash = await bcrypt.hash(password, 10);
  const [result] = await db.query(
    'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
    [name, email, hash]
  );

  res.status(201).json({
    message: 'Đăng ký thành công',
    user: { id: result.insertId, name, email }
  });
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });

  const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  if (rows.length === 0)
    return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });

  const user = rows[0];
  const match = await bcrypt.compare(password, user.password);
  if (!match)
    return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });

  const token = jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );

  res.json({
    message: 'Đăng nhập thành công',
    token,
    user: { id: user.id, name: user.name, email: user.email }
  });
});

module.exports = router;
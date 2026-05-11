const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth',    require('./routes/auth'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/foods',   require('./routes/foods'));
app.use('/api/meals',   require('./routes/meals'));
app.use('/api/weights', require('./routes/weights'));
app.use('/api/reports', require('./routes/reports'));

// Health check
app.get('/', (req, res) => res.json({ status: 'ok', message: 'Nutrition API running' }));

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Lỗi server', error: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`✅ Server đang chạy tại http://localhost:${PORT}`));
-- ============================================================
--  NUTRITION APP — DATABASE SCHEMA + SAMPLE DATA
--  MySQL 8.0+
--  Tạo bởi: Hệ thống Theo dõi Dinh dưỡng Cá nhân
-- ============================================================

-- Tạo và chọn database
CREATE DATABASE IF NOT EXISTS nutrition_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE nutrition_app;

-- ============================================================
-- 1. BẢNG users — Tài khoản người dùng
-- ============================================================
CREATE TABLE users (
  id           INT           NOT NULL AUTO_INCREMENT,
  name         VARCHAR(100)  NOT NULL,
  email        VARCHAR(150)  NOT NULL,
  password     VARCHAR(255)  NOT NULL COMMENT 'bcrypt hash',
  created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. BẢNG user_profiles — Hồ sơ sức khỏe
-- ============================================================
CREATE TABLE user_profiles (
  id             INT     NOT NULL AUTO_INCREMENT,
  user_id        INT     NOT NULL,
  gender         ENUM('male','female','other') NOT NULL,
  age            INT     NOT NULL,
  height         FLOAT   NOT NULL COMMENT 'cm',
  weight         FLOAT   NOT NULL COMMENT 'kg — cân nặng khi thiết lập',
  activity_level ENUM('sedentary','light','moderate','active','very_active')
                         NOT NULL DEFAULT 'moderate',
  PRIMARY KEY (id),
  UNIQUE KEY uq_profile_user (user_id),
  CONSTRAINT fk_profile_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. BẢNG goals — Mục tiêu dinh dưỡng
-- ============================================================
CREATE TABLE goals (
  id                  INT   NOT NULL AUTO_INCREMENT,
  user_id             INT   NOT NULL,
  goal_type           ENUM('lose_weight','gain_weight','maintain','build_muscle')
                            NOT NULL DEFAULT 'maintain',
  target_weight       FLOAT          DEFAULT NULL COMMENT 'kg',
  daily_calorie_goal  INT   NOT NULL COMMENT 'kcal/ngày — tính từ BMR/TDEE',
  daily_protein_goal  INT            DEFAULT NULL COMMENT 'gram',
  daily_carbs_goal    INT            DEFAULT NULL COMMENT 'gram',
  daily_fat_goal      INT            DEFAULT NULL COMMENT 'gram',
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_goal_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. BẢNG foods — Danh mục món ăn / thực phẩm
-- ============================================================
CREATE TABLE foods (
  id           INT           NOT NULL AUTO_INCREMENT,
  name         VARCHAR(200)  NOT NULL,
  calories     FLOAT         NOT NULL COMMENT 'kcal trên 100g',
  protein      FLOAT         NOT NULL DEFAULT 0 COMMENT 'g trên 100g',
  carbs        FLOAT         NOT NULL DEFAULT 0 COMMENT 'g trên 100g',
  fat          FLOAT         NOT NULL DEFAULT 0 COMMENT 'g trên 100g',
  fiber        FLOAT                  DEFAULT 0 COMMENT 'g trên 100g',
  serving_size FLOAT         NOT NULL DEFAULT 100,
  serving_unit VARCHAR(50)   NOT NULL DEFAULT 'g',
  category     VARCHAR(100)           DEFAULT NULL,
  is_verified  TINYINT(1)    NOT NULL DEFAULT 1 COMMENT '1=dữ liệu đã kiểm chứng',
  created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_foods_name     (name),
  KEY idx_foods_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. BẢNG meal_logs — Nhật ký bữa ăn (header)
-- ============================================================
CREATE TABLE meal_logs (
  id         INT    NOT NULL AUTO_INCREMENT,
  user_id    INT    NOT NULL,
  meal_type  ENUM('breakfast','lunch','dinner','snack') NOT NULL,
  log_date   DATE   NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_meal_user_date (user_id, log_date),
  CONSTRAINT fk_meal_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. BẢNG meal_log_items — Chi tiết món trong bữa ăn
-- ============================================================
CREATE TABLE meal_log_items (
  id              INT   NOT NULL AUTO_INCREMENT,
  meal_log_id     INT   NOT NULL,
  food_id         INT   NOT NULL,
  quantity        FLOAT NOT NULL COMMENT 'theo serving_unit của món ăn',
  total_calories  FLOAT NOT NULL,
  total_protein   FLOAT NOT NULL DEFAULT 0,
  total_carbs     FLOAT NOT NULL DEFAULT 0,
  total_fat       FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_item_meal
    FOREIGN KEY (meal_log_id) REFERENCES meal_logs(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_item_food
    FOREIGN KEY (food_id) REFERENCES foods(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. BẢNG weight_logs — Lịch sử cân nặng
-- ============================================================
CREATE TABLE weight_logs (
  id         INT     NOT NULL AUTO_INCREMENT,
  user_id    INT     NOT NULL,
  weight     FLOAT   NOT NULL COMMENT 'kg',
  log_date   DATE    NOT NULL,
  note       VARCHAR(255) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_weight_user_date (user_id, log_date),
  KEY idx_weight_user (user_id),
  CONSTRAINT fk_weight_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. BẢNG notifications — Cài đặt nhắc nhở
-- ============================================================
CREATE TABLE notifications (
  id               INT  NOT NULL AUTO_INCREMENT,
  user_id          INT  NOT NULL,
  breakfast_time   TIME          DEFAULT '07:00:00',
  lunch_time       TIME          DEFAULT '12:00:00',
  dinner_time      TIME          DEFAULT '19:00:00',
  is_enabled       TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notif_user (user_id),
  CONSTRAINT fk_notif_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  SAMPLE DATA
-- ============================================================

-- ------------------------------------------------------------
-- users (mật khẩu là 'matkhau123' — đã hash bcrypt, chỉ minh họa)
-- ------------------------------------------------------------
INSERT INTO users (name, email, password) VALUES
('Nguyễn Thị Lan',  'lan@gmail.com',  '$2b$10$examplehashforlan000000000000000000000000000'),
('Trần Văn Hùng',   'hung@gmail.com', '$2b$10$examplehashforhung00000000000000000000000000'),
('Lê Minh Tú',      'tu@gmail.com',   '$2b$10$examplehashfortu000000000000000000000000000');

-- ------------------------------------------------------------
-- user_profiles
-- ------------------------------------------------------------
INSERT INTO user_profiles (user_id, gender, age, height, weight, activity_level) VALUES
(1, 'female', 25, 162, 65.0, 'sedentary'),
(2, 'male',   22, 175, 70.0, 'active'),
(3, 'female', 30, 158, 58.0, 'light');

-- ------------------------------------------------------------
-- goals
-- Lan: giảm cân → TDEE ≈ 1,740 → mục tiêu 1,500 kcal
-- Hùng: tăng cơ → TDEE ≈ 3,080 → mục tiêu 3,200 kcal
-- Tú:  giữ cân  → TDEE ≈ 1,820 → mục tiêu 1,820 kcal
-- ------------------------------------------------------------
INSERT INTO goals (user_id, goal_type, target_weight, daily_calorie_goal,
                   daily_protein_goal, daily_carbs_goal, daily_fat_goal) VALUES
(1, 'lose_weight',  58.0, 1500,  80, 170, 45),
(2, 'build_muscle', 75.0, 3200, 160, 360, 90),
(3, 'maintain',     NULL, 1820,  90, 200, 55);

-- ------------------------------------------------------------
-- foods — món ăn Việt Nam + thực phẩm phổ biến
-- (tất cả giá trị dinh dưỡng tính trên 100g trừ khi ghi chú)
-- ------------------------------------------------------------
INSERT INTO foods (name, calories, protein, carbs, fat, fiber,
                   serving_size, serving_unit, category) VALUES
-- Tinh bột / Cơm bún phở
('Cơm trắng',           130, 2.7, 28.0,  0.3, 0.4, 100, 'g',   'Tinh bột'),
('Cơm gạo lứt',         111, 2.6, 23.0,  0.9, 1.8, 100, 'g',   'Tinh bột'),
('Bún tươi',            109, 2.5, 25.0,  0.2, 0.3, 100, 'g',   'Tinh bột'),
('Phở (bánh phở)',      108, 2.4, 24.5,  0.2, 0.2, 100, 'g',   'Tinh bột'),
('Bánh mì trắng',       265, 9.0, 49.0,  3.2, 2.7, 100, 'g',   'Tinh bột'),
('Khoai lang luộc',      86, 1.6, 20.0,  0.1, 3.0, 100, 'g',   'Tinh bột'),
('Yến mạch (oats)',     389,16.9, 66.3,  6.9,10.6, 100, 'g',   'Tinh bột'),

-- Thịt
('Ức gà luộc',          165,31.0,  0.0,  3.6, 0.0, 100, 'g',   'Thịt'),
('Đùi gà luộc',         209,26.0,  0.0, 11.0, 0.0, 100, 'g',   'Thịt'),
('Thịt heo nạc',        143,26.0,  0.0,  3.5, 0.0, 100, 'g',   'Thịt'),
('Thịt bò nạc',         250,26.0,  0.0, 15.0, 0.0, 100, 'g',   'Thịt'),
('Thịt bò băm',         215,22.0,  0.0, 13.0, 0.0, 100, 'g',   'Thịt'),

-- Hải sản & Cá
('Cá hồi',              208,20.0,  0.0, 13.0, 0.0, 100, 'g',   'Cá'),
('Cá ngừ (đóng hộp)',   132,29.0,  0.0,  1.0, 0.0, 100, 'g',   'Cá'),
('Tôm luộc',             99,21.0,  0.0,  1.1, 0.0, 100, 'g',   'Hải sản'),
('Mực xào',             175,18.0,  4.0,  9.0, 0.0, 100, 'g',   'Hải sản'),

-- Trứng & Đậu
('Trứng gà',            155,13.0,  1.1, 11.0, 0.0,  60, 'quả', 'Trứng'),
('Trứng vịt',           185,13.0,  1.0, 14.0, 0.0,  65, 'quả', 'Trứng'),
('Đậu hũ (tofu)',        76, 8.0,  1.9,  4.2, 0.3, 100, 'g',   'Đậu'),
('Đậu đen luộc',        132, 8.9, 23.7,  0.5, 8.7, 100, 'g',   'Đậu'),

-- Rau củ
('Rau muống xào',        45, 3.0,  5.0,  2.0, 1.8, 100, 'g',   'Rau'),
('Bắp cải luộc',         25, 1.3,  5.8,  0.1, 2.5, 100, 'g',   'Rau'),
('Cà rốt',               41, 0.9,  9.6,  0.2, 2.8, 100, 'g',   'Rau'),
('Bông cải xanh',        34, 2.8,  6.6,  0.4, 2.6, 100, 'g',   'Rau'),
('Cà chua',              18, 0.9,  3.9,  0.2, 1.2, 100, 'g',   'Rau'),
('Dưa chuột',            15, 0.7,  3.6,  0.1, 0.5, 100, 'g',   'Rau'),

-- Trái cây
('Chuối',                89, 1.1, 23.0,  0.3, 2.6, 120, 'quả', 'Trái cây'),
('Táo',                  52, 0.3, 14.0,  0.2, 2.4, 150, 'quả', 'Trái cây'),
('Cam',                  47, 0.9, 12.0,  0.1, 2.4, 130, 'quả', 'Trái cây'),
('Dưa hấu',              30, 0.6,  7.6,  0.2, 0.4, 100, 'g',   'Trái cây'),
('Xoài',                 60, 0.8, 15.0,  0.4, 1.6, 100, 'g',   'Trái cây'),

-- Sữa & chế phẩm
('Sữa tươi không đường', 42, 3.4,  5.0,  1.0, 0.0, 200, 'ml',  'Sữa'),
('Sữa chua không đường', 59, 3.5,  5.0,  3.3, 0.0, 100, 'g',   'Sữa'),
('Phô mai',             402,25.0,  1.3, 33.0, 0.0,  30, 'lát', 'Sữa'),

-- Các món Việt đặc trưng (tính theo khẩu phần thực tế)
('Phở bò (1 tô)',       215,14.0, 28.0,  5.0, 1.0, 400, 'tô',  'Món Việt'),
('Bún bò Huế (1 tô)',   190,12.0, 26.0,  4.5, 0.8, 350, 'tô',  'Món Việt'),
('Bánh mì thịt (1 ổ)',  280,13.0, 38.0,  8.0, 2.0, 150, 'ổ',   'Món Việt'),
('Bánh cuốn (1 phần)',  165, 8.0, 28.0,  3.5, 0.5, 200, 'g',   'Món Việt'),
('Cơm tấm sườn',        520,28.0, 65.0, 16.0, 1.5, 350, 'phần','Món Việt'),
('Bún chả (1 phần)',    410,25.0, 45.0, 14.0, 1.2, 300, 'phần','Món Việt'),
('Gỏi cuốn (1 cuốn)',    85, 5.0, 12.0,  2.0, 1.0,  80, 'cuốn','Món Việt'),
('Chả giò (1 cái)',     120, 4.0, 11.0,  7.0, 0.5,  50, 'cái', 'Món Việt'),

-- Đồ uống
('Nước cam tươi',        45, 0.7, 10.4,  0.2, 0.2, 200, 'ml',  'Đồ uống'),
('Sinh tố chuối',       120, 2.0, 27.0,  0.5, 1.5, 250, 'ml',  'Đồ uống'),
('Cà phê đen (không đường)', 2, 0.3,  0.0,  0.0, 0.0, 200, 'ml',  'Đồ uống'),
('Trà sữa trân châu',   250, 2.5, 42.0,  7.0, 0.0, 350, 'ml',  'Đồ uống'),

-- Snack / Phụ
('Hạnh nhân',           579,21.0, 22.0, 50.0,12.5,  30, 'g',   'Snack'),
('Thanh protein bar',   200,20.0, 22.0,  7.0, 3.0,  60, 'g',   'Snack'),
('Bánh gạo lứt',        387, 8.0, 82.0,  3.0, 4.0,  30, 'g',   'Snack');

-- ------------------------------------------------------------
-- meal_logs — Dữ liệu mẫu cho user 1 (Lan) trong 3 ngày
-- ------------------------------------------------------------
INSERT INTO meal_logs (user_id, meal_type, log_date) VALUES
-- Ngày 08/05
(1, 'breakfast', '2026-05-08'),  -- id=1
(1, 'lunch',     '2026-05-08'),  -- id=2
(1, 'dinner',    '2026-05-08'),  -- id=3
-- Ngày 09/05
(1, 'breakfast', '2026-05-09'),  -- id=4
(1, 'lunch',     '2026-05-09'),  -- id=5
(1, 'snack',     '2026-05-09'),  -- id=6
-- Ngày 10/05
(1, 'breakfast', '2026-05-10'),  -- id=7
(1, 'lunch',     '2026-05-10');  -- id=8

-- ------------------------------------------------------------
-- meal_log_items — Chi tiết bữa ăn
-- Công thức: total = (giá trị / 100) × quantity
-- ------------------------------------------------------------
INSERT INTO meal_log_items
  (meal_log_id, food_id, quantity, total_calories, total_protein, total_carbs, total_fat)
VALUES
-- 08/05 Bữa sáng (meal_log_id=1): Cơm trắng 200g + Trứng gà 1 quả + Rau muống 100g
(1, 1,  200, 260.0,  5.4, 56.0,  0.6),  -- cơm trắng 200g
(1, 17,  60,  93.0,  7.8,  0.7,  6.6),  -- trứng gà 1 quả (60g)
(1, 21, 100,  45.0,  3.0,  5.0,  2.0),  -- rau muống 100g

-- 08/05 Bữa trưa (meal_log_id=2): Phở bò 1 tô
(2, 35, 400, 860.0, 56.0,112.0, 20.0),  -- phở bò 1 tô 400g

-- 08/05 Bữa tối (meal_log_id=3): Cơm 150g + Ức gà 120g + Bắp cải 100g
(3, 1,  150, 195.0,  4.1, 42.0,  0.5),
(3, 8,  120, 198.0, 37.2,  0.0,  4.3),
(3, 22, 100,  25.0,  1.3,  5.8,  0.1),

-- 09/05 Bữa sáng (meal_log_id=4): Yến mạch 80g + Chuối 1 quả + Sữa tươi 200ml
(4, 7,   80, 311.2, 13.5, 53.0,  5.5),
(4, 27, 120, 106.8,  1.3, 27.6,  0.4),
(4, 31, 200,  84.0,  6.8, 10.0,  2.0),

-- 09/05 Bữa trưa (meal_log_id=5): Cơm tấm sườn 1 phần
(5, 39, 350, 520.0, 28.0, 65.0, 16.0),

-- 09/05 Snack (meal_log_id=6): Sữa chua 100g + Táo 1 quả
(6, 32, 100,  59.0,  3.5,  5.0,  3.3),
(6, 28, 150,  78.0,  0.5, 21.0,  0.3),

-- 10/05 Bữa sáng (meal_log_id=7): Bánh mì thịt 1 ổ + Nước cam 200ml
(7, 36, 150, 280.0, 13.0, 38.0,  8.0),
(7, 43, 200,  90.0,  1.4, 20.8,  0.4),

-- 10/05 Bữa trưa (meal_log_id=8): Bún chả 1 phần
(8, 40, 300, 410.0, 25.0, 45.0, 14.0);

-- ------------------------------------------------------------
-- weight_logs — Lịch sử cân nặng của Lan (user 1)
-- ------------------------------------------------------------
INSERT INTO weight_logs (user_id, weight, log_date, note) VALUES
(1, 65.0, '2026-04-10', 'Bắt đầu theo dõi'),
(1, 64.5, '2026-04-17', NULL),
(1, 64.1, '2026-04-24', NULL),
(1, 63.8, '2026-05-01', 'Giảm được 1.2kg sau 3 tuần'),
(1, 63.2, '2026-05-05', NULL),
(1, 62.8, '2026-05-10', 'Tiến triển tốt!');

-- weight_logs cho Hùng (user 2) — tăng cân
INSERT INTO weight_logs (user_id, weight, log_date, note) VALUES
(2, 70.0, '2026-04-10', 'Mục tiêu 75kg'),
(2, 70.5, '2026-04-17', NULL),
(2, 71.2, '2026-04-24', NULL),
(2, 71.8, '2026-05-01', NULL),
(2, 72.3, '2026-05-10', 'Tăng 2.3kg sau 1 tháng');

-- ------------------------------------------------------------
-- notifications — Cài đặt nhắc nhở mặc định
-- ------------------------------------------------------------
INSERT INTO notifications (user_id, breakfast_time, lunch_time, dinner_time, is_enabled)
VALUES
(1, '07:00:00', '12:00:00', '19:00:00', 1),
(2, '06:30:00', '12:00:00', '18:30:00', 1),
(3, '07:30:00', '12:30:00', '19:30:00', 0);


-- ============================================================
--  VIEWS — Truy vấn tổng hợp thường dùng
-- ============================================================

-- View: Tổng dinh dưỡng theo ngày của từng user
CREATE OR REPLACE VIEW v_daily_nutrition AS
SELECT
  ml.user_id,
  ml.log_date,
  ROUND(SUM(mli.total_calories), 1)  AS total_calories,
  ROUND(SUM(mli.total_protein),  1)  AS total_protein,
  ROUND(SUM(mli.total_carbs),    1)  AS total_carbs,
  ROUND(SUM(mli.total_fat),      1)  AS total_fat
FROM meal_logs ml
JOIN meal_log_items mli ON mli.meal_log_id = ml.id
GROUP BY ml.user_id, ml.log_date;

-- View: Tổng dinh dưỡng theo từng bữa trong ngày
CREATE OR REPLACE VIEW v_meal_summary AS
SELECT
  ml.id          AS meal_log_id,
  ml.user_id,
  ml.log_date,
  ml.meal_type,
  ROUND(SUM(mli.total_calories), 1) AS total_calories,
  ROUND(SUM(mli.total_protein),  1) AS total_protein,
  ROUND(SUM(mli.total_carbs),    1) AS total_carbs,
  ROUND(SUM(mli.total_fat),      1) AS total_fat,
  COUNT(mli.id)                     AS item_count
FROM meal_logs ml
JOIN meal_log_items mli ON mli.meal_log_id = ml.id
GROUP BY ml.id, ml.user_id, ml.log_date, ml.meal_type;

-- View: Tiến trình cân nặng kèm thay đổi so với lần trước
CREATE OR REPLACE VIEW v_weight_progress AS
SELECT
  wl.user_id,
  wl.log_date,
  wl.weight,
  ROUND(wl.weight - LAG(wl.weight) OVER (
    PARTITION BY wl.user_id ORDER BY wl.log_date
  ), 1) AS change_kg,
  wl.note
FROM weight_logs wl;


-- ============================================================
--  STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- SP: Lấy toàn bộ bữa ăn + món trong ngày của 1 user
CREATE PROCEDURE sp_get_daily_meals(
  IN p_user_id  INT,
  IN p_log_date DATE
)
BEGIN
  SELECT
    ml.id          AS meal_log_id,
    ml.meal_type,
    f.name         AS food_name,
    mli.quantity,
    f.serving_unit,
    mli.total_calories,
    mli.total_protein,
    mli.total_carbs,
    mli.total_fat
  FROM meal_logs ml
  JOIN meal_log_items mli ON mli.meal_log_id = ml.id
  JOIN foods f            ON f.id = mli.food_id
  WHERE ml.user_id  = p_user_id
    AND ml.log_date = p_log_date
  ORDER BY
    FIELD(ml.meal_type,'breakfast','lunch','dinner','snack'),
    ml.id;
END$$

-- SP: Thêm bữa ăn và tự động tính dinh dưỡng từ bảng foods
CREATE PROCEDURE sp_add_meal_item(
  IN p_meal_log_id INT,
  IN p_food_id     INT,
  IN p_quantity    FLOAT  -- theo serving_unit của món
)
BEGIN
  DECLARE v_cal   FLOAT;
  DECLARE v_pro   FLOAT;
  DECLARE v_carb  FLOAT;
  DECLARE v_fat   FLOAT;

  SELECT
    ROUND((calories / 100) * p_quantity, 2),
    ROUND((protein  / 100) * p_quantity, 2),
    ROUND((carbs    / 100) * p_quantity, 2),
    ROUND((fat      / 100) * p_quantity, 2)
  INTO v_cal, v_pro, v_carb, v_fat
  FROM foods WHERE id = p_food_id;

  INSERT INTO meal_log_items
    (meal_log_id, food_id, quantity, total_calories,
     total_protein, total_carbs, total_fat)
  VALUES
    (p_meal_log_id, p_food_id, p_quantity,
     v_cal, v_pro, v_carb, v_fat);
END$$

-- SP: Tính calo mục tiêu theo Mifflin-St Jeor + hệ số vận động
CREATE PROCEDURE sp_calc_daily_calorie(
  IN  p_user_id      INT,
  IN  p_goal_type    VARCHAR(20),
  OUT p_calorie_goal INT
)
BEGIN
  DECLARE v_w      FLOAT;
  DECLARE v_h      FLOAT;
  DECLARE v_age    INT;
  DECLARE v_gender VARCHAR(10);
  DECLARE v_act    VARCHAR(20);
  DECLARE v_bmr    FLOAT;
  DECLARE v_tdee   FLOAT;
  DECLARE v_factor FLOAT DEFAULT 1.55;

  SELECT weight, height, age, gender, activity_level
  INTO   v_w, v_h, v_age, v_gender, v_act
  FROM   user_profiles WHERE user_id = p_user_id;

  -- BMR theo Mifflin-St Jeor
  IF v_gender = 'male' THEN
    SET v_bmr = 10 * v_w + 6.25 * v_h - 5 * v_age + 5;
  ELSE
    SET v_bmr = 10 * v_w + 6.25 * v_h - 5 * v_age - 161;
  END IF;

  -- Hệ số vận động
  SET v_factor = CASE v_act
    WHEN 'sedentary'  THEN 1.2
    WHEN 'light'      THEN 1.375
    WHEN 'moderate'   THEN 1.55
    WHEN 'active'     THEN 1.725
    WHEN 'very_active'THEN 1.9
    ELSE 1.55
  END;

  SET v_tdee = v_bmr * v_factor;

  -- Điều chỉnh theo mục tiêu
  SET p_calorie_goal = ROUND(CASE p_goal_type
    WHEN 'lose_weight'  THEN v_tdee - 500
    WHEN 'gain_weight'  THEN v_tdee + 300
    WHEN 'build_muscle' THEN v_tdee + 200
    ELSE v_tdee
  END);
END$$

DELIMITER ;


-- ============================================================
--  SAMPLE QUERIES — Truy vấn tham khảo
-- ============================================================

-- 1. Tổng dinh dưỡng hôm nay của user 1
-- SELECT * FROM v_daily_nutrition WHERE user_id = 1 AND log_date = CURDATE();

-- 2. Tóm tắt từng bữa hôm nay
-- SELECT * FROM v_meal_summary WHERE user_id = 1 AND log_date = CURDATE();

-- 3. Tiến trình cân nặng của user 1
-- SELECT * FROM v_weight_progress WHERE user_id = 1 ORDER BY log_date;

-- 4. Tìm kiếm món ăn theo tên
-- SELECT id, name, calories, protein, carbs, fat
-- FROM foods WHERE name LIKE '%gà%' ORDER BY name;

-- 5. Trung bình calo 7 ngày qua
-- SELECT ROUND(AVG(total_calories),0) AS avg_cal_7days
-- FROM v_daily_nutrition
-- WHERE user_id = 1 AND log_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);

-- 6. Gọi stored procedure thêm bữa ăn
-- CALL sp_add_meal_item(7, 8, 150);  -- meal_log_id=7, ức gà 150g

-- 7. Tính calo mục tiêu cho user 1
-- CALL sp_calc_daily_calorie(1, 'lose_weight', @goal);
-- SELECT @goal AS calorie_goal;

-- ============================================================
--  END OF FILE
-- ============================================================
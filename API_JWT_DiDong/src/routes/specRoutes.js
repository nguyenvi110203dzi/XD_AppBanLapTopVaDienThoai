const express = require('express');
const router = express.Router();
const {
    upsertCauHinhBonho,
    upsertCameraManhinh,
    upsertPinSac,
} = require('../controllers/specController'); // Import controller mới
const { protect } = require('../middleware/authMiddleware'); // Middleware xác thực
const { admin } = require('../middleware/roleMiddleware'); // Middleware phân quyền admin

// Áp dụng middleware protect và admin cho tất cả các route trong file này
router.use(protect, admin);

// Định nghĩa các route PUT cho việc cập nhật/tạo thông số kỹ thuật
// Sử dụng PUT vì hành động này mang tính chất idempotent (gọi nhiều lần với cùng data cho kết quả như nhau)
// và thường dùng để cập nhật hoặc thay thế toàn bộ tài nguyên con.
router.put('/products/:productId/cauhinh', upsertCauHinhBonho);
router.put('/products/:productId/camera', upsertCameraManhinh);
router.put('/products/:productId/pinsac', upsertPinSac);

module.exports = router;

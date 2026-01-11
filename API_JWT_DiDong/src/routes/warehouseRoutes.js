const express = require('express');
const router = express.Router();
const {
  importStock,
  exportStock,
  getOverallProductQuantity,
  getProductStockHistory
} = require('../controllers/warehouseController');
const { protect } = require('../middleware/authMiddleware');
// <<--- Đảm bảo bạn chỉ import 'admin' và 'warehouseStaff' một lần
const { admin, warehouseStaff } = require('../middleware/roleMiddleware');

// API cho Nhân viên kho (role 3) HOẶC Admin (role 1)
// Điều này có nghĩa là nếu một route dùng warehouseStaff, Admin cũng có thể truy cập nếu logic trong warehouseStaff cho phép
router.post('/import', protect, warehouseStaff, importStock);
router.post('/export', protect, warehouseStaff, exportStock);

// API CHỈ cho Admin (role 1)
router.get('/products/total-quantity', protect, admin, getOverallProductQuantity);
router.get('/products/:productId/history', protect, admin, getProductStockHistory);

module.exports = router;
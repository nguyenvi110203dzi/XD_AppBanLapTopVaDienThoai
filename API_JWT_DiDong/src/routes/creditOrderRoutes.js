const express = require('express');
const router = express.Router();
const {
  createCreditOrder,
  getMyCreditOrders,
  getCreditOrderByIdForCustomer, // Khách hàng xem chi tiết đơn của mình
  // Admin controllers
  getAllCreditOrders,
  getCreditOrderByIdForAdmin,
  updateCreditOrder
} = require('../controllers/creditOrderController'); // Sẽ tạo controller này ở bước sau

const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/roleMiddleware'); // Middleware cho admin
const { checkCreditCustomerRole } = require('../middleware/checkCreditCustomerRole'); // Middleware mới

// === Routes cho Khách hàng Công Nợ (role = 2) ===
router.post('/', protect, checkCreditCustomerRole, createCreditOrder);
router.get('/my-history', protect, checkCreditCustomerRole, getMyCreditOrders); // Khách hàng role 2 xem lịch sử của mình
router.get('/my-history/:id', protect, checkCreditCustomerRole, getCreditOrderByIdForCustomer); // Khách hàng role 2 xem chi tiết đơn của mình

// === Routes cho Admin Quản lý Đơn Công Nợ ===
router.get('/admin', protect, admin, getAllCreditOrders); // Admin xem tất cả
router.get('/admin/:id', protect, admin, getCreditOrderByIdForAdmin); // Admin xem chi tiết
router.put('/admin/:id', protect, admin, updateCreditOrder); // Admin cập nhật (ngày hẹn trả, trạng thái)

module.exports = router;
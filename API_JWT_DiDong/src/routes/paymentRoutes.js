const express = require('express');
const router = express.Router();
const {
  createVnpayPaymentUrl,
  vnpayIpn,
  vnpayReturn,
} = require('../controllers/paymentController'); // Import controller thanh toán
const { protect } = require('../middleware/authMiddleware'); // Middleware xác thực

// Route tạo URL thanh toán VNPAY (Yêu cầu user đăng nhập)
// Frontend sẽ gọi API này sau khi đơn hàng được tạo (với paymentMethod=1)
router.post('/vnpay/create_url', protect, createVnpayPaymentUrl);

// Route xử lý IPN từ VNPAY (VNPAY Server gọi đến, không cần xác thực user)
// URL này cần được cấu hình trong tài khoản VNPAY Merchant
router.get('/vnpay/ipn', vnpayIpn);

// Route xử lý khi người dùng được VNPAY chuyển hướng về (Không cần xác thực user)
// URL này được cấu hình trong tham số vnp_ReturnUrl khi tạo URL thanh toán
router.get('/vnpay/return', vnpayReturn);

module.exports = router;

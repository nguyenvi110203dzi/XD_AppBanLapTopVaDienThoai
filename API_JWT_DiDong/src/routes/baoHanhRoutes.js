// src/routes/baoHanhRoutes.js
const express = require('express');
const router = express.Router();
const {
  createBaoHanh,
  getAllBaoHanh,
  searchBaoHanh,
  updateBaoHanh,
  getBaoHanhById
} = require('../controllers/baoHanhController'); // Sửa tên controller cho nhất quán
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/roleMiddleware');

// Tất cả các route này yêu cầu đăng nhập và quyền admin
router.use(protect, admin);

router.route('/')
  .post(createBaoHanh)
  .get(getAllBaoHanh);

router.get('/search', searchBaoHanh);

router.route('/:id')
  .get(getBaoHanhById)
  .put(updateBaoHanh);

module.exports = router;
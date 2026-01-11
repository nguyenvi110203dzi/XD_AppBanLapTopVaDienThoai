const express = require('express');
const router = express.Router();
const {
  getAllSpecs,
  getSpecById,
  createSpec,
  updateSpec,
  deleteSpec,
} = require('../controllers/adminSpecController'); // Import controller mới
const { protect } = require('../middleware/authMiddleware'); // Middleware xác thực
const { admin } = require('../middleware/roleMiddleware'); // Middleware phân quyền admin

// Áp dụng middleware protect và admin cho tất cả các route trong file này
router.use(protect, admin);

// --- Routes cho CRUD thông số kỹ thuật ---
// :specType sẽ là 'cauhinh', 'camera', hoặc 'pinsac'

// GET all specs of a type
router.get('/spec/:specType', getAllSpecs);

// GET a single spec by ID
router.get('/spec/:specType/:id', getSpecById);

// POST (Create) a new spec
router.post('/spec/:specType', createSpec);

// PUT (Update) a spec by ID
router.put('/spec/:specType/:id', updateSpec);

// DELETE a spec by ID
router.delete('/spec/:specType/:id', deleteSpec);


module.exports = router;

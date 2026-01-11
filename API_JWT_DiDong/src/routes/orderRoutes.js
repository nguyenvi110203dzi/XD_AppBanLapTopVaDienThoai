const express = require('express');
const router = express.Router();
const {
    getAllOrders,
    getOrderById,
    getUserOrders,
    createOrder,
    updateOrderStatus,
    deleteOrder,
    getOrderDetails
} = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/roleMiddleware');

// Public routes
router.get('/details/:orderId', getOrderDetails);

// User routes
router.get('/myorders', protect, getUserOrders);
router.post('/', protect, createOrder);

// Admin routes
router.get('/', protect, admin, getAllOrders);
router.get('/:id', protect, getOrderById);
router.put('/:id/status', protect, admin, updateOrderStatus);
router.delete('/:id', protect, admin, deleteOrder);

module.exports = router;

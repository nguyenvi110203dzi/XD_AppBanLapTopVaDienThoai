const express = require('express');
const router = express.Router();
const {
  getAllProducts,
  getAllProductsCategory1,
  getNewProducts,
  getProductsByBrandLimit,
  getProductsByBrand,
  getProductsByCategoryLimit,
  getProductsByCategory,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  searchProductsByName,
} = require('../controllers/productController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/roleMiddleware');
const multer = require('multer');
const path = require('path');

// Set up multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadPath = path.join(__dirname, '../uploads/products/');
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    cb(null, `product-${Date.now()}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: function (req, file, cb) {
    const filetypes = /jpeg|jpg|png/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb('Error: Images only (jpeg, jpg, png)!');
    }
  }
});

// Public routes
router.get('/', getAllProducts);
router.get('/category1', getAllProductsCategory1);
router.get('/new', getNewProducts);
router.get('/search', searchProductsByName);
router.get('/brand/:brandId/limit', getProductsByBrandLimit);
router.get('/brand/:brandId', getProductsByBrand);
router.get('/category/:categoryId/limit', getProductsByCategoryLimit);
router.get('/category/:categoryId', getProductsByCategory);
router.get('/:id', getProductById);

// Admin routes
router.post('/', protect, admin, upload.single('image'), createProduct);
router.put('/:id', protect, admin, upload.single('image'), updateProduct);
router.delete('/:id', protect, admin, deleteProduct);
module.exports = router;
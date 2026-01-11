const { Product, Brand, Category, Cauhinh_bonho, Camera_manhinh, Pin_sac } = require('../models');
const { Op } = require('sequelize');

// @desc    Get all products
// @route   GET /api/products
// @access  Public
const getAllProducts = async (req, res) => {
  try {
    const products = await Product.findAll({
      order: [['createdAt', 'DESC']]
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch all products in category 1
// @route   GET /api/products/category1
// @access  Public
const getAllProductsCategory1 = async (req, res) => {
  try {
    const products = await Product.findAll({
      where: { category_id: 1 },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] },
        { model: Cauhinh_bonho, },
        { model: Camera_manhinh, },
        { model: Pin_sac, },
      ]
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch latest 8 products
// @route   GET /api/products/new
// @access  Public
const getNewProducts = async (req, res) => {
  try {
    const products = await Product.findAll({
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ],
      order: [['createdAt', 'DESC']],
      limit: 8
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch 8 products by brand
// @route   GET /api/products/brand/:brandId/limit
// @access  Public
const getProductsByBrandLimit = async (req, res) => {
  try {
    const { brandId } = req.params;

    const products = await Product.findAll({
      where: { brand_id: brandId },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ],
      limit: 8
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch all products by brand
// @route   GET /api/products/brand/:brandId
// @access  Public
const getProductsByBrand = async (req, res) => {
  try {
    const { brandId } = req.params;

    const products = await Product.findAll({
      where: { brand_id: brandId },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ]
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch 8 products by category
// @route   GET /api/products/category/:categoryId/limit
// @access  Public
const getProductsByCategoryLimit = async (req, res) => {
  try {
    const { categoryId } = req.params;

    const products = await Product.findAll({
      where: { category_id: categoryId },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ],
      limit: 8
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch all products by category
// @route   GET /api/products/category/:categoryId
// @access  Public
const getProductsByCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;

    const products = await Product.findAll({
      where: { category_id: categoryId },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ]
    });

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Fetch product details by ID
// @route   GET /api/products/:id
// @access  Public
const getProductById = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await Product.findByPk(id, {
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ]
    });

    if (product) {
      res.json(product);
    } else {
      res.status(404).json({ message: 'Product not found' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};


// @desc    Fetch products by brand_id = 2
// @route   GET /api/products/productsBrandId2
// @access  Public
const getProductBrandById2 = async (req, res) => {
  try {
    const { brandId } = 2;
    // xuat ra danh sach san pham theo brand_id = 2
    const productsBrandId2 = await Product.findAll({
      where: { brand_id: brandId },
      include: [
        { model: Brand, attributes: ['id', 'name'] }, // Lấy thông tin từ bảng Brand
        { model: Category, attributes: ['id', 'name'] } // Lấy thông tin từ bảng Category
      ],
    });
    res.json(productsBrandId2);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};


// @desc    Create a product
// @route   POST /api/products
// @access  Private/Admin
const createProduct = async (req, res) => {
  try {
    const {
      name,
      price,
      oldprice,
      description,
      specification,
      quantity,
      brand_id,
      category_id
    } = req.body;

    let imagePath = null;
    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/products/${filename}`;
    }

    const product = await Product.create({
      name,
      price,
      oldprice,
      image: imagePath,
      description,
      specification,
      quantity,
      brand_id,
      category_id
    });

    res.status(201).json(product);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update a product
// @route   PUT /api/products/:id
// @access  Private/Admin
const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findByPk(id);

    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    const {
      name,
      price,
      oldprice,
      description,
      specification,
      quantity,
      brand_id,
      category_id
    } = req.body;

    let imagePath = product.image;
    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/products/${filename}`;
    }

    product.name = name || product.name;
    product.price = price || product.price;
    product.oldprice = oldprice || product.oldprice;
    product.image = imagePath;
    product.description = description || product.description;
    product.specification = specification || product.specification;
    product.quantity = quantity || product.quantity;
    product.brand_id = brand_id || product.brand_id;
    product.category_id = category_id || product.category_id;


    const updatedProduct = await product.save();
    res.json(updatedProduct);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a product
// @route   DELETE /api/products/:id
// @access  Private/Admin
const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findByPk(id);

    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    await product.destroy();
    res.json({ message: 'Product removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Search products by name
// @route   GET /api/products/search?name=<searchTerm>
// @access  Public
const searchProductsByName = async (req, res) => {
  try {
    const searchTerm = req.query.name;

    if (!searchTerm) {
      return res.status(400).json({ message: 'Search term query parameter "name" is required' });
    }

    const products = await Product.findAll({
      where: {
        name: {
          [Op.like]: `%${searchTerm}%`
        }
      },
      include: [
        { model: Brand, attributes: ['id', 'name'] },
        { model: Category, attributes: ['id', 'name'] }
      ],
      order: [['name', 'ASC']]
    });

    res.json(products);
  } catch (error) {
    console.error('Error searching products:', error);
    res.status(500).json({ message: 'Server Error during product search' });
  }
};



module.exports = {
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
};
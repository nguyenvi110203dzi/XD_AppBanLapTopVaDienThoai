const { Brand, Product } = require('../models');

// @desc    Get all brands
// @route   GET /api/brands
// @access  Public
const getBrands = async (req, res) => {
  try {
    const brands = await Brand.findAll({
      order: [['name', 'ASC']]
    });
    res.json(brands);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get brand by ID
// @route   GET /api/brands/:id
// @access  Public
const getBrandById = async (req, res) => {
  try {
    const { id } = req.params;

    const brand = await Brand.findByPk(id);

    if (brand) {
      res.json(brand);
    } else {
      res.status(404).json({ message: 'Brand not found' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Create a brand
// @route   POST /api/brands
// @access  Private/Admin
const createBrand = async (req, res) => {
  try {
    const { name } = req.body;

    let imagePath = null;

    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/brands/${filename}`;
    }

    const brand = await Brand.create({
      name,
      image: imagePath
    });

    res.status(201).json(brand);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update a brand
// @route   PUT /api/brands/:id
// @access  Private/Admin
const updateBrand = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    const brand = await Brand.findByPk(id);

    if (!brand) {
      return res.status(404).json({ message: 'Brand not found' });
    }
    if (!brand) {
      return res.status(404).json({ message: 'Brand not found' });
    }

    let imagePath = brand.image;
    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/brands/${filename}`;
    }

    brand.name = name || brand.name;
    brand.image = imagePath;
    await brand.save();

    res.json(brand);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a brand
// @route   DELETE /api/brands/:id
// @access  Private/Admin
const deleteBrand = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if any products use this brand
    const productsWithBrand = await Product.count({ where: { brand_id: id } });

    if (productsWithBrand > 0) {
      return res.status(400).json({
        message: 'Cannot delete brand that has products associated with it'
      });
    }

    const brand = await Brand.findByPk(id);

    if (!brand) {
      return res.status(404).json({ message: 'Brand not found' });
    }

    await brand.destroy();

    res.json({ message: 'Brand removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

module.exports = {
  getBrands,
  getBrandById,
  createBrand,
  updateBrand,
  deleteBrand
};
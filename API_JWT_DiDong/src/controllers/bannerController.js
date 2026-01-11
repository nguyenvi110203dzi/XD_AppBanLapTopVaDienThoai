const { Banner } = require('../models');

// @desc    Get all banners
// @route   GET /api/banners
// @access  Public
const getBanners = async (req, res) => {
  try {
    const banners = await Banner.findAll({
      where: { status: 1 }, // Only active banners
      order: [['createdAt', 'DESC']]
    });
    res.json(banners);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get all banners (including inactive ones) for admin
// @route   GET /api/banners/admin
// @access  Private/Admin
const getAllBanners = async (req, res) => {
  try {
    const banners = await Banner.findAll({
      order: [['createdAt', 'DESC']]
    });
    res.json(banners);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Create a banner
// @route   POST /api/banners
// @access  Private/Admin
const createBanner = async (req, res) => {
  try {
    const { name, status } = req.body;

    let imagePath = null;
    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/banners/${filename}`;
    }

    const banner = await Banner.create({
      name,
      image: imagePath,
      status: status || 1
    });

    res.status(201).json(banner);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update a banner
// @route   PUT /api/banners/:id
// @access  Private/Admin
const updateBanner = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, status } = req.body;

    const banner = await Banner.findByPk(id);

    if (!banner) {
      return res.status(404).json({ message: 'Banner not found' });
    }

    let imagePath = banner.image;
    if (req.file) {
      const filename = req.file.filename;
      imagePath = `/uploads/banners/${filename}`;
    }

    banner.name = name || banner.name;
    banner.status = status !== undefined ? status : banner.status;
    banner.image = imagePath;

    await banner.save();

    res.json(banner);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a banner
// @route   DELETE /api/banners/:id
// @access  Private/Admin
const deleteBanner = async (req, res) => {
  try {
    const { id } = req.params;

    const banner = await Banner.findByPk(id);

    if (!banner) {
      return res.status(404).json({ message: 'Banner not found' });
    }

    await banner.destroy();

    res.json({ message: 'Banner removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

module.exports = {
  getBanners,
  getAllBanners,
  createBanner,
  updateBanner,
  deleteBanner
};
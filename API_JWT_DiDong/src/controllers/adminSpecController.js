const { Cauhinh_bonho, Camera_manhinh, Pin_sac, Product } = require('../models');
const { Op } = require('sequelize'); // Để dùng toán tử tìm kiếm

// --- Helper Functions ---

// Hàm tìm model dựa trên loại spec
const getSpecModel = (specType) => {
  switch (specType.toLowerCase()) {
    case 'cauhinh': return Cauhinh_bonho;
    case 'camera': return Camera_manhinh;
    case 'pinsac': return Pin_sac;
    default: throw new Error('Invalid spec type');
  }
};

// Hàm kiểm tra sản phẩm có tồn tại và thuộc loại điện thoại không
const checkPhoneProductExists = async (productId) => {
    const product = await Product.findOne({
        where: {
            id: productId,
            category_id: 1 // Giả sử category_id = 1 là Điện thoại
        }
    });
    return product !== null;
};


// --- CRUD Functions ---

// @desc    Get all specs of a specific type (e.g., all CauHinhBonho)
// @route   GET /api/admin/spec/:specType
// @access  Private/Admin
const getAllSpecs = async (req, res) => {
  const { specType } = req.params;
  try {
    const Model = getSpecModel(specType);
    // Include Product để lấy tên sản phẩm được gán (tùy chọn)
    const specs = await Model.findAll({
        order: [['id', 'DESC']],
        include: [{ model: Product, attributes: ['id', 'name'] }] // Lấy tên SP
    });
    res.json(specs);
  } catch (error) {
    console.error(`[AdminSpecCtrl] Error getting all ${specType}:`, error);
    res.status(500).json({ message: `Server Error getting ${specType}` });
  }
};

// @desc    Get a single spec by its ID
// @route   GET /api/admin/spec/:specType/:id
// @access  Private/Admin
const getSpecById = async (req, res) => {
  const { specType, id } = req.params;
  try {
    const Model = getSpecModel(specType);
    const spec = await Model.findByPk(id, {
        include: [{ model: Product, attributes: ['id', 'name'] }]
    });
    if (!spec) {
      return res.status(404).json({ message: `${specType} with ID ${id} not found` });
    }
    res.json(spec);
  } catch (error) {
    console.error(`[AdminSpecCtrl] Error getting ${specType} by ID ${id}:`, error);
    res.status(500).json({ message: `Server Error getting ${specType}` });
  }
};

// @desc    Create a new spec and assign it to a product
// @route   POST /api/admin/spec/:specType
// @access  Private/Admin
const createSpec = async (req, res) => {
  const { specType } = req.params;
  const data = req.body; // Dữ liệu spec gửi lên, bao gồm cả id_product

  // --- Validation ---
  if (!data.id_product) {
      return res.status(400).json({ message: 'Missing required field: id_product' });
  }
  // Kiểm tra xem id_product có phải là số không
   const productId = parseInt(data.id_product, 10);
   if (isNaN(productId)) {
       return res.status(400).json({ message: 'Invalid id_product: Must be a number.' });
   }

  try {
    const Model = getSpecModel(specType);

    // 1. Kiểm tra sản phẩm tồn tại và là điện thoại
    const productExists = await checkPhoneProductExists(productId);
    if (!productExists) {
        return res.status(404).json({ message: `Product with ID ${productId} not found or is not a Phone (category 1).` });
    }

     // 2. Kiểm tra xem sản phẩm này đã có loại spec này chưa (tránh tạo trùng)
     const existingSpec = await Model.findOne({ where: { id_product: productId } });
     if (existingSpec) {
         return res.status(400).json({ message: `Product ID ${productId} already has a ${specType} specification. Use PUT to update.` });
     }

    // 3. Tạo spec mới
    // Đảm bảo id_product là số
    data.id_product = productId;
    const newSpec = await Model.create(data);
    res.status(201).json(newSpec); // 201 Created

  } catch (error) {
    console.error(`[AdminSpecCtrl] Error creating ${specType}:`, error);
     if (error.name === 'SequelizeValidationError') {
        const messages = error.errors.map(err => err.message);
        return res.status(400).json({ message: 'Validation Error', errors: messages });
    }
    res.status(500).json({ message: `Server Error creating ${specType}` });
  }
};

// @desc    Update an existing spec by its ID
// @route   PUT /api/admin/spec/:specType/:id
// @access  Private/Admin
const updateSpec = async (req, res) => {
  const { specType, id } = req.params;
  const data = req.body; // Dữ liệu cập nhật, có thể bao gồm cả id_product mới

  // --- Validation ---
  // Nếu id_product được gửi lên để cập nhật, kiểm tra nó
  let productIdToUpdate = null;
  if (data.id_product !== undefined) {
      if (data.id_product === null) { // Cho phép bỏ gán sản phẩm
          productIdToUpdate = null;
      } else {
          productIdToUpdate = parseInt(data.id_product, 10);
          if (isNaN(productIdToUpdate)) {
              return res.status(400).json({ message: 'Invalid id_product: Must be a number or null.' });
          }
      }
  }


  try {
    const Model = getSpecModel(specType);

    // 1. Tìm spec cần cập nhật
    const spec = await Model.findByPk(id);
    if (!spec) {
      return res.status(404).json({ message: `${specType} with ID ${id} not found` });
    }

    // 2. Nếu id_product mới được cung cấp và khác null, kiểm tra sản phẩm mới
    if (productIdToUpdate !== null) {
        const productExists = await checkPhoneProductExists(productIdToUpdate);
        if (!productExists) {
            return res.status(404).json({ message: `Product with ID ${productIdToUpdate} not found or is not a Phone (category 1).` });
        }
         // Kiểm tra xem sản phẩm mới này đã được gán spec loại này chưa (trừ spec hiện tại)
         const existingSpecForNewProduct = await Model.findOne({
             where: {
                 id_product: productIdToUpdate,
                 id: { [Op.ne]: id } // Không phải là spec hiện tại
             }
         });
         if (existingSpecForNewProduct) {
             return res.status(400).json({ message: `Product ID ${productIdToUpdate} is already assigned to another ${specType} (ID: ${existingSpecForNewProduct.id}).` });
         }
         data.id_product = productIdToUpdate; // Cập nhật id_product trong data nếu hợp lệ
    } else if (data.id_product === null) {
        data.id_product = null; // Cho phép bỏ gán
    }


    // 3. Cập nhật spec
    const updatedSpec = await spec.update(data);
    res.json(updatedSpec);

  } catch (error) {
    console.error(`[AdminSpecCtrl] Error updating ${specType} ID ${id}:`, error);
     if (error.name === 'SequelizeValidationError') {
        const messages = error.errors.map(err => err.message);
        return res.status(400).json({ message: 'Validation Error', errors: messages });
    }
    res.status(500).json({ message: `Server Error updating ${specType}` });
  }
};

// @desc    Delete a spec by its ID
// @route   DELETE /api/admin/spec/:specType/:id
// @access  Private/Admin
const deleteSpec = async (req, res) => {
  const { specType, id } = req.params;
  try {
    const Model = getSpecModel(specType);

    // 1. Tìm spec
    const spec = await Model.findByPk(id);
    if (!spec) {
      return res.status(404).json({ message: `${specType} with ID ${id} not found` });
    }

    // 2. Xóa spec
    await spec.destroy();
    res.json({ message: `${specType} deleted successfully` });

  } catch (error) {
    console.error(`[AdminSpecCtrl] Error deleting ${specType} ID ${id}:`, error);
    // Có thể thêm kiểm tra lỗi khóa ngoại nếu DB không tự xử lý
    res.status(500).json({ message: `Server Error deleting ${specType}` });
  }
};

module.exports = {
  getAllSpecs,
  getSpecById,
  createSpec,
  updateSpec,
  deleteSpec,
};

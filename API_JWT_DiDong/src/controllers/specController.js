const { Product, Cauhinh_bonho, Camera_manhinh, Pin_sac } = require('../models');
const sequelize = require('../config/db'); // Import sequelize instance for transactions

// Helper function to handle upsert logic for specs
const upsertSpec = async (Model, productId, data, transaction) => {
    // Find existing spec record for the product
    let spec = await Model.findOne({ where: { id_product: productId }, transaction });

    if (spec) {
        // If exists, update it
        console.log(`[SpecController] Updating ${Model.name} for product ID: ${productId}`);
        await spec.update(data, { transaction });
    } else {
        // If not exists, create a new one
        console.log(`[SpecController] Creating new ${Model.name} for product ID: ${productId}`);
        // Ensure id_product is included in the data for creation
        const createData = { ...data, id_product: productId };
        spec = await Model.create(createData, { transaction });
    }
    return spec; // Return the updated or created spec object
};

// @desc    Upsert (Update or Insert) CauHinhBonho for a product
// @route   PUT /api/products/:productId/cauhinh
// @access  Private/Admin
const upsertCauHinhBonho = async (req, res) => { // tạo mới hoặc cập nhật thông số kỹ thuật
    const { productId } = req.params;
    const data = req.body;
    const t = await sequelize.transaction(); // Start a transaction

    try {
        // tìm kiếm sản phẩm theo ID và thuộc danh mục điện thoại category_id = 1 
        const product = await Product.findByPk(productId, { transaction: t });
        if (!product) {
            await t.rollback();
            return res.status(404).json({ message: 'Product not found' });
        }
        // 2. Upsert the spec using the helper function
        const cauhinh = await upsertSpec(Cauhinh_bonho, parseInt(productId, 10), data, t);

        // 3. Commit transaction
        await t.commit();

        // 4. Return the saved spec data
        res.status(200).json(cauhinh); // Return 200 OK for upsert

    } catch (error) {
        await t.rollback(); // Rollback transaction on error
        console.error(`[SpecController] Error upserting CauHinhBonho for product ${productId}:`, error);
        // Check for validation errors specifically
        if (error.name === 'SequelizeValidationError') {
            const messages = error.errors.map(err => err.message);
            return res.status(400).json({ message: 'Validation Error', errors: messages });
        }
        res.status(500).json({ message: 'Server Error upserting CauHinhBonho' });
    }
};

// @desc    Upsert CameraManhinh for a product
// @route   PUT /api/products/:productId/camera
// @access  Private/Admin
const upsertCameraManhinh = async (req, res) => {
    const { productId } = req.params;
    const data = req.body;
    // Convert denflash_camsau from 1/0/null (JSON) to true/false/null (DB) if needed
    if (data.denflash_camsau !== undefined) {
        data.denflash_camsau = data.denflash_camsau == 1 || data.denflash_camsau === true;
    }
    const t = await sequelize.transaction();

    try {
        const product = await Product.findByPk(productId, { transaction: t });
        if (!product) {
            await t.rollback();
            return res.status(404).json({ message: 'Product not found' });
        }

        const camera = await upsertSpec(Camera_manhinh, parseInt(productId, 10), data, t);
        await t.commit();
        res.status(200).json(camera);

    } catch (error) {
        await t.rollback();
        console.error(`[SpecController] Error upserting CameraManhinh for product ${productId}:`, error);
        if (error.name === 'SequelizeValidationError') {
            const messages = error.errors.map(err => err.message);
            return res.status(400).json({ message: 'Validation Error', errors: messages });
        }
        res.status(500).json({ message: 'Server Error upserting CameraManhinh' });
    }
};

// @desc    Upsert PinSac for a product
// @route   PUT /api/products/:productId/pinsac
// @access  Private/Admin
const upsertPinSac = async (req, res) => {
    const { productId } = req.params;
    const data = req.body;
    const t = await sequelize.transaction();

    try {
        const product = await Product.findByPk(productId, { transaction: t });
        if (!product) {
            await t.rollback();
            return res.status(404).json({ message: 'Product not found' });
        }

        const pinsac = await upsertSpec(Pin_sac, parseInt(productId, 10), data, t);
        await t.commit();
        res.status(200).json(pinsac);

    } catch (error) {
        await t.rollback();
        console.error(`[SpecController] Error upserting PinSac for product ${productId}:`, error);
        if (error.name === 'SequelizeValidationError') {
            const messages = error.errors.map(err => err.message);
            return res.status(400).json({ message: 'Validation Error', errors: messages });
        }
        res.status(500).json({ message: 'Server Error upserting PinSac' });
    }
};


module.exports = {
    upsertCauHinhBonho,
    upsertCameraManhinh,
    upsertPinSac,
};

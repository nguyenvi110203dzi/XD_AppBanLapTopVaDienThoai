const { Product, InventoryTransaction, User, Order } = require('../models'); // <<--- THÊM Order VÀO ĐÂY
const sequelize = require('../config/db');
const { Op } = require('sequelize');

// @desc    Nhập kho sản phẩm
// @route   POST /api/warehouse/import
// @access  Private/Admin
exports.importStock = async (req, res) => {
  const { product_id, quantity, notes } = req.body;
  const user_id = req.user.id; // Lấy từ middleware protect

  if (!product_id || quantity === undefined || isNaN(parseInt(quantity)) || parseInt(quantity) <= 0) {
    return res.status(400).json({ message: 'Dữ liệu sản phẩm hoặc số lượng không hợp lệ.' });
  }

  const t = await sequelize.transaction();
  try {
    const product = await Product.findByPk(product_id, { transaction: t });
    if (!product) {
      await t.rollback();
      return res.status(404).json({ message: 'Sản phẩm không tồn tại.' });
    }

    product.quantity = (product.quantity || 0) + parseInt(quantity);
    await product.save({ transaction: t });

    await InventoryTransaction.create({
      product_id: product.id,
      transaction_type: 'import',
      quantity_change: parseInt(quantity),
      user_id: user_id,
      notes: notes,
      transaction_date: new Date(),
    }, { transaction: t });

    await t.commit();
    res.status(200).json({ message: 'Nhập kho thành công.', product });
  } catch (error) {
    await t.rollback();
    console.error('Lỗi khi nhập kho:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi nhập kho.' });
  }
};

// @desc    Xuất kho sản phẩm (thủ công, không phải qua đơn hàng)
// @route   POST /api/warehouse/export
// @access  Private/Admin
exports.exportStock = async (req, res) => {
  const { product_id, quantity, reason, notes } = req.body;
  const user_id = req.user.id;

  if (!product_id || quantity === undefined || isNaN(parseInt(quantity)) || parseInt(quantity) <= 0 || !reason) {
    return res.status(400).json({ message: 'Dữ liệu sản phẩm, số lượng hoặc lý do không hợp lệ.' });
  }

  const t = await sequelize.transaction();
  try {
    const product = await Product.findByPk(product_id, { transaction: t });
    if (!product) {
      await t.rollback();
      return res.status(404).json({ message: 'Sản phẩm không tồn tại.' });
    }

    if ((product.quantity || 0) < parseInt(quantity)) {
      await t.rollback();
      return res.status(400).json({ message: 'Số lượng tồn kho không đủ.' });
    }

    product.quantity -= parseInt(quantity);
    await product.save({ transaction: t });

    await InventoryTransaction.create({
      product_id: product.id,
      transaction_type: 'export',
      quantity_change: -parseInt(quantity), // Số lượng âm
      user_id: user_id,
      reason: reason,
      notes: notes,
      transaction_date: new Date(),
    }, { transaction: t });

    await t.commit();
    res.status(200).json({ message: 'Xuất kho thành công.', product });
  } catch (error) {
    await t.rollback();
    console.error('Lỗi khi xuất kho:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi xuất kho.' });
  }
};

// @desc    Admin xem tổng số lượng của tất cả sản phẩm
// @route   GET /api/warehouse/products/total-quantity
// @access  Private/Admin
exports.getOverallProductQuantity = async (req, res) => {
  try {
    const totalQuantity = await Product.sum('quantity');
    res.status(200).json({ total_quantity: totalQuantity || 0 });
  } catch (error) {
    console.error('Lỗi khi lấy tổng số lượng sản phẩm:', error);
    res.status(500).json({ message: 'Lỗi máy chủ.' });
  }
};

// @desc    Admin xem lịch sử nhập/xuất của một sản phẩm
// @route   GET /api/warehouse/products/:productId/history
// @access  Private/Admin
exports.getProductStockHistory = async (req, res) => {
  try {
    const { productId } = req.params;
    const product = await Product.findByPk(productId);
    if (!product) {
        return res.status(404).json({ message: 'Sản phẩm không tồn tại.' });
    }

    const history = await InventoryTransaction.findAll({
      where: { product_id: productId },
      include: [
        { model: User, attributes: ['id', 'name', 'email'] },
        { model: Order, attributes: ['id', 'status'] }
      ],
      order: [['transaction_date', 'DESC']],
    });
    res.status(200).json({ product_name: product.name, history });
  } catch (error) {
    console.error('Lỗi khi lấy lịch sử kho của sản phẩm:', error);
    res.status(500).json({ message: 'Lỗi máy chủ.' });
  }
};
const { Order, OrderDetail, Product, User, BaoHanh } = require('../models');
const sequelize = require('../config/db');

// @desc    Create new order
// @route   POST /api/orders
// @access  Private
const createOrder = async (req, res) => {
  const t = await sequelize.transaction();
  let transactionCommitted = false;

  try {
    const { items, note } = req.body;
    const user_id = req.user.id;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'No order items' });
    }

    // Calculate total
    let total = 0;

    // Verify all products exist and have sufficient quantity
    for (const item of items) {
      const product = await Product.findByPk(item.product_id);

      if (!product) {
        await t.rollback();
        return res.status(404).json({
          message: `Product not found: ${item.product_id}`
        });
      }

      if (product.quantity < item.quantity) {
        await t.rollback();
        return res.status(400).json({
          message: `Not enough stock for product: ${product.name}`
        });
      }

      total += product.price * item.quantity;
    }

    // Create order
    const order = await Order.create({
      user_id,
      status: 0, // Default status: "chưa xác nhận"
      note,
      total
    }, { transaction: t });

    // Create order details and update product quantities
    for (const item of items) {
      const product = await Product.findByPk(item.product_id);

      await OrderDetail.create({
        order_id: order.id,
        product_id: item.product_id,
        price: product.price,
        quantity: item.quantity
      }, { transaction: t });

      // Update product quantity and buyturn
      product.quantity -= item.quantity;
      product.buyturn = (product.buyturn || 0) + item.quantity;
      await product.save({ transaction: t });
      //Tạo giao dịch hàng tồn kho để điều chỉnh bán
       await InventoryTransaction.create({
        product_id: item.product_id,
        transaction_type: 'sale_adjustment',
        quantity_change: -item.quantity, // Số lượng âm
        order_id: order.id,
        notes: `Xuất kho cho đơn hàng ${order.id}`,
        transaction_date: new Date()
      }, { transaction: t });
    }

    await t.commit();
    transactionCommitted = true;

    // Return the complete order with details
    const completeOrder = await Order.findByPk(order.id, {
      include: [
        {
          model: OrderDetail,
          include: [{ model: Product, as: 'product' }]
        }
      ]
    });

    res.status(201).json(completeOrder);
  } catch (error) {
    await t.rollback();
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get order by ID
// @route   GET /api/orders/:id
// @access  Private
const getOrderById = async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [
        {
          model: OrderDetail,
          include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image'] }]
        },
        {
          model: User,
          attributes: ['id', 'email', 'name', 'role', 'avatar', 'phone']
        }
      ]
    });

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Check if the user is authorized to see this order (admin or order owner)
    if (req.user.role !== 1 && order.user_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    res.json(order);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update order status
// @route   PUT /api/orders/:id/status
// @access  Private/Admin
const updateOrderStatus = async (req, res) => {
  const { id: orderId } = req.params;
  const { status: newStatusString } = req.body; // Nhận trạng thái từ body request

  const newStatus = parseInt(newStatusString);

  const t = await sequelize.transaction();
  try {
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: User,
        },
        {
          model: OrderDetail,
          as: 'order_details',
          include: [{
            model: Product,
            as: 'product',
          }]
        }
      ],
      transaction: t
    });

    if (!order) {
      await t.rollback();
      return res.status(404).json({ message: 'Không tìm thấy đơn hàng.' });
    }
    const oldStatus = order.status;
    order.status = newStatus;
    await order.save({ transaction: t });

    // Logic tạo phiếu bảo hành khi trạng thái chuyển thành "đã giao" (status: 3)
    // Và khôi phục số lượng sản phẩm khi đơn hàng bị "hủy" (status: 4)
    if (newStatus == 3 && oldStatus != 3) { // 3: Đã giao
      console.log(`Đơn hàng ${order.id} chuyển sang trạng thái Đã Giao. Bắt đầu tạo phiếu bảo hành...`);
      console.log(`Đơn hàng ${order.order_details} chuyển sang trạng thái Đã Giao. Bắt đầu tạo phiếu bảo hành...`);
      if (order.order_details && order.order_details.length > 0) {
        for (const detail of order.order_details) {
          console.log(`   => Đang xử lý chi tiết đơn hàng ID: ${detail.id} (Sản phẩm ID: ${detail.product_id})`);
          if (detail.product && detail.product.time_baohanh) {
            try {
              const existingBaoHanh = await BaoHanh.findOne({ where: { id_chi_tiet_don_hang: detail.id }, transaction: t });
              if (detail.product.time_baohanh == `6 tháng`) {
                detail.product.time_baohanh = 0.5;
              } else if (detail.product.time_baohanh == `12 tháng`) {
                detail.product.time_baohanh = 1;
              } else if (detail.product.time_baohanh == `24 tháng`) {
                detail.product.time_baohanh = 2;
              } else {
                detail.product.time_baohanh = 0;
              }
              if (!existingBaoHanh) {
                // lấy sdt người dùng từ id user trong order
                await BaoHanh.create({
                  id_chi_tiet_don_hang: detail.id,
                  so_dien_thoai_khach_hang: order.user?.phone ?? 'N/A',
                  ten_khach_hang: order.user?.name ?? 'N/A',
                  ten_san_pham: detail.product.name,
                  ngay_giao_hang: new Date().toISOString().slice(0, 10), // Ngày giao hàng là ngày hiện tại
                  ngay_bat_dau_bao_hanh: new Date().toISOString().slice(0, 10), // Ngày bắt đầu bảo hành là ngày hiện tại
                  thoi_gian_bao_hanh_nam: detail.product.time_baohanh,
                  trang_thai: 'Còn hạn', // Trạng thái ban đầu
                  hinh_thuc: 'Theo NSX', // Hình thức mặc định
                  ghi_chu: 'Tạo tự động khi đơn hàng được giao thành công.'
                }, { transaction: t });
                console.log(`   => Phiếu bảo hành tự động tạo cho chi tiết đơn hàng ID: ${detail.id} (Sản phẩm: ${detail.product.name})`);
              } else {
                console.log(`   => Phiếu bảo hành đã tồn tại cho chi tiết đơn hàng ID: ${detail.id}, không tạo mới.`);
              }
            } catch (errCreateBH) {
              console.error(`   Lỗi khi tự động tạo phiếu bảo hành cho chi tiết đơn hàng ID ${detail.id}:`, errCreateBH);
            }
          } else {
            console.log(`   Sản phẩm ID ${detail.product_id} (Tên: ${detail.product ? detail.product.name : 'N/A'}) không có thông tin bảo hành hoặc thời gian bảo hành là 0.`);
          }
        }
      } else {
        console.log(`Đơn hàng ${order.id} không có chi tiết sản phẩm để tạo bảo hành.`);
      }
    } else if (newStatus == 4 && oldStatus != 4) { // 4: Đã hủy
      // Logic khôi phục số lượng sản phẩm nếu đơn hàng bị hủy (và trước đó chưa bị hủy)
      console.log(`Đơn hàng ${order.id} đã bị hủy. Khôi phục số lượng sản phẩm...`);
      if (order.orderDetails && order.orderDetails.length > 0) {
        for (const detail of order.orderDetails) {
          // Chỉ khôi phục nếu đơn hàng trước đó không phải là đã hủy (tránh khôi phục nhiều lần)
          // và đơn hàng đó đã từng ở trạng thái làm giảm số lượng (vd: đã xác nhận, đang giao)
          if (oldStatus != 4 && (oldStatus == 1 || oldStatus == 2 || oldStatus == 3)) {
            const productToUpdate = await Product.findByPk(detail.product_id, { transaction: t });
            if (productToUpdate) {
              productToUpdate.quantity += detail.quantity;
              productToUpdate.buyturn = Math.max(0, (productToUpdate.buyturn || 0) - detail.quantity); // Tránh buyturn âm
              await productToUpdate.save({ transaction: t });
              console.log(`   => Khôi phục ${detail.quantity} cho sản phẩm ID ${detail.product_id}. Số lượng mới: ${productToUpdate.quantity}`);
              await InventoryTransaction.create({
                product_id: detail.product_id,
                transaction_type: 'return_adjustment', // Hoặc 'cancellation_adjustment'
                quantity_change: detail.quantity, // Số lượng dương
                order_id: order.id,
                notes: `Khôi phục tồn kho do hủy/trả đơn hàng ${order.id}.`,
                transaction_date: new Date()
              }, { transaction: t });
            }
          }
        }
      }
    }

    await t.commit();
    // Lấy lại thông tin đơn hàng đầy đủ sau khi cập nhật để trả về (bao gồm cả phiếu bảo hành nếu có)
    const updatedOrderWithDetails = await Order.findByPk(orderId, {
      include: [
        { model: User, attributes: ['id', 'name', 'email', 'phone'] },
        {
          model: OrderDetail,
          as: 'order_details',
          include: [
            { model: Product, as: 'product', attributes: ['id', 'name', 'image'] },
            { model: BaoHanh, as: 'baoHanhs' }
          ]
        }
      ]
    });
    res.json({ message: 'Cập nhật trạng thái đơn hàng thành công.', order: updatedOrderWithDetails });

  } catch (error) {
    if (t.finished !== 'commit' && t.finished !== 'rollback') { // Check if transaction is still active
      await t.rollback();
    }
    console.error(`Lỗi khi cập nhật trạng thái đơn hàng ${orderId}:`, error);
    res.status(500).json({ message: 'Lỗi máy chủ khi cập nhật trạng thái đơn hàng.' });
  }
};

// @desc    Get all orders
// @route   GET /api/orders
// @access  Private/Admin
const getAllOrders = async (req, res) => {
  try {
    const orders = await Order.findAll({
      include: [
        {
          model: User,
          attributes: ['id', 'name', 'email', 'phone']
        }
      ],
      order: [['createdAt', 'DESC']]
    });

    res.json(orders);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get user orders
// @route   GET /api/orders/myorders
// @access  Private
const getUserOrders = async (req, res) => {
  try {
    const user_id = req.user.id;
    const status = req.query.status;
    let whereClause = { user_id: user_id };
    if (status !== undefined && !isNaN(parseInt(status)) && parseInt(status) >= 0 && parseInt(status) <= 4) {
      whereClause.status = parseInt(status);
      console.log(`[OrderController] Filtering user ${user_id} orders by status: ${status}`); // Debug
    } else {
      console.log(`[OrderController] Fetching all orders for user ${user_id}`); // Debug
    }

    const orders = await Order.findAll({
      where: whereClause,
      include: [
        {
          model: OrderDetail,
          include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image'] }]
        }
      ],
      order: [['createdAt', 'DESC']]
    });

    res.json(orders);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete an order
// @route   DELETE /api/orders/:id
// @access  Private/Admin
const deleteOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const order = await Order.findByPk(id);

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Delete order details first
    await OrderDetail.destroy({
      where: { order_id: id }
    });

    // Then delete the order
    await order.destroy();

    res.json({ message: 'Order removed' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get order details
// @route   GET /api/orders/details/:orderId
// @access  Public
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    const orderDetails = await OrderDetail.findAll({
      where: { order_id: orderId },
      include: [
        {
          model: Product,
          as: 'product',
          attributes: ['id', 'name', 'image']
        }
      ]
    });

    res.json(orderDetails);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

module.exports = {
  createOrder,
  getOrderById,
  updateOrderStatus,
  getAllOrders,
  getUserOrders,
  deleteOrder,
  getOrderDetails
};
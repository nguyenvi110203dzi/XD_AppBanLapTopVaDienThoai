const { CreditOrder, CreditOrderDetail, Product, User } = require('../models');
const sequelize = require('../config/db'); // Cho transactions

// @desc    Khách hàng (role=2) tạo đơn hàng công nợ mới
// @route   POST /api/credit-orders
// @access  Private (Role 2)
const createCreditOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { items, note, due_date } = req.body;
        const user_id = req.user.id; // req.user được đảm bảo có role = 2 bởi middleware

        if (!items || !Array.isArray(items) || items.length === 0) {
            // await t.rollback(); // Không cần rollback nếu chưa có thao tác DB nào
            return res.status(400).json({ message: 'Giỏ hàng công nợ không được rỗng.' });
        }

        // Validate items
        for (const item of items) {
            if (!item.product_id || isNaN(parseInt(item.product_id)) || !item.quantity || isNaN(parseInt(item.quantity)) || parseInt(item.quantity) <= 0) {
                // await t.rollback();
                return res.status(400).json({ message: 'Thông tin sản phẩm trong giỏ hàng không hợp lệ.' });
            }
        }

        let total = 0;

        for (const item of items) {
            const product = await Product.findByPk(item.product_id, { transaction: t });
            if (!product) {
                await t.rollback(); // Rollback nếu sản phẩm không tồn tại
                return res.status(404).json({ message: `Sản phẩm với ID ${item.product_id} không tìm thấy.` });
            }
            // BỎ QUA KIỂM TRA TỒN KHO CHO KHÁCH SỈ (role=2) KHI MUA CÔNG NỢ
            // if (product.quantity < item.quantity) {
            //   await t.rollback();
            //   return res.status(400).json({ message: `Không đủ số lượng cho sản phẩm: ${product.name}. Tồn kho: ${product.quantity}` });
            // }
            total += product.price * item.quantity;
        }

        const creditOrder = await CreditOrder.create({
            user_id,
            status: 0, // 0: Chờ thanh toán/Chờ xác nhận
            note,
            total,
            order_date: new Date(),
            due_date: due_date ? new Date(due_date) : null,
        }, { transaction: t });

        for (const item of items) {
            const product = await Product.findByPk(item.product_id, { transaction: t }); // Lấy lại để đảm bảo thông tin mới nhất
            await CreditOrderDetail.create({
                credit_order_id: creditOrder.id,
                product_id: item.product_id,
                price: product.price,
                quantity: item.quantity,
            }, { transaction: t });

            // CẬP NHẬT SỐ LƯỢNG SẢN PHẨM: Cho phép số lượng âm nếu là khách sỉ mua công nợ
            product.quantity -= item.quantity; // Số lượng có thể trở thành âm
            product.buyturn = (product.buyturn || 0) + item.quantity;
            await product.save({ transaction: t });
        }

        await t.commit();

        const completeCreditOrder = await CreditOrder.findByPk(creditOrder.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email'] },
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image'] }]
                }
            ]
        });

        res.status(201).json(completeCreditOrder);

    } catch (error) {
        if (t && !t.finished && !t.isRolledBack) {
            try { await t.rollback(); } catch (rbError) { console.error('Rollback error:', rbError); }
        }
        console.error('Lỗi khi tạo đơn hàng công nợ:', error);
        if (error.name === 'SequelizeValidationError') {
            return res.status(400).json({ message: 'Dữ liệu không hợp lệ.', errors: error.errors.map(e => e.message) });
        }
        res.status(500).json({ message: 'Lỗi máy chủ khi tạo đơn hàng công nợ.' });
    }
};

// @desc    Khách hàng (role=2) xem lịch sử đơn hàng công nợ của mình
// @route   GET /api/credit-orders/my-history
// @access  Private (Role 2)
const getMyCreditOrders = async (req, res) => {
    try {
        const user_id = req.user.id;
        const { status } = req.query; // Cho phép lọc theo trạng thái

        let whereClause = { user_id: user_id };
        if (status !== undefined && !isNaN(parseInt(status))) {
            whereClause.status = parseInt(status);
        }

        const creditOrders = await CreditOrder.findAll({
            where: whereClause,
            include: [
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image'] }]
                }
            ],
            order: [['order_date', 'DESC']]
        });
        res.json(creditOrders);
    } catch (error) {
        console.error('Lỗi khi lấy lịch sử đơn hàng công nợ:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};

// @desc    Khách hàng (role=2) xem chi tiết một đơn hàng công nợ của mình
// @route   GET /api/credit-orders/my-history/:id
// @access  Private (Role 2)
const getCreditOrderByIdForCustomer = async (req, res) => {
    try {
        const creditOrder = await CreditOrder.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id // Đảm bảo chỉ lấy đơn của user đang đăng nhập
            },
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone'] },
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image', 'price'] }]
                }
            ]
        });

        if (!creditOrder) {
            return res.status(404).json({ message: 'Không tìm thấy đơn hàng công nợ.' });
        }
        res.json(creditOrder);
    } catch (error) {
        console.error('Lỗi khi lấy chi tiết đơn hàng công nợ cho khách hàng:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};


// === Các hàm cho Admin ===

// @desc    Admin xem tất cả đơn hàng công nợ
// @route   GET /api/credit-orders/admin
// @access  Private (Admin)
const getAllCreditOrders = async (req, res) => {
    try {
        const { status, userId, sortBy, sortOrder } = req.query;
        let whereClause = {};
        let orderClause = [['order_date', sortOrder || 'DESC']]; // Mặc định sắp xếp mới nhất lên đầu

        if (status !== undefined && !isNaN(parseInt(status))) {
            whereClause.status = parseInt(status);
        }
        if (userId !== undefined && !isNaN(parseInt(userId))) {
            whereClause.user_id = parseInt(userId);
        }
        if (sortBy) {
            orderClause = [[sortBy, sortOrder || 'ASC']];
        }


        const creditOrders = await CreditOrder.findAll({
            where: whereClause,
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone'] },
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name'] }]
                }
            ],
            order: orderClause
        });
        res.json(creditOrders);
    } catch (error) {
        console.error('Lỗi khi admin lấy danh sách đơn hàng công nợ:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};

// @desc    Admin xem chi tiết một đơn hàng công nợ
// @route   GET /api/credit-orders/admin/:id
// @access  Private (Admin)
const getCreditOrderByIdForAdmin = async (req, res) => {
    try {
        const creditOrder = await CreditOrder.findByPk(req.params.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone', 'avatar'] },
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image', 'price'] }]
                }
            ]
        });
        if (!creditOrder) {
            return res.status(404).json({ message: 'Không tìm thấy đơn hàng công nợ.' });
        }
        res.json(creditOrder);
    } catch (error) {
        console.error('Lỗi khi admin lấy chi tiết đơn hàng công nợ:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};

// @desc    Admin cập nhật đơn hàng công nợ (ngày hẹn trả, trạng thái, ghi chú)
// @route   PUT /api/credit-orders/admin/:id
// @access  Private (Admin)
const updateCreditOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const { status, due_date, note } = req.body;

        const creditOrder = await CreditOrder.findByPk(id, { transaction: t });

        if (!creditOrder) {
            await t.rollback();
            return res.status(404).json({ message: 'Không tìm thấy đơn hàng công nợ.' });
        }

        const oldStatus = creditOrder.status;

        // Cập nhật các trường nếu có
        if (status !== undefined) creditOrder.status = parseInt(status);
        if (due_date !== undefined) creditOrder.due_date = due_date; // due_date có thể là null nếu muốn xóa
        if (note !== undefined) creditOrder.note = note;

        // Logic đặc biệt khi trạng thái thay đổi
        // Ví dụ: Nếu chuyển sang "Đã thanh toán" (status: 1) thì cập nhật payment_date
        if (status !== undefined && parseInt(status) === 1 && oldStatus !== 1) {
            creditOrder.payment_date = new Date();
        }

        // Nếu chuyển sang "Đã hủy" (status: 3) từ một trạng thái chưa hủy trước đó, và đơn hàng chưa được thanh toán
        // thì khôi phục số lượng sản phẩm
        if (status !== undefined && parseInt(status) === 3 && oldStatus !== 3 && oldStatus !== 1 /* chưa thanh toán */) {
            const details = await CreditOrderDetail.findAll({ where: { credit_order_id: id }, transaction: t });
            for (const detail of details) {
                const product = await Product.findByPk(detail.product_id, { transaction: t });
                if (product) {
                    product.quantity += detail.quantity;
                    product.buyturn = Math.max(0, (product.buyturn || 0) - detail.quantity); // Tránh buyturn âm
                    await product.save({ transaction: t });
                }
            }
            console.log(`Đơn hàng công nợ ${id} bị hủy, đã khôi phục số lượng sản phẩm.`);
        }


        await creditOrder.save({ transaction: t });
        await t.commit();

        const updatedOrder = await CreditOrder.findByPk(id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email'] },
                {
                    model: CreditOrderDetail,
                    as: 'creditOrderDetails',
                    include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image'] }]
                }
            ]
        });

        res.json(updatedOrder);
    } catch (error) {
        if (t && !t.finished) {
            await t.rollback();
        }
        console.error('Lỗi khi admin cập nhật đơn hàng công nợ:', error);
        res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};

module.exports = {
    createCreditOrder,
    getMyCreditOrders,
    getCreditOrderByIdForCustomer,
    getAllCreditOrders,
    getCreditOrderByIdForAdmin,
    updateCreditOrder
};
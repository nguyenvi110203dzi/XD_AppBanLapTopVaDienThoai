// src/controllers/baoHanhController.js
const { BaoHanh, OrderDetail, Order, Product, User } = require('../models');
const { Op } = require('sequelize');

// @desc    Tạo mới một yêu cầu bảo hành
// @route   POST /api/baohanh
// @access  Private/Admin
exports.createBaoHanh = async (req, res) => {
  try {
    const {
      id_chi_tiet_don_hang,
      ngay_giao_hang,
      ngay_bat_dau_bao_hanh,
      thoi_gian_bao_hanh_nam,
      hinh_thuc,
      trang_thai,
      ghi_chu
    } = req.body;

    // Kiểm tra xem id_chi_tiet_don_hang có phải là số hợp lệ không
    if (isNaN(parseInt(id_chi_tiet_don_hang))) {
      return res.status(400).json({ message: 'ID chi tiết đơn hàng không hợp lệ.' });
    }

    const orderDetail = await OrderDetail.findByPk(parseInt(id_chi_tiet_don_hang), {
      include: [
        { model: Product, attributes: ['name', 'id'] },
        {
          model: Order,
          attributes: ['id', 'user_id'],
          include: [{ model: User, attributes: ['name', 'phone', 'id'] }]
        }
      ]
    });

    if (!orderDetail) {
      return res.status(404).json({ message: `Chi tiết đơn hàng với ID ${id_chi_tiet_don_hang} không tồn tại.` });
    }

    if (!orderDetail.order || !orderDetail.order.user || !orderDetail.product) {
      return res.status(404).json({ message: 'Không tìm thấy thông tin đầy đủ của đơn hàng, khách hàng hoặc sản phẩm.' });
    }

    const baoHanhMoi = await BaoHanh.create({
      id_chi_tiet_don_hang: parseInt(id_chi_tiet_don_hang),
      so_dien_thoai_khach_hang: orderDetail.order.user.phone,
      ten_khach_hang: orderDetail.order.user.name,
      ten_san_pham: orderDetail.product.name,
      ngay_giao_hang,
      ngay_bat_dau_bao_hanh,
      thoi_gian_bao_hanh_nam,
      trang_thai: trang_thai || 'Chờ xử lý',
      hinh_thuc: hinh_thuc || 'Chưa xác định', // Giá trị mặc định nếu không cung cấp
      ghi_chu,
    });

    res.status(201).json(baoHanhMoi);
  } catch (error) {
    console.error('Lỗi khi tạo phiếu bảo hành:', error);
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ', errors: error.errors.map(e => e.message) });
    }
    res.status(500).json({ message: 'Lỗi máy chủ khi tạo thông tin bảo hành.' });
  }
};

// @desc    Lấy tất cả thông tin bảo hành
// @route   GET /api/baohanh
// @access  Private/Admin
exports.getAllBaoHanh = async (req, res) => {
  try {
    const danhSachBaoHanh = await BaoHanh.findAll({
      include: [
        {
          model: OrderDetail,
          as: 'order_details', // Sử dụng alias đã định nghĩa
          include: [
            { model: Product, as: 'product', attributes: ['id', 'name', 'image'] },
            {
              model: Order,
              attributes: ['id', 'user_id', 'createdAt'],
              include: [{ model: User, attributes: ['id', 'name', 'email'] }]
            }
          ]
        }
      ],
      order: [['ngay_tao', 'DESC']],
    });
    res.json(danhSachBaoHanh);
  } catch (error) {
    console.error('Lỗi khi lấy danh sách bảo hành:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi lấy danh sách bảo hành.' });
  }
};

// @desc    Tìm kiếm thông tin bảo hành theo SĐT hoặc Họ tên khách hàng
// @route   GET /api/baohanh/search
// @access  Private/Admin
exports.searchBaoHanh = async (req, res) => {
  try {
    const { phone, name } = req.query;
    let dieuKienTimKiem = {};

    if (phone) {
      dieuKienTimKiem.so_dien_thoai_khach_hang = { [Op.like]: `%${phone}%` };
    }
    if (name) {
      dieuKienTimKiem.ten_khach_hang = { [Op.like]: `%${name}%` };
    }

    if (Object.keys(dieuKienTimKiem).length === 0) {
      return res.status(400).json({ message: 'Vui lòng cung cấp SĐT hoặc Họ tên để tìm kiếm.' });
    }

    const ketQuaTimKiem = await BaoHanh.findAll({
      where: dieuKienTimKiem,
      include: [
        {
          model: OrderDetail,
          as: 'order_details', // Sử dụng alias đã định nghĩa
          include: [
            { model: Product, as: 'product', attributes: ['id', 'name', 'image'] },
            {
              model: Order,
              attributes: ['id', 'user_id', 'createdAt'],
              include: [{ model: User, attributes: ['id', 'name', 'email'] }]
            }
          ]
        }
      ],
      order: [['ngay_tao', 'DESC']],
    });

    if (!ketQuaTimKiem.length) {
      return res.status(404).json({ message: 'Không tìm thấy thông tin bảo hành phù hợp.' });
    }
    res.json(ketQuaTimKiem);
  } catch (error) {
    console.error('Lỗi khi tìm kiếm thông tin bảo hành:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi tìm kiếm thông tin bảo hành.' });
  }
};

// @desc    Cập nhật trạng thái/hình thức bảo hành
// @route   PUT /api/baohanh/:id
// @access  Private/Admin
exports.updateBaoHanh = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      trang_thai,
      hinh_thuc,
      ghi_chu,
      ngay_bat_dau_bao_hanh,
      thoi_gian_bao_hanh_nam,
      ngay_giao_hang,
      // Các trường có thể cập nhật khác nếu cần
      so_dien_thoai_khach_hang,
      ten_khach_hang,
      ten_san_pham
    } = req.body;

    const phieuBaoHanh = await BaoHanh.findByPk(id);

    if (!phieuBaoHanh) {
      return res.status(404).json({ message: 'Không tìm thấy thông tin bảo hành.' });
    }

    if (trang_thai !== undefined) phieuBaoHanh.trang_thai = trang_thai;
    if (hinh_thuc !== undefined) phieuBaoHanh.hinh_thuc = hinh_thuc;
    if (ghi_chu !== undefined) phieuBaoHanh.ghi_chu = ghi_chu;
    if (ngay_giao_hang !== undefined) phieuBaoHanh.ngay_giao_hang = ngay_giao_hang;
    if (ngay_bat_dau_bao_hanh !== undefined) phieuBaoHanh.ngay_bat_dau_bao_hanh = ngay_bat_dau_bao_hanh;
    if (thoi_gian_bao_hanh_nam !== undefined) phieuBaoHanh.thoi_gian_bao_hanh_nam = thoi_gian_bao_hanh_nam;
    if (so_dien_thoai_khach_hang !== undefined) phieuBaoHanh.so_dien_thoai_khach_hang = so_dien_thoai_khach_hang;
    if (ten_khach_hang !== undefined) phieuBaoHanh.ten_khach_hang = ten_khach_hang;
    if (ten_san_pham !== undefined) phieuBaoHanh.ten_san_pham = ten_san_pham;


    await phieuBaoHanh.save();
    res.json(phieuBaoHanh);
  } catch (error) {
    console.error('Lỗi khi cập nhật thông tin bảo hành:', error);
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ', errors: error.errors.map(e => e.message) });
    }
    res.status(500).json({ message: 'Lỗi máy chủ khi cập nhật thông tin bảo hành.' });
  }
};

// @desc    Lấy chi tiết một phiếu bảo hành
// @route   GET /api/baohanh/:id
// @access  Private/Admin
exports.getBaoHanhById = async (req, res) => {
  try {
    const phieuBaoHanh = await BaoHanh.findByPk(req.params.id, {
      include: [
        {
          model: OrderDetail,
          as: 'order_details',
          include: [
            { model: Product, as: 'product', attributes: ['id', 'name', 'image', 'description'] },
            {
              model: Order,
              attributes: ['id', 'createdAt', 'total', 'user_id'],
              include: [{ model: User, attributes: ['id', 'name', 'email', 'phone', 'avatar'] }]
            }
          ]
        }
      ]
    });

    if (!phieuBaoHanh) {
      return res.status(404).json({ message: 'Phiếu bảo hành không tồn tại.' });
    }
    res.json(phieuBaoHanh);
  } catch (error) {
    console.error(`Lỗi khi lấy chi tiết bảo hành ID ${req.params.id}:`, error);
    res.status(500).json({ message: 'Lỗi máy chủ khi lấy chi tiết bảo hành.' });
  }
};
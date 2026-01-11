// src/models/BaoHanh.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const BaoHanh = sequelize.define('baohanh', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  id_chi_tiet_don_hang: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'id_chi_tiet_don_hang' // Đảm bảo khớp tên cột CSDL
  },
  so_dien_thoai_khach_hang: {
    type: DataTypes.STRING(20),
    allowNull: false,
    field: 'so_dien_thoai_khach_hang'
  },
  ten_khach_hang: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'ten_khach_hang'
  },
  ten_san_pham: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'ten_san_pham'
  },
  ngay_giao_hang: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    field: 'ngay_giao_hang'
  },
  ngay_bat_dau_bao_hanh: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    field: 'ngay_bat_dau_bao_hanh'
  },
  thoi_gian_bao_hanh_nam: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'thoi_gian_bao_hanh_nam'
  },
  // ngay_ket_thuc_bao_hanh là GENERATED COLUMN trong CSDL
  trang_thai: {
    type: DataTypes.STRING(50),
    defaultValue: 'Chờ xử lý',
    field: 'trang_thai'
  },
  hinh_thuc: {
    type: DataTypes.STRING(50),
    allowNull: false, // Cho phép null nếu ban đầu chưa xác định hình thức
    field: 'hinh_thuc'
  },
  ghi_chu: {
    type: DataTypes.TEXT,
    field: 'ghi_chu'
  }
  // ngay_tao và ngay_cap_nhat sẽ được quản lý bởi timestamps của Sequelize
}, {
  tableName: 'baohanh', // Khớp chính xác tên bảng trong CSDL
  timestamps: true,
  createdAt: 'ngay_tao', // Ánh xạ createdAt của Sequelize với cột ngay_tao
  updatedAt: 'ngay_cap_nhat', // Ánh xạ updatedAt của Sequelize với cột ngay_cap_nhat
  // underscored: true, // Cân nhắc sử dụng nếu muốn Sequelize tự động xử lý tên cột snake_case
});

module.exports = BaoHanh;
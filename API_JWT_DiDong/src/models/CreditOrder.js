const { DataTypes } = require('sequelize');
const sequelize = require('../config/db'); // Đảm bảo đường dẫn này đúng

const CreditOrder = sequelize.define('credit_order', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { // Khai báo khóa ngoại
      model: 'users', // Tên bảng mà nó tham chiếu đến
      key: 'id'
    }
  },
  status: {
    type: DataTypes.INTEGER,
    defaultValue: 0, // 0: Chờ thanh toán, 1: Đã thanh toán, 2: Quá hạn, 3: Đã hủy
    allowNull: false,
    comment: '0: Chờ thanh toán, 1: Đã thanh toán, 2: Quá hạn, 3: Đã hủy'
  },
  note: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  total: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  order_date: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  due_date: { // Ngày hẹn trả
    type: DataTypes.DATE,
    allowNull: true // Admin có thể cập nhật sau
  },
  payment_date: { // Ngày khách hàng thanh toán thực tế
    type: DataTypes.DATE,
    allowNull: true
  }
  // createdAt và updatedAt sẽ được Sequelize tự động quản lý
}, {
  tableName: 'credit_orders', // Quan trọng: Đảm bảo tên bảng khớp với CSDL
  timestamps: true // Bật timestamps (createdAt, updatedAt)
});

module.exports = CreditOrder;
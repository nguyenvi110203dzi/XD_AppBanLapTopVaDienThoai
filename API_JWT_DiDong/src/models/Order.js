const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Order = sequelize.define('order', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  status: {
  type: DataTypes.INTEGER,
  defaultValue: 0,
  // 0: "chưa xác nhận", 1: "xác nhận", 2: "đang giao", 3: "đã giao", 4: "đã hủy"
},
  note: {
    type: DataTypes.TEXT
  },
  total: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  paymentMethod: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0: COD (Mặc định), 1: VNPAY
  }
}, 
{
  tableName: 'orders',
  timestamps: true,
});

module.exports = Order;
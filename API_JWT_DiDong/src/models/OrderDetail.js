const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const OrderDetail = sequelize.define('order_detail', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  price: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  order_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  product_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  }
}, {
  tableName: 'order_details',
  timestamps: true
});

module.exports = OrderDetail;
// src/models/InventoryTransaction.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const InventoryTransaction = sequelize.define('inventory_transaction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  product_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  transaction_type: {
    type: DataTypes.ENUM('import', 'export', 'sale_adjustment', 'return_adjustment', 'damage_adjustment', 'initial_stock'),
    allowNull: false,
  },
  quantity_change: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  transaction_date: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  user_id: { // Admin thực hiện hành động
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  order_id: { // Liên kết với đơn hàng nếu có
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  notes: {
    type: DataTypes.TEXT,
  },
  reason: {
    type: DataTypes.STRING,
  }
}, {
  tableName: 'inventory_transactions',
  timestamps: true,
});

module.exports = InventoryTransaction;
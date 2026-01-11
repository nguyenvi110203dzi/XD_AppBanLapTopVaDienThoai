const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Product = sequelize.define('product', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  price: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  oldprice: {
    type: DataTypes.INTEGER
  },
  image: {
    type: DataTypes.TEXT
  },
  description: {
    type: DataTypes.TEXT
  },
  specification: {
    type: DataTypes.TEXT
  },
  buyturn: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  quantity: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  brand_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  category_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  updatedAt: {
    type: DataTypes.DATE,
    allowNull: false
  },
  time_baohanh: {
    type: DataTypes.STRING,
    allowNull: true, // Hoặc false nếu mọi sản phẩm đều phải có
  },
}, {
  tableName: 'products',
  timestamps: true, // createdAt, updatedAt
});

module.exports = Product;
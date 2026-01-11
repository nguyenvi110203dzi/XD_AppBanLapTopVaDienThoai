const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Banner = sequelize.define('banner', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  image: {
    type: DataTypes.TEXT
  },
  name: {
    type: DataTypes.STRING
  },
  status: {
    type: DataTypes.INTEGER,
    defaultValue: 1 // 1: Active, 0: Inactive
  }
});

module.exports = Banner;